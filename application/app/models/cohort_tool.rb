class CohortTool < ActiveRecord::Base
  set_table_name "encounter"

  def self.records_that_were_updated(quarter)

    date        = Report.generate_cohort_date_range(quarter)
    start_date  = (date.first.to_s  + " 00:00:00")
    end_date    = (date.last.to_s   + " 23:59:59")

    voided_records = {}

    other_encounters = Encounter.find_by_sql("SELECT encounter.* FROM encounter
                        INNER JOIN obs ON encounter.encounter_id = obs.encounter_id
                        WHERE ((encounter.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}'))
                        GROUP BY encounter.encounter_id
                        ORDER BY encounter.encounter_type, encounter.patient_id")

    drug_encounters = Encounter.find_by_sql("SELECT encounter.* as duration FROM encounter
                        INNER JOIN orders ON encounter.encounter_id = orders.encounter_id
                        WHERE ((encounter.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}'))
                        ORDER BY encounter.encounter_type")

    voided_encounters = []
    other_encounters.delete_if { |encounter| voided_encounters << encounter if (encounter.voided == 1)}

    voided_encounters.map do |encounter|
      patient           = Patient.find(encounter.patient_id)

      new_encounter  = other_encounters.reduce([])do |result, e|
        result << e if( e.encounter_datetime.strftime("%d-%m-%Y") == encounter.encounter_datetime.strftime("%d-%m-%Y")&&
                        e.patient_id      == encounter.patient_id &&
                        e.encounter_type  == encounter. encounter_type)
        result
      end

      new_encounter = new_encounter.last

      next if new_encounter.nil?

      voided_observations = encounter.voided_observations

      changed_to    = self.changed_to(new_encounter)
      changed_from  = self.changed_from(voided_observations)

      patient_arv_number = patient.get_identifier("ARV NUMBER")

      if( voided_observations && !voided_observations.empty?)
          voided_records[encounter.id] = {
              "id"              => patient.patient_id,
              "arv_number"      => patient_arv_number,
              "name"            => patient.name,
              "national_id"     => patient.national_id,
              "encounter_name"  => encounter.name,
              "voided_date"     => encounter.date_voided,
              "reason"          => encounter.void_reason,
              "change_from"     => changed_from,
              "change_to"       => changed_to
            }
      end
    end

    voided_treatments = []
    drug_encounters.delete_if { |encounter| voided_treatments << encounter if (encounter.voided == 1)}

    voided_treatments.each do |encounter|

      patient           = Patient.find(encounter.patient_id)

      orders            = encounter.orders
      changed_from      = ''
      changed_to        = ''

     new_encounter  =  drug_encounters.reduce([])do |result, e|
        result << e if( e.encounter_datetime.strftime("%d-%m-%Y") == encounter.encounter_datetime.strftime("%d-%m-%Y")&&
                        e.patient_id      == encounter.patient_id &&
                        e.encounter_type  == encounter. encounter_type)
          result
        end

      new_encounter = new_encounter.last

      next if new_encounter.nil?

      changed_from  += "Treatment: #{new_encounter.voided_orders.to_s.gsub!(":", " =>")}</br>"
      changed_to    += "Treatment: #{encounter.to_s.gsub!(":", " =>") }</br>"

      patient_arv_number = patient.get_identifier("ARV NUMBER")

      if( orders && !orders.empty?)
        voided_records[encounter.id]= {
            "id"              => patient.patient_id,
            "arv_number"      => patient_arv_number,
            "name"            => patient.name,
            "national_id"     => patient.national_id,
            "encounter_name"  => encounter.name,
            "voided_date"     => encounter.date_voided,
            "reason"          => encounter.void_reason,
            "change_from"     => changed_from,
            "change_to"       => changed_to
        }
      end

    end

    self.show_tabuler_format(voided_records)
  end

  def self.show_tabuler_format(records)

    patients = {}

    records.each do |key,value|

      sorted_values = self.sort(value)

      patients["#{key},#{value['id']}"] = sorted_values
    end

    patients
  end

  def self.sort(values)
    name              = ''
    patient_id        = ''
    arv_number        = ''
    national_id       = ''
    encounter_name    = ''
    voided_date       = ''
    reason            = ''
    obs_names         = ''
    changed_from_obs  = {}
    changed_to_obs    = {}
    changed_data      = {}

    values.each do |value|
      value_name =  value.first
      value_data =  value.last

      case value_name
        when "id"
          patient_id = value_data
        when "arv_number"
          arv_number = value_data
        when "name"
          name = value_data
        when "national_id"
          national_id = value_data
        when "encounter_name"
          encounter_name = value_data
        when "voided_date"
          voided_date = value_data
        when "reason"
          reason = value_data
        when "change_from"
          value_data.split("</br>").each do |obs|
            obs_name  = obs.split(':')[0].strip
            obs_value = obs.split(':')[1].strip rescue ''

            changed_from_obs[obs_name] = obs_value
          end unless value_data.blank?
        when "change_to"

          value_data.split("</br>").each do |obs|
            obs_name  = obs.split(':')[0].strip
            obs_value = obs.split(':')[1].strip rescue ''

            changed_to_obs[obs_name] = obs_value
          end unless value_data.blank?
      end
    end

    changed_from_obs.each do |a,b|
      changed_to_obs.each do |x,y|

        if (a == x)
          next if b == y
          changed_data[a] = "#{b} to #{y}"

          changed_from_obs.delete(a)
          changed_to_obs.delete(x)
        end
      end
    end

    changed_to_obs.each do |a,b|
      changed_from_obs.each do |x,y|
        if (a == x)
          next if b == y
          changed_data[a] = "#{b} to #{y}"

          changed_to_obs.delete(a)
          changed_from_obs.delete(x)
        end
      end
    end

    changed_data.each do |k,v|
      from  = v.split("to")[0].strip rescue ''
      to    = v.split("to")[1].strip rescue ''

      if obs_names.blank?
        obs_names = "#{k}||#{from}||#{to}||#{voided_date}||#{reason}"
      else
        obs_names += "</br>#{k}||#{from}||#{to}||#{voided_date}||#{reason}"
      end
    end

    results = {
        "id"              => patient_id,
        "arv_number"      => arv_number,
        "name"            => name,
        "national_id"     => national_id,
        "encounter_name"  => encounter_name,
        "voided_date"     => voided_date,
        "obs_name"        => obs_names,
        "reason"          => reason
      }

    results
  end

  def self.changed_from(observations)
    changed_obs = ''

    observations.collect do |obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each do |value|
        case value
          when "value_coded"
            next if obs.value_coded.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_datetime"
            next if obs.value_datetime.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_numeric"
            next if obs.value_numeric.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_text"
            next if obs.value_text.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_modifier"
            next if obs.value_modifier.blank?
            changed_obs += "#{obs.to_s}</br>"
        end
      end
    end

    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def self.changed_to(enc)
    encounter_type = enc.encounter_type

    encounter = Encounter.find(:first,
                 :joins       => "INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
                 :conditions  => ["encounter_type=? AND encounter.patient_id=? AND Date(encounter.encounter_datetime)=?",
                                  encounter_type,enc.patient_id, enc.encounter_datetime.to_date],
                 :group       => "encounter.encounter_type",
                 :order       => "encounter.encounter_datetime DESC")

    observations = encounter.observations rescue nil
    return if observations.blank?

    changed_obs = ''
    observations.collect do |obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each do |value|
        case value
          when "value_coded"
            next if obs.value_coded.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_datetime"
            next if obs.value_datetime.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_numeric"
            next if obs.value_numeric.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_text"
            next if obs.value_text.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_modifier"
            next if obs.value_modifier.blank?
            changed_obs += "#{obs.to_s}</br>"
        end
      end
    end

    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def self.visits_by_day(quarter)
    date        = Report.generate_cohort_date_range(quarter)
    start_date  = date.first.beginning_of_day
    end_date    = date.last.end_of_day

    encounters    = Encounter.visits_by_day(start_date, end_date)
    visits_by_day = {}

    encounters.map do |encounter|
      this_day = encounter.encounter_datetime.strftime("%d-%b-%Y")
      (visits_by_day[this_day].nil?) ? visits_by_day[this_day] = 1 : visits_by_day[this_day] += 1
    end

    visits_by_day
  end

  def self.survival_analysis(survival_start_date=@start_date,
                        survival_end_date=@end_date,
                        outcome_end_date=@end_date, min_age=nil, max_age=nil)
    # Make sure these are always dates
    survival_start_date = start_date.to_date
    survival_end_date = end_date.to_date
    outcome_end_date = outcome_end_date.to_date

    date_ranges = Array.new
    first_registration_date = PatientRegistrationDate.find(:first,
      :order => 'registration_date').registration_date

    while (survival_start_date -= 1.year) >= first_registration_date
      survival_end_date   -= 1.year
      date_ranges << {:start_date => survival_start_date,
                      :end_date   => survival_end_date
      }
    end

    survival_analysis_outcomes = Array.new

    date_ranges.each_with_index do |date_range, i|
      outcomes_hash = Hash.new(0)
      all_outcomes = self.outcomes(date_range[:start_date], date_range[:end_date], outcome_end_date, min_age, max_age)

      outcomes_hash["Title"] = "#{(i+1)*12} month survival: outcomes by end of #{outcome_end_date.strftime('%B %Y')}"
      outcomes_hash["Start Date"] = date_range[:start_date]
      outcomes_hash["End Date"] = date_range[:end_date]

      survival_cohort = Reports::CohortByRegistrationDate.new(date_range[:start_date], date_range[:end_date])
      if max_age.nil?
        outcomes_hash["Total"] = survival_cohort.patients_started_on_arv_therapy.length rescue all_outcomes.values.sum
      else
        outcomes_hash["Total"] = all_outcomes.values.sum
      end
      outcomes_hash["Unknown"] = outcomes_hash["Total"] - all_outcomes.values.sum
      outcomes_hash["outcomes"] = all_outcomes

      # if there are no patients registered in that quarter, we must have
      # passed the real date when the clinic opened
      break if outcomes_hash["Total"] == 0
      
      survival_analysis_outcomes << outcomes_hash 
    end
    survival_analysis_outcomes
  end


  def self.cohort(period)
    date_range = Report.generate_cohort_date_range(period)
    start_date = date_range[0] ; end_date = date_range[1]
    cohort = Cohort.new()

    cohort.total_registered = SurvivalAnalysis.report(cohort)
  end

  def self.visits_by_week(visits)

    visits_by_week = visits.inject({}) do |week, visit|

      day       = visit.encounter_datetime.strftime("%a")
      beginning = visit.encounter_datetime.beginning_of_week.to_date

      # add a new week
      week[beginning] = {day => []} if week[beginning].nil?

      #add a new visit to the week
      (week[beginning][day].nil?) ? week[beginning][day] = [visit] : week[beginning][day].push(visit)

      week
    end

    return visits_by_week
  end

  def self.visits_by_week_day(visits)
    week_day_visits = {}
    visits          = CohortTool.visits_by_week(visits)
    weeks           = visits.keys.sort
    week_days       = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    week_days.each_with_index do |day, index|
      weeks.map do  |week|
        visits_number = 0
        visit_date    = week.to_date.strftime("%d-%b-%Y")
        js_date       = week.to_time.to_i * 1000
        this_day      = visits[week][day]


        unless this_day.nil?
          visits_number = this_day.count
          visit_date    = this_day.first.encounter_datetime.to_date.strftime("%d-%b-%Y")
          js_date       = this_day.first.encounter_datetime.to_time.to_i * 1000
        else
        this_day      = (week.to_date + index.days)
        visit_date    = this_day.strftime("%d-%b-%Y")
        js_date       = this_day.to_time.to_i * 1000
        end

        (week_day_visits[day].nil?) ? week_day_visits[day] = [[js_date, visits_number, visit_date]] : week_day_visits[day].push([js_date, visits_number, visit_date])
      end
    end
    week_day_visits
  end

  def self.visiting_patients_by_day(visits)

    patients = visits.inject({}) do |patient, visit|

      visit_date = visit.encounter_datetime.strftime("%d-%b-%Y")

      # get a patient of a given visit
      new_patient   = { :patient_id   => (visit.patient.patient_id || ""),
                        :arv_number   => (visit.patient.arv_number || ""),
                        :name         => (visit.patient.name || ""),
                        :national_id  => (visit.patient.national_id || ""),
                        :gender       => (visit.patient.gender || ""),
                        :age          => (visit.patient.person.age || ""),
                        :birthdate    => (visit.patient.person.birthdate.strftime("%d-%b-%Y") || ""),
                        :phone_number => (visit.patient.person.phone_numbers[:cell_phone_number] || ""),
                        :start_date   => (visit.patient.encounters.last.encounter_datetime.strftime("%d-%b-%Y") || "")
      }

      #add a patient to the day
      (patient[visit_date].nil?) ? patient[visit_date] = [new_patient] : patient[visit_date].push(new_patient)

      patient
    end

    patients
  end

  def self.adherence(quarter="Q1 2009")
  date = Report.generate_cohort_date_range(quarter)

  start_date  = date.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
  end_date    = date.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
  adherences  = Hash.new(0)
  adherence_concept_id = ConceptName.find_by_name("WHAT WAS THE PATIENTS ADHERENCE FOR THIS DRUG ORDER").concept_id

 adherence_sql_statement= " SELECT worse_adherence_dif, pat_ad.person_id as patient_id, pat_ad.value_text AS adherence_rate_worse
                            FROM (SELECT ABS(100 - Abs(value_text)) as worse_adherence_dif, obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, value_text
                                  FROM obs q
                                  WHERE concept_id = #{adherence_concept_id} AND order_id IS NOT NULL
                                  ORDER BY q.obs_datetime DESC, worse_adherence_dif DESC, person_id ASC)pat_ad
                            WHERE pat_ad.obs_datetime >= '#{start_date}' AND pat_ad.obs_datetime<= '#{end_date}'
                            GROUP BY patient_id "

  adherence_rates = Observation.find_by_sql(adherence_sql_statement)

  adherence_rates.each{|adherence|

    rate = adherence.adherence_rate_worse.to_i

    if rate >= 91 and rate <= 94
      cal_adherence = 94
    elsif  rate >= 95 and rate <= 100
      cal_adherence = 100
    else
      cal_adherence = rate + (5- rate%5)%5
    end
    adherences[cal_adherence]+=1
  }
  adherences
  end

  def self.adherence_over_hundred(quater="Q1 2009",min_range = nil,max_range=nil,missing_adherence=false)
    date_range                 = Report.generate_cohort_date_range(quater)
    start_date                 = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date                   = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    adherence_range_filter     = " (adherence_rate_worse >= #{min_range} AND adherence_rate_worse <= #{max_range}) "
    adherence_concept_id       = ConceptName.find_by_name("WHAT WAS THE PATIENTS ADHERENCE FOR THIS DRUG ORDER").concept_id
    brought_drug_concept_id    = ConceptName.find_by_name("AMOUNT OF DRUG BROUGHT TO CLINIC").concept_id

    patients = {}

    if (min_range.blank? or max_range.blank?) and !missing_adherence
        adherence_range_filter = " (adherence_rate_worse > 100) "
    elsif missing_adherence

       adherence_range_filter = " (adherence_rate_worse IS NULL) "

    end

    patients_with_adherences =  " (SELECT   oders.start_date, obs_inner_order.obs_datetime, obs_inner_order.adherence_rate AS adherence_rate,
                                        obs_inner_order.id, obs_inner_order.patient_id, obs_inner_order.drug_inventory_id AS drug_id,
                                        ROUND(DATEDIFF(obs_inner_order.obs_datetime, oders.start_date)* obs_inner_order.equivalent_daily_dose, 0) AS expected_remaining,
                                        obs_inner_order.quantity AS quantity, obs_inner_order.encounter_id, obs_inner_order.order_id
                               FROM (SELECT latest_adherence.obs_datetime, latest_adherence.adherence_rate, latest_adherence.id, latest_adherence.patient_id, latest_adherence.order_id, drugOrder.drug_inventory_id, drugOrder.equivalent_daily_dose, drugOrder.quantity, latest_adherence.encounter_id
                                    FROM (SELECT all_adherences.obs_datetime, all_adherences.value_text AS adherence_rate, all_adherences.obs_id as id, all_adherences.person_id as patient_id,all_adherences.order_id, all_adherences.encounter_id
                                          FROM (SELECT obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, value_text
                                                FROM obs Observations
                                                WHERE concept_id = #{adherence_concept_id}
                                                ORDER BY person_id ASC , Observations.obs_datetime DESC )all_adherences
                                          WHERE all_adherences.obs_datetime >= '#{start_date}' AND all_adherences.obs_datetime<= '#{end_date}'
                                          GROUP BY order_id, patient_id) latest_adherence
                                    INNER JOIN
                                          drug_order drugOrder
                                    On    drugOrder.order_id = latest_adherence.order_id) obs_inner_order
                               INNER JOIN
                                    orders oders
                               On     oders.order_id = obs_inner_order.order_id) patients_with_adherence  "

      worse_adherence_per_patient =" (SELECT worse_adherence_dif, pat_ad.person_id as patient_id, pat_ad.value_text AS adherence_rate_worse
                                FROM (SELECT ABS(100 - Abs(value_text)) as worse_adherence_dif, obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, value_text
                                      FROM obs q
                                      WHERE concept_id = #{adherence_concept_id} AND order_id IS NOT NULL
                                      ORDER BY q.obs_datetime DESC, worse_adherence_dif DESC, person_id ASC)pat_ad
                                WHERE pat_ad.obs_datetime >= '#{start_date}' AND pat_ad.obs_datetime<= '#{end_date}'
                                GROUP BY patient_id ) worse_adherence_per_patient   "

     patient_adherences_sql =  " SELECT *
                                 FROM   #{patients_with_adherences} INNER JOIN #{worse_adherence_per_patient}
                                 ON patients_with_adherence.patient_id = worse_adherence_per_patient.patient_id
                                 WHERE  #{adherence_range_filter} "

      rates = Observation.find_by_sql(patient_adherences_sql)

      patients_rates = []
      rates.each{|rate|
        patients_rates << rate
      }
      adherence_rates = patients_rates

    arv_number_id = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    adherence_rates.each{|rate|

      arv_number = PatientIdentifier.identifier(rate.patient_id, arv_number_id).identifier rescue ""
      patient    = Patient.find(rate.patient_id)
      person     = Person.find(rate.patient_id)
      drug       = Drug.find(rate.drug_id)
      pill_count = Observation.find(:first, :conditions => "order_id = #{rate.order_id} AND encounter_id = #{rate.encounter_id} AND concept_id = #{brought_drug_concept_id} ").value_numeric rescue ""
      if !patients[patient.patient_id] then

          patients[patient.patient_id]={"id" =>patient.id,
                                        "arv_number" => arv_number,
                                        "name" =>patient.name,
                                        "national_id" =>patient.national_id,
                                        "visit_date" =>rate.obs_datetime,
                                        "gender" =>person.gender,
                                        "age" =>patient.age_at_initiation(rate.start_date.to_date),
                                        "birthdate" => person.birthdate,
                                        "pill_count" => pill_count.to_i.to_s,
                                        "adherence" => rate. adherence_rate_worse,
                                        "start_date" => rate.start_date.to_date,
                                        "expected_count" =>rate.expected_remaining,
                                        "drug" => drug.name}
   elsif  patients[patient.patient_id] then

          patients[patient.patient_id]["age"].to_i < patient.age_at_initiation(rate.start_date.to_date).to_i ? patients[patient.patient_id]["age"] = patient.age_at_initiation(rate.start_date.to_date).to_s : ""

          patients[patient.patient_id]["drug"] = patients[patient.patient_id]["drug"].to_s + "<br>#{drug.name}"

          patients[patient.patient_id]["pill_count"] << "<br>#{pill_count.to_i.to_s}"

          patients[patient.patient_id]["expected_count"] << "<br>#{rate.expected_remaining.to_i.to_s}"

          patients[patient.patient_id]["start_date"].to_date > rate.start_date.to_date ?
          patients[patient.patient_id]["start_date"] = rate.start_date.to_date : ""

    end
    }

    patients.sort { |a,b| a[1]['adherence'].to_i <=> b[1]['adherence'].to_i }
  end
end
