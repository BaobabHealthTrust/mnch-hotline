module Report

  def self.generate_report_date_range(start_date, end_date)
    report_date_ranges  = {}

    if end_date
      today       = end_date
      this_week_beginning   = today.beginning_of_week
      last_week_beginning   = (this_week_beginning - 1.week)
      last_week_ending      = (last_week_beginning + 4.days) # the fifth day is the actual beginning of week itself
      this_month_beginning  = today.beginning_of_month

      this_week  = "#{this_week_beginning.strftime("%d-%m")} to #{today.strftime("%d-%m")}"
      last_week  = "#{last_week_beginning.strftime("%d-%m")} to #{last_week_ending.strftime("%d-%m")}"
      this_month = "#{this_month_beginning.strftime("%d-%m")} to #{today.strftime("%d-%m")}"

      report_date_ranges["this_week"]   = {"range"      =>["This Week (#{this_week})"],
                                            "datetime"  =>[this_week_beginning.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")]}

      report_date_ranges["last_week"]   = {"range"      =>["Last Week (#{last_week})"],
                                            "datetime"  =>[last_week_beginning.strftime("%Y-%m-%d"), last_week_ending.strftime("%Y-%m-%d")]}

      report_date_ranges["this_month"]  = {"range"      =>["This Month (#{this_month})"],
                                            "datetime"  =>[this_month_beginning.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")]}
      report_date_ranges["all_dates"]  = {"range"      =>["All Dates"],
                                            "datetime"  =>[start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")]}
    end
    report_date_ranges
  end

  def self.generate_grouping_date_ranges(grouping, start_date, end_date)
    start_date  = start_date.to_date
    end_date    = end_date.to_date

    grouping_date_ranges  = {:display_text => nil, :date_ranges => []}

    case grouping
      when "week"
        grouping_date_ranges[:display_text] = "Week beginning XXXX ending  YYYY"

        current_week  = start_date.beginning_of_week
        final_week    = end_date.beginning_of_week

        begin
          week_beginning  = current_week.beginning_of_week
          week_ending     = current_week.end_of_week
          grouping_date_ranges[:date_ranges].push([week_beginning.strftime("%Y-%m-%d"), week_ending.strftime("%Y-%m-%d")])
          current_week    += 1.week
        end while current_week <= final_week

      when "month"
        grouping_date_ranges[:display_text]  = "Month beginning XXXX ending  YYYY"
        final_month   = end_date.beginning_of_month
        current_month = start_date.beginning_of_month

        begin
          month_beginning  = current_month.beginning_of_month
          month_ending     = current_month.end_of_month
          grouping_date_ranges[:date_ranges].push([month_beginning.strftime("%Y-%m-%d"), month_ending.strftime("%Y-%m-%d")])
          current_month    += 1.month
        end while current_month <= final_month
    end

    return grouping_date_ranges
  end

  def self.patient_demographics_query_builder(patient_type, date_range)
    child_maximum_age     = 9 # see definition of a female adult above
    nearest_health_center = PersonAttributeType.find_by_name("NEAREST HEALTH FACILITY").id

    case patient_type.downcase
      when "women"
        pregnancy_status_concept_id         = Concept.find_by_name("PREGNANCY STATUS").concept_id
        pregnancy_status_encounter_type_id  = EncounterType.find_by_name("PREGNANCY STATUS").encounter_type_id

        extra_parameters = ", pregnancy_status_table.pregnancy_status AS pregnancy_status_text "

        extra_conditions = " AND pregnancy_status_table.person_id = patient.patient_id " +
                           "AND (YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age} "

        sub_query       = ", (SELECT  obs.person_id AS person_id, " +
                              "concept.concept_id, concept_name.name AS name, obs.value_text AS pregnancy_status " +
                              "FROM encounter, obs, concept, concept_name " +
                            "WHERE encounter.encounter_type = #{pregnancy_status_encounter_type_id} " +
                              "AND obs.encounter_id = encounter.encounter_id " +
                              "AND concept.concept_id = #{pregnancy_status_concept_id} " +
                              "AND obs.concept_id = concept.concept_id " +
                              "AND concept_name.concept_id = concept.concept_id " +
                              "AND concept.retired = 0 AND concept_name.voided = 0 " +
                            "GROUP BY person_id " +
                            "ORDER BY obs.person_id, obs.date_created DESC) pregnancy_status_table "

      extra_group_by = ", pregnancy_status_table.pregnancy_status "

      when "children"
        extra_parameters  = ", person.gender AS gender "
        extra_conditions  = "AND (YEAR(patient.date_created) - YEAR(person.birthdate)) <= #{child_maximum_age} "
        sub_query         = ""
        extra_group_by    = ", person.gender "
      else
      extra_parameters  = ", ((YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age}) AS adult "
      extra_conditions  = ""
      sub_query         = ""
      extra_group_by    = ", ((YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age})"
    end

    query = "SELECT person_attribute.value AS nearest_health_center, "+
      "COUNT(patient.patient_id) AS number_of_patients, " +
      "DATE(patient.date_created) AS start_date " + extra_parameters +
    "FROM person_attribute, patient, person " + sub_query +
    "WHERE patient.patient_id = person.person_id " +
      "AND person.person_id = person_attribute.person_id " + extra_conditions +
      "AND DATE(patient.date_created) >= '#{date_range.first}' " +
      "AND DATE(patient.date_created) <= '#{date_range.last}' " +
      "AND patient.voided = 0 " +
      "AND person.voided = 0 " +
      "AND person_attribute.person_attribute_type_id = #{nearest_health_center} " +
    "GROUP BY person_attribute.value " + extra_group_by
    "ORDER BY patient.date_created"

    return query
  end

  def self.patient_demographics(patient_type, grouping, start_date, end_date)

    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    patients_data = []

    date_ranges.map do |date_range|
      query   = self.patient_demographics_query_builder(patient_type, date_range)
      results = Patient.find_by_sql(query)

      case patient_type.downcase
        when "women"
          new_patients_data = self.women_demographics(results, date_range)
        when "children"
          new_patients_data = self.children_demographics(results, date_range)
        else
          new_patients_data = self.all_patients_demographics(results, date_range)
      end # end case
      patients_data.push(new_patients_data)
    end

    patients_data
  end

  def self.all_patients_demographics(patients_data, date_range)
    nearest_health_centers  = []

    mnch_health_facilities_list = Location.find_by_tag("mnch_health_facilities")
    mnch_health_facilities_list.map do |facility|
      nearest_health_centers.push([facility["name"].humanize, 0])
    end

    new_patients_data  = {:new_registrations  => 0,
                          :catchment          => nearest_health_centers.sort,
                          :start_date         => date_range.first,
                          :end_date           => date_range.last}
    children = 0
    women    = 1
    new_patients_data[:patient_type] = [["children", 0], ["women", 0]]

    unless patients_data.blank?
      patients_data.map do|data|
        catchment           = data.attributes["nearest_health_center"]
        number_of_patients  = data.attributes["number_of_patients"].to_i
        adult               = data.attributes["adult"].to_i

        new_patients_data[:new_registrations] += number_of_patients if(number_of_patients)
        i = 0
        new_patients_data[:catchment].map do |c|

          if(c.first == catchment.humanize)
            new_patients_data[:catchment][i][1]           += number_of_patients
            new_patients_data[:patient_type][children][1] += number_of_patients if(adult == children)
            new_patients_data[:patient_type][women][1]    += number_of_patients if(adult == women)
          end
          i += 1
        end
      end
    end
    new_patients_data
  end

  def self.children_demographics(patients_data, date_range)
    nearest_health_centers  = []

    mnch_health_facilities_list = Location.find_by_tag("mnch_health_facilities")
    mnch_health_facilities_list.map do |facility|
      nearest_health_centers.push([facility["name"].humanize, 0])
    end

    new_patients_data  = {:new_registrations  => 0,
                          :catchment          => nearest_health_centers.sort,
                          :start_date         => date_range.first,
                          :end_date           => date_range.last}
    female = 0
    male   = 1
    new_patients_data[:gender] = [["female", 0], ["male", 0]]

    unless patients_data.blank?
      patients_data.map do|data|
        catchment           = data.attributes["nearest_health_center"]
        number_of_patients  = data.attributes["number_of_patients"].to_i
        gender              = data.attributes["gender"]

        new_patients_data[:new_registrations] += number_of_patients if(number_of_patients)
        i = 0
        new_patients_data[:catchment].map do |c|
          if(c.first == catchment.humanize)
            new_patients_data[:catchment][i][1]   += number_of_patients
            new_patients_data[:gender][female][1] += number_of_patients if(gender == "F")
            new_patients_data[:gender][male][1]   += number_of_patients if(gender == "M")
          end
          i += 1
        end
      end
    end
    new_patients_data
  end

  def self.women_demographics(patients_data, date_range)
    nearest_health_centers  = []

    mnch_health_facilities_list = Location.find_by_tag("mnch_health_facilities")
    mnch_health_facilities_list.map do |facility|
      nearest_health_centers.push([facility["name"].humanize, 0])
    end

    new_patients_data  = {:new_registrations  => 0,
                          :catchment          => nearest_health_centers.sort,
                          :start_date         => date_range.first,
                          :end_date           => date_range.last}
    pregnant      = 0
    non_pregnant  = 1
    delivered     = 2
    new_patients_data[:pregnancy_status] = [["pregnant", 0], ["non_pregnant", 0], ["delivered", 0]]

    unless patients_data.blank?
      patients_data.map do|data|
        catchment           = data.attributes["nearest_health_center"]
        number_of_patients  = data.attributes["number_of_patients"].to_i
        pregnancy_status    = data.attributes["pregnancy_status_text"]

        new_patients_data[:new_registrations] += number_of_patients if(number_of_patients)
        i = 0
        new_patients_data[:catchment].map do |c|
          if(c.first == catchment.humanize)
            new_patients_data[:catchment][i][1]                   += number_of_patients
            new_patients_data[:pregnancy_status][pregnant][1]     += number_of_patients if(pregnancy_status == "PREGNANT")
            new_patients_data[:pregnancy_status][non_pregnant][1] += number_of_patients if(pregnancy_status == "NOT PREGNANT")
            new_patients_data[:pregnancy_status][delivered][1]    += number_of_patients if(pregnancy_status == "DELIVERED")
          end
          i += 1
        end
      end
    end
    new_patients_data
  end

  def self.patient_health_issues_query_builder(patient_type, health_task, date_range)
    if health_task.humanize.downcase == "outcomes"
      concepts_list       = ["OUTCOME"]
      encounter_type_list = ["UPDATE OUTCOME"]
      outcomes            = ["REFERRED TO A HEALTH CENTRE",
                              "REFERRED TO NEAREST VILLAGE CLINIC",
                              "PATIENT TRIAGED TO NURSE SUPERVISOR",
                              "GIVEN ADVICE NO REFERRAL NEEDED"]

      extra_parameters    = " obs.value_text AS concept_name, "
      extra_conditions    = " obs.value_text, DATE(obs.date_created), "
    else
      extra_conditions = " DATE(obs.date_created), "
      extra_parameters = " concept_name.name AS concept_name, "

      if patient_type.downcase == "children"
        encounter_type_list = ["CHILD HEALTH SYMPTOMS"]

        case health_task.humanize.downcase
          when "health symptoms"
            concepts_list = ["FEVER", "DIARRHEA", "COUGH", "CONVULSIONS SYMPTOM",
                              "NOT EATING", "VOMITING", "RED EYE",
                              "FAST BREATHING", "VERY SLEEPY", "UNCONSCIOUS"]

          when "danger warning signs"
            concepts_list = ["FEVER OF 7 DAYS OR MORE",
                              "DIARRHEA FOR 14 DAYS OR MORE",
                              "BLOOD IN STOOL", "COUGH FOR 21 DAYS OR MORE",
                              "CONVULSIONS SIGN", "NOT EATING OR DRINKING ANYTHING",
                              "VOMITING EVERYTHING",
                              "RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS",
                              "VERY SLEEPY OR UNCONSCIOUS", "POTENTIAL CHEST INDRAWING"]

          when "health information requested"
            concepts_list = ["SLEEPING", "FEEDING PROBLEMS", "CRYING",
                              "BOWEL MOVEMENTS", "SKIN RASHES", "SKIN INFECTIONS",
                              "UMBILICUS INFECTION", "GROWTH MILESTONES",
                              "ACCESSING HEALTHCARE SERVICES"]
        end

      elsif patient_type.downcase == "women"
        encounter_type_list = ["MATERNAL HEALTH SYMPTOMS"]

        case health_task.humanize.downcase
          when "health symptoms"
            concepts_list = ["VAGINAL BLEEDING DURING PREGNANCY",
                              "POSTNATAL BLEEDING", "FEVER DURING PREGNANCY SYMPTOM",
                              "POSTNATAL FEVER SYMPTOM", "HEADACHES",
                              "FITS OR CONVULSIONS SYMPTOM",
                              "SWOLLEN HANDS OR FEET SYMPTOM",
                              "PALENESS OF THE SKIN AND TIREDNESS SYMPTOM",
                              "NO FETAL MOVEMENTS SYMPTOM", "WATER BREAKS SYMPTOM"]

          when "danger warning signs"
            concepts_list = ["HEAVY VAGINAL BLEEDING DURING PREGNANCY",
                              "EXCESSIVE POSTNATAL BLEEDING",
                              "FEVER DURING PREGNANCY SIGN",
                              "POSTNATAL FEVER SIGN", "SEVERE HEADACHE",
                              "FITS OR CONVULSIONS SIGN",
                              "SWOLLEN HANDS OR FEET SIGN",
                              "PALENESS OF THE SKIN AND TIREDNESS SIGN",
                              "NO FETAL MOVEMENTS SIGN", "WATER BREAKS SIGN"]

          when "health information requested"
            concepts_list = ["HEALTHCARE VISITS", "NUTRITION", "BODY CHANGES",
                              "DISCOMFORT", "CONCERNS", "EMOTIONS",
                              "WARNING SIGNS", "ROUTINES", "BELIEFS",
                              "BABY'S GROWTH", "MILESTONES", "PREVENTION"]
        end

      end
    end
    concept_ids     = ""
    concept_map     = []
    call_count      = 0
    call_percentage = 0
    concepts_list.each do |concept_name|
      concept_id = Concept.find_by_name("#{concept_name}").id rescue nil
      next if concept_id.nil?

      concept_ids += concept_id.to_s + ", "
      if concept_name == "OUTCOME"
        outcomes.each do |concept_name|
          mapping = {:concept_name  => concept_name,  :concept_id       => concept_id,
                     :call_count    => call_count,    :call_percentage  => call_percentage}

          concept_map.push(mapping)
        end
      else
        mapping = {:concept_name  => concept_name,  :concept_id       => concept_id,
                     :call_count  => call_count,    :call_percentage  => call_percentage}

          concept_map.push(mapping)
      end
    end

    encounter_type_ids = ""
    encounter_type_list.each do |encounter_type|
      encounter_type_id = EncounterType.find_by_name("#{encounter_type}").id rescue nil
      next if encounter_type_id.nil?
      encounter_type_ids += encounter_type_id.to_s + ", "
    end

    concept_ids.strip!.chop!
    encounter_type_ids.strip!.chop!

    query = "SELECT encounter_type.name AS encounter_type_name, " +
              "COUNT(obs.person_id) AS number_of_patients," + extra_parameters +
              "concept.concept_id AS concept_id, DATE(encounter.date_created) AS start_date " +
            "FROM encounter, encounter_type, obs, concept, concept_name " +
            "WHERE encounter_type.encounter_type_id IN (#{encounter_type_ids}) " +
              "AND concept.concept_id IN (#{concept_ids}) " +
              "AND encounter_type.encounter_type_id = encounter.encounter_type " +
              "AND obs.concept_id = concept_name.concept_id " +
              "AND obs.concept_id = concept.concept_id " +
              "AND encounter.encounter_id = obs.encounter_id " +
              "AND DATE(obs.date_created) >= '#{date_range.first}' " +
              "AND DATE(obs.date_created) <= '#{date_range.last}' " +
              "AND encounter.voided = 0 AND obs.voided = 0 AND concept_name.voided = 0 " +
            "GROUP BY encounter_type.encounter_type_id," + extra_conditions + "obs.concept_id " +
            "ORDER BY encounter_type.name, DATE(obs.date_created), obs.concept_id"

    {:query => query, :concept_map => concept_map}
  end


  def self.call_count(date_range)
    call_id = Concept.find_by_name("CALL ID").id
    query   = "SELECT COUNT(obs.person_id) AS call_count, " +
                  "concept_name.name AS concept_name, " +
                  "DATE(encounter.date_created) AS start_date " +
                "FROM encounter, encounter_type, obs, concept, concept_name " +
                "WHERE concept.concept_id = #{call_id} " +
                  "AND encounter_type.encounter_type_id = encounter.encounter_type " +
                  "AND obs.concept_id = concept_name.concept_id " +
                  "AND obs.concept_id = concept.concept_id " +
                  "AND encounter.encounter_id = obs.encounter_id " +
                  "AND DATE(obs.date_created) >= '#{date_range.first}' " +
                  "AND DATE(obs.date_created) <= '#{date_range.last}' " +
                  "AND encounter.voided = 0 AND obs.voided = 0 AND concept_name.voided = 0 " +
                "GROUP BY obs.concept_id " +
                "ORDER BY encounter_type.name, DATE(obs.date_created), obs.concept_id"

    Patient.find_by_sql(query)
  end

  def self.patient_health_issues(patient_type, grouping, health_task, start_date, end_date)
    patients_data = []
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      query_builder = self.patient_health_issues_query_builder(patient_type, health_task, date_range)
      query         = query_builder[:query]
      concept_map   = query_builder[:concept_map]

      results               = Patient.find_by_sql(query)
      total_call_count      = self.call_count(date_range)
      total_number_of_calls = total_call_count.first.attributes["call_count"].to_i rescue 0

      new_patients_data                 = {}
      new_patients_data[:health_issues] = concept_map
      new_patients_data[:start_date]    = date_range.first
      new_patients_data[:end_date]      = date_range.last

      unless results.blank?
        (health_task.humanize.downcase == "outcomes")? outcomes = true : outcomes = false
        results.map do|data|

          concept_name        = data.attributes["concept_name"].upcase
          concept_id          = data.attributes["concept_id"].to_i
          number_of_patients  = data.attributes["number_of_patients"].to_i
          i = 0

          new_patients_data[:health_issues].each do |health_issue|
            update_statistics = false
            if outcomes
              update_statistics = true if(health_issue[:concept_name] == concept_name)
            else
              update_statistics = true if(health_issue[:concept_id].to_i == concept_id)
            end

            next if !update_statistics

            number_of_patients_so_far  = new_patients_data[:health_issues][i][:call_count]
            number_of_patients_so_far += number_of_patients
            call_percentage            = ((number_of_patients_so_far * 100.0)/total_number_of_calls).round(1) rescue 0

            new_patients_data[:health_issues][i][:call_count]       = number_of_patients_so_far
            new_patients_data[:health_issues][i][:call_percentage]  = call_percentage

            break
            i += 1
          end
        end
      end

      patients_data.push(new_patients_data)
    end
    patients_data
  end

end
