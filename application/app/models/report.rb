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

    #raise query.to_s
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

  def self.patient_health_issues_query_builder(patient_type, health_task, date_range, essential_params)
    concept_ids         = essential_params[:concept_ids]
    encounter_type_ids  = essential_params[:encounter_type_ids]
    extra_conditions    = essential_params[:extra_conditions]
    extra_parameters    = essential_params[:extra_parameters]

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

    #raise query.to_yaml
    query
  end

  def self.prepopulate_concept_ids_and_extra_parameters(patient_type, health_task)
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
                              "NO FETAL MOVEMENTS SYMPTOM", "WATER BREAKS SYMPTOM",
                              "FEVER", "DIARRHEA", "COUGH", "CONVULSIONS SYMPTOM",
                              "NOT EATING", "VOMITING", "RED EYE",
                              "FAST BREATHING", "VERY SLEEPY", "UNCONSCIOUS"
                              ]

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
      else #all
        encounter_type_list = ["MATERNAL HEALTH SYMPTOMS", "CHILD HEALTH SYMPTOMS"]

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
                              "NO FETAL MOVEMENTS SIGN", "WATER BREAKS SIGN",
                              "FEVER OF 7 DAYS OR MORE",
                              "DIARRHEA FOR 14 DAYS OR MORE",
                              "BLOOD IN STOOL", "COUGH FOR 21 DAYS OR MORE",
                              "CONVULSIONS SIGN", "NOT EATING OR DRINKING ANYTHING",
                              "VOMITING EVERYTHING",
                              "RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS",
                              "VERY SLEEPY OR UNCONSCIOUS", "POTENTIAL CHEST INDRAWING"
                              ]

          when "health information requested"
            concepts_list = ["HEALTHCARE VISITS", "NUTRITION", "BODY CHANGES",
                              "DISCOMFORT", "CONCERNS", "EMOTIONS",
                              "WARNING SIGNS", "ROUTINES", "BELIEFS",
                              "BABY'S GROWTH", "MILESTONES", "PREVENTION",
                              "SLEEPING", "FEEDING PROBLEMS", "CRYING",
                              "BOWEL MOVEMENTS", "SKIN RASHES", "SKIN INFECTIONS",
                              "UMBILICUS INFECTION", "GROWTH MILESTONES",
                              "ACCESSING HEALTHCARE SERVICES"
                              ]
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

    params = {:concept_ids        => concept_ids,
              :concept_map        => concept_map,
              :encounter_type_ids => encounter_type_ids,
              :extra_conditions   => extra_conditions,
              :extra_parameters   => extra_parameters}

    params
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

    essential_params  = self.prepopulate_concept_ids_and_extra_parameters(patient_type, health_task)

    date_ranges.map do |date_range|
      query = self.patient_health_issues_query_builder(patient_type, health_task, date_range, essential_params)
      concept_map           = Marshal.load(Marshal.dump(essential_params[:concept_map]))
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

          new_patients_data[:health_issues].each_with_index do |health_issue, i|
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

          end
        end
      end

      patients_data.push(new_patients_data)
    end
    patients_data
  end

  def self.patient_age_distribution(patient_type, grouping, start_date, end_date)

    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    patients_data = []

    date_ranges.map do |date_range|
      query   = self.patient_demographics_query_builder(patient_type, date_range)
      results = Patient.find_by_sql(query)
      data_for_patients = {:patient_data => {}, :statistical_data => {}}
      case patient_type.downcase
        when "women"
          new_patients_data = self.women_demographics(results, date_range)
          statistical_data = Patient.find_by_sql(self.get_age_statistics(patient_type, date_range))

          patient_statistics = self.create_patient_statistics(patient_type,
                                statistical_data) unless statistical_data.empty?

          data_for_patients[:patient_data] = new_patients_data
          data_for_patients[:statistical_data] = patient_statistics rescue ''

        when "children"
          new_patients_data = self.children_demographics(results, date_range)
          statistical_data = Patient.find_by_sql(self.get_age_statistics(patient_type, date_range))
          patient_statistics = self.create_patient_statistics(patient_type,
                                statistical_data) unless statistical_data.empty?

          data_for_patients[:patient_data] = new_patients_data
          data_for_patients[:statistical_data] = patient_statistics rescue ''
        else
          new_patients_data = self.all_patients_demographics(results, date_range)
          statistical_data = Patient.find_by_sql(self.get_age_statistics(patient_type, date_range))

          patient_statistics = self.create_patient_statistics(patient_type,
                                statistical_data) unless statistical_data.empty?

          data_for_patients[:patient_data] = new_patients_data
          data_for_patients[:statistical_data] = patient_statistics rescue ''

      end # end case
      patients_data.push(data_for_patients)
    end

    patients_data
  end

  def self.get_age_statistics(patient_type, date_range)

    child_maximum_age     = 9 # see definition of a female adult above
    nearest_health_center = PersonAttributeType.find_by_name("NEAREST HEALTH FACILITY").id

    case patient_type.downcase
      when "women"
        pregnancy_status_concept_id         = Concept.find_by_name("PREGNANCY STATUS").concept_id
        pregnancy_status_encounter_type_id  = EncounterType.find_by_name("PREGNANCY STATUS").encounter_type_id

        extra_parameters = "SELECT (YEAR(patient.date_created) - YEAR(person.birthdate)) AS Age,
                            pregnancy_status_table.pregnancy_status AS pregnancy_status_text"

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
        extra_parameters  = "SELECT PERIOD_DIFF(CONCAT(YEAR(patient.date_created),
                              IF(MONTH(patient.date_created)<10,'0',''),
                              MONTH(patient.date_created)),
                              CONCAT(YEAR(person.birthdate),
                              IF(MONTH(person.birthdate)<10,'0',''),
                              MONTH(person.birthdate))) AS Age, person.gender AS gender "
        extra_conditions  = "AND (YEAR(patient.date_created) - YEAR(person.birthdate)) <= #{child_maximum_age} "
        sub_query         = ""
        extra_group_by    = ", person.gender "
      else
      extra_parameters  = "SELECT PERIOD_DIFF(CONCAT(YEAR(patient.date_created),
                              IF(MONTH(patient.date_created)<10,'0',''),
                              MONTH(patient.date_created)),
                              CONCAT(YEAR(person.birthdate),
                              IF(MONTH(person.birthdate)<10,'0',''),
                              MONTH(person.birthdate))) AS age_in_months,
                          (YEAR(patient.date_created) - YEAR(person.birthdate)) as age_in_years,
                          ((YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age}) AS adult"
      extra_conditions  = ""
      sub_query         = ""
      extra_group_by    = ",((YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age}) "
    end

    query = extra_parameters +
    " FROM person_attribute, patient, person " + sub_query +
    "WHERE patient.patient_id = person.person_id " +
      "AND person.person_id = person_attribute.person_id " + extra_conditions +
      "AND DATE(patient.date_created) >= '#{date_range.first}' " +
      "AND DATE(patient.date_created) <= '#{date_range.last}' " +
      "AND patient.voided = 0 " +
      "AND person.voided = 0 " +
      "AND person_attribute.person_attribute_type_id = #{nearest_health_center} " +
    "ORDER BY patient.date_created"

    return query
  end

  def self.create_patient_statistics(patient_type, patient_data)

    case patient_type.downcase
      when 'women'
        women_grouping = {:pregnant => {}, :nonpregnant => {},
                          :delivered => {}
        }
        pregnant_data = []
        nonpregnant_data = []
        delivered_data = []

      #raise patient_data.first[:pregnancy_status_text].downcase
        unless patient_data.empty?
          patient_data.each do |value|
            case value[:pregnancy_status_text].downcase
            when 'pregnant'
              pregnant_data << value[:Age].to_i 
            when 'nonpregnant'
              nonpregnant_data << value[:Age].to_i
            when 'delivered'
              delivered_data << value[:Age].to_i
            end
          end
        end

      unless pregnant_data.empty?
          pregnant_statistics = {:total => 0, :percentage => 0,
                         :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          pregnant_statistics[:min] = pregnant_data.min
          pregnant_statistics[:max] = pregnant_data.max
          pregnant_statistics[:percentage] = (pregnant_data.count.to_f / patient_data.count.to_f * 100).round(1)
          pregnant_statistics[:average] = self.calculate_average_age(pregnant_data.flatten)
          pregnant_statistics[:sdev] = self.calculate_sdev_age(pregnant_data)

          women_grouping[:pregnant][:statistical_info] = pregnant_statistics
        end

        unless nonpregnant_data.empty?
          nonpregnant_statistics = {:total => 0, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          nonpregnant_statistics[:min] = nonpregnant_data.min
          nonpregnant_statistics[:max] = nonpregnant_data.max
          nonpregnant_statistics[:percentage] = (nonpregnant_data.count.to_f / patient_data.count.to_f * 100).round(1)
          nonpregnant_statistics[:average] = self.calculate_average_age(nonpregnant_data)
          nonpregnant_statistics[:sdev] = self.calculate_sdev_age(nonpregnant_data)

          women_grouping[:nonpregnant][:statistical_info] = nonpregnant_statistics

        end
        unless delivered_data.empty?
          delivered = {:total => 0, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          delivered[:min] = delivered_data.min
          delivered[:max] = delivered_data.max
          delivered[:percentage] = (delivered_data.count.to_f / patient_data.count.to_f * 100).round(1)
          delivered[:average] = self.calculate_average_age(delivered_data)
          delivered[:sdev] = self.calculate_sdev_age(delivered_data)

          women_grouping[:delivered][:statistical_info] = delivered_statistics
        end
        return_data = women_grouping

      when 'children'
        child_grouping = {:female => {}, :male => {}}

        female_data = []
        male_data = []
        
        unless patient_data.empty?
          patient_data.each do |value|
            female_data << value[:Age].to_i if value[:gender].downcase.to_s == 'f'
            male_data << value[:Age].to_i if value[:gender].downcase.to_s == 'm'     
          end
        end
        
        unless female_data.empty?
          female_statistics = {:total => 0, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          female_statistics[:min] = female_data.min
          female_statistics[:max] = female_data.max
          female_statistics[:percentage] = (female_data.count.to_f / patient_data.count.to_f * 100).round(1)
          female_statistics[:average] = self.calculate_average_age(female_data)
          female_statistics[:sdev] = self.calculate_sdev_age(female_data)

          child_grouping[:female][:statistical_info] = female_statistics
        end

        unless male_data.empty?
          male_statistics = {:total => 0, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          male_statistics[:min] = male_data.min
          male_statistics[:max] = male_data.max
          male_statistics[:percentage] = (male_data.count.to_f / patient_data.count.to_f  * 100).round(1)
          male_statistics[:average] = self.calculate_average_age(male_data)
          male_statistics[:sdev] = self.calculate_sdev_age(male_data)

          child_grouping[:male][:statistical_info] = male_statistics
        end

      return_data = child_grouping
      else
        all_grouping = {:women=> {}, :child => {}}

        child_data = []
        women_data = []

        unless patient_data.empty?
          patient_data.each do |value|
            women_data << value[:age_in_years].to_i if value[:adult].to_i == 1
            child_data << value[:age_in_months].to_i if value[:adult].to_i == 0
          end
        end

        unless child_data.empty?
          child_statistics = {:total => 0, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          child_statistics[:min] = child_data.min
          child_statistics[:max] = child_data.max
          child_statistics[:percentage] = (child_data.count.to_f / patient_data.count.to_f  * 100).round(1)
          child_statistics[:average] = self.calculate_average_age(child_data)
          child_statistics[:sdev] = self.calculate_sdev_age(child_data)

          all_grouping[:child][:statistical_info] = child_statistics
        end

        unless women_data.empty?
          women_statistics = {:total => 0, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          women_statistics[:min] = women_data.min
          women_statistics[:max] = women_data.max
          women_statistics[:percentage] = (women_data.count.to_f / patient_data.count.to_f  * 100).round(1)
          women_statistics[:average] = self.calculate_average_age(women_data)
          women_statistics[:sdev] = self.calculate_sdev_age(women_data)

          all_grouping[:women][:statistical_info] = women_statistics
        end

      return_data = all_grouping

    end

    return return_data
  end

 def self.calculate_average_age(data)
   return  (data.inject{ |sum, el| sum + el }.to_f / data.size).round(1)
 end

 def self.calculate_sdev_age(data)
   mean = data.sum / data.length
   new_data = []

   data.each do |el|
      new_data << ((el - mean) * (el - mean))
   end

   sdev = Math.sqrt(new_data.sum / (new_data.count - 1)).round(1)

   return sdev
 end

 def self.patient_activity(patient_type, grouping, start_date, end_date)
  patients_data = []
  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      
      query   = self.patient_demographics_query_builder(patient_type, date_range)
      results = Patient.find_by_sql(query)
      #data_for_patients = {:patient_data => {}, :statistical_data => {}}
      patient_statistics = {:start_date => date_range.first, 
                            :end_date => date_range.last, :total => 0,
                            :symptoms => 0, :symptoms_pct => 0,
                            :danger => 0, :danger_pct => 0,
                            :info => 0, :info_pct => 0
      }
      activity_type = ["symptoms","danger","info"]
      case patient_type.downcase
        when "women"
          new_patients_data = self.women_demographics(results, date_range)
          total_patients = 0
          new_patients_data[:pregnancy_status].each do |status|
            total_patients += status.last
          end
          patient_statistics[:total] = total_patients

         activity_type.each do |type|
          activity = 'health symptoms' if type == 'symptoms'
          activity = 'danger warning signs' if type == 'danger'
          activity = 'health information requested' if type == 'info'
            essential_params  = self.prepopulate_concept_ids_and_extra_parameters(patient_type, activity)
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params)
            activity_data = Patient.find_by_sql(data_query)
            if type == 'symptoms'
              patient_statistics[:symptoms] = activity_data.first.number_of_patients.to_i
              patient_statistics[:symptoms_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            elsif type == 'danger'
              patient_statistics[:danger] = activity_data.first.number_of_patients.to_i
              patient_statistics[:danger_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            elsif type == 'info'
              patient_statistics[:info] = activity_data.first.number_of_patients.to_i
              patient_statistics[:info_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            end
         end

        when "children"
          new_patients_data = self.children_demographics(results, date_range)
          total_patients = 0
          new_patients_data[:gender].each do |status|
            total_patients += status.last
          end
          patient_statistics[:total] = total_patients

         activity_type.each do |type|
          activity = 'health symptoms' if type == 'symptoms'
          activity = 'danger warning signs' if type == 'danger'
          activity = 'health information requested' if type == 'info'
            essential_params  = self.prepopulate_concept_ids_and_extra_parameters(patient_type, activity)
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params)
            activity_data = Patient.find_by_sql(data_query)
            if type == 'symptoms'
              patient_statistics[:symptoms] = activity_data.first.number_of_patients.to_i
              patient_statistics[:symptoms_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            elsif type == 'danger'
              patient_statistics[:danger] = activity_data.first.number_of_patients.to_i
              patient_statistics[:danger_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            elsif type == 'info'
              patient_statistics[:info] = activity_data.first.number_of_patients.to_i
              patient_statistics[:info_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            end
         end
        else
          new_patients_data = self.all_patients_demographics(results, date_range)
          total_patients = 0
          new_patients_data[:patient_type].each do |status|
            total_patients += status.last
          end
          patient_statistics[:total] = total_patients

         activity_type.each do |type|
          activity = 'health symptoms' if type == 'symptoms'
          activity = 'danger warning signs' if type == 'danger'
          activity = 'health information requested' if type == 'info'
            essential_params  = self.prepopulate_concept_ids_and_extra_parameters(patient_type, activity)
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params)
            activity_data = Patient.find_by_sql(data_query)
            if type == 'symptoms'
              patient_statistics[:symptoms] = activity_data.first.number_of_patients.to_i
              patient_statistics[:symptoms_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1)  if patient_statistics[:total].to_f != 0
            elsif type == 'danger'
              patient_statistics[:danger] = activity_data.first.number_of_patients.to_i
              patient_statistics[:danger_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            elsif type == 'info'
              patient_statistics[:info] = activity_data.first.number_of_patients.to_i
              patient_statistics[:info_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            end
         end

      end # end case
      patients_data << patient_statistics
    end
    patients_data
  end

 def self.patient_activity_query_builder(patient_type, health_task, date_range, essential_params)
    concept_ids         = essential_params[:concept_ids]
    encounter_type_ids  = essential_params[:encounter_type_ids]
    #extra_conditions    = essential_params[:extra_conditions]
    #extra_parameters    = essential_params[:extra_parameters]

    query = "SELECT COUNT(obs.person_id) AS number_of_patients "  +
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
            "ORDER BY encounter_type.name, DATE(obs.date_created), obs.concept_id"

    #raise query.to_yaml
    query
  end

 def self.patient_referral_followup(patient_type, grouping, outcome, start_date, end_date)
    patient_data = []
    youth_age = 9

   #raise params.to_yaml
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      patient_info = []
      patient_data_elements = {:date_range => [], :patient_info => []}

      if patient_type.downcase == "Women"
        condition_options = ["encounter_type = ?
                                    AND encounter_datetime >= ?
                                    AND encounter_datetime <= ?
                                    AND obs.concept_id = ?
                                    AND obs.value_text = ?
                                    AND (YEAR(encounter.encounter_datetime) - YEAR(person.birthdate)) >= ?",
                      EncounterType.find_by_name("Update Outcome").id,
                      date_range.first, date_range.last,
                      Concept.find_by_name("Outcome").id,
                      outcome, youth_age]
      elsif patient_type.downcase == 'children'
        condition_options = ["encounter_type = ?
                                    AND encounter_datetime >= ?
                                    AND encounter_datetime <= ?
                                    AND obs.concept_id = ?
                                    AND obs.value_text = ?
                                    AND (YEAR(encounter.encounter_datetime) - YEAR(person.birthdate)) <= ?",
                      EncounterType.find_by_name("Update Outcome").id,
                      date_range.first, date_range.last,
                      Concept.find_by_name("Outcome").id,
                      outcome, youth_age]
      else
        condition_options = ["encounter_type = ?
                                    AND encounter_datetime >= ?
                                    AND encounter_datetime <= ?
                                    AND obs.concept_id = ?
                                    AND obs.value_text = ?",
                      EncounterType.find_by_name("Update Outcome").id,
                      date_range.first, date_range.last,
                      Concept.find_by_name("Outcome").id,
                      outcome]

      end
      
      o_encounters = Encounter.find(:all,
                   :joins =>"INNER JOIN obs ON encounter.encounter_id = obs.encounter_id
                             INNER JOIN person ON patient_id = person.person_id",
                   :conditions => condition_options
                  )

     #raise o_encounters.to_yaml
      o_encounters.each do |a_encounter|

         patient_information = {:name => '', :number => '', :visit_summary => ''}

         a_person = Person.find(a_encounter.observations.first.person_id)

         patient_information[:name] = a_person.name
         patient_information[:number] = a_person.phone_numbers
         patient_information[:visit_summary] = get_call_summary(a_person.id,
                                                a_encounter.encounter_datetime.strftime("%Y-%m-%d"))

        patient_info << patient_information
      end
      patient_data_elements[:date_range] = date_range
      patient_data_elements[:patient_info] = patient_info

     patient_data << patient_data_elements
       
    end

    return patient_data
  end

 def self.get_call_summary(patient_id, encounter_date)

   encounter_types = EncounterType.find(:all,
                                 :conditions =>["name = ?
                                  or name = ?", 'MATERNAL HEALTH SYMPTOMS',
                                  "CHILD HEALTH SYMPTOMS"]).map{|e|
                                                          e.encounter_type_id}

   patient_encounters = Encounter.find(:all,
                   :conditions =>["encounter_type IN (?)
                                  AND encounter_datetime like ?
                                  AND patient_id = ?",
                                  encounter_types, "#{encounter_date}%", patient_id
                  ])

        danger_signs = []
        health_information = []
        health_symptoms = []
        return_string = ""

        patient_encounters.each do |a_encounter|
          for obs in a_encounter.observations do
            if obs.name_to_s != "CALL ID"
               name_tag_id = ConceptNameTagMap.find(:all,
                                                    :conditions =>["concept_name_id = ?", obs.concept_id],
                                                    :select => "concept_name_tag_id"
                                                   ).last

               symptom_type = ConceptNameTag.find(:all,
                                                  :conditions =>["concept_name_tag_id = ?", name_tag_id.concept_name_tag_id],
                                                  :select => "tag"
                                                  ).uniq
              symptom_type.each{|symptom|
                if symptom.tag == "HEALTH INFORMATION"
                  health_information << obs.name_to_s.capitalize
                elsif symptom.tag == "DANGER SIGN"
                  danger_signs << obs.name_to_s.capitalize
                elsif symptom.tag == "HEALTH SYMPTOM"
                  health_symptoms << obs.name_to_s.capitalize
                end
              }
            end
          end
        end

        if danger_signs.length != 0
          return_string = "<B>Danger Signs : </B>" + danger_signs.join(", ").to_s
        end
        if health_information.length != 0
          return_string =  return_string + " <B> Health Information : </B>" + health_information.join(", ").to_s
        end
        if health_symptoms.length != 0
          return_string = return_string + " <B> Health Symptoms : </B>" + health_symptoms.join(", ").to_s
        end

        return_string = 'None' if return_string == ''
        return return_string
 end

 def self.call_time_of_day(patient_type, grouping, call_type, call_status,
                                     staff_member, start_date, end_date)
  call_data = []

  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]

    date_ranges.map do |date_range|

      query   = self.call_analysis_query_builder(patient_type,
                      date_range, staff_member, call_type, call_status)

      results = CallLog.find_by_sql(query)

      raise results.to_yaml

      call_statistics = {:start_date => date_range.first,
                            :end_date => date_range.last, :total => results.count,
                            :morning => 0, :morning_pct => 0,
                            :midday => 0, :midday_pct => 0,
                            :afternoon => 0, :afternoon_pct => 0,
                            :evening => 0, :evening_pct => 0
                           }

     results.each do |call|

       if Time.parse(call.call_start_time) >= Time.parse("07:00:00") && Time.parse(call.call_start_time) <= Time.parse("10:00:00")
         call_statistics[:morning] += 1
       elsif Time.parse(call.call_start_time) > Time.parse("10:00:00") && Time.parse(call.call_start_time) <= Time.parse("13:00:00")
         call_statistics[:midday] += 1
       elsif Time.parse(call.call_start_time) > Time.parse("13:00:00") && Time.parse(call.call_start_time) <= Time.parse("16:00:00")
         call_statistics[:afternoon] += 1
       elsif Time.parse(call.call_start_time) > Time.parse("16:00:00") && Time.parse(call.call_start_time) <= Time.parse("19:00:00")
         call_statistics[:evening] += 1
       end
     end #end of results loop

     call_statistics[:morning_pct] = (call_statistics[:morning].to_f / results.count.to_f * 100).round(1) if call_statistics[:morning] != 0
     call_statistics[:midday_pct] = (call_statistics[:midday].to_f / results.count.to_f * 100).round(1) if call_statistics[:midday] != 0
     call_statistics[:afternoon_pct] = (call_statistics[:afternoon].to_f / results.count.to_f * 100).round(1) if call_statistics[:afternoon] != 0
     call_statistics[:evening_pct] = (call_statistics[:evening].to_f / results.count.to_f * 100).round(1) if call_statistics[:evening] != 0


     call_data << call_statistics

    end #end of period loop

   return call_data
 end

 def self.call_analysis_query_builder(patient_type, date_range, staff_id, call_type, call_status)
   child_maximum_age     = 9 # see definition of a female adult above
   call_concept_id = Concept.find_by_name('call id').id
   extra_conditions = " "
   extra_grouping = " "

   case patient_type.downcase
     when 'women'
        extra_conditions += " AND (YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age} "
     when 'children'
        extra_conditions += " AND (YEAR(patient.date_created) - YEAR(person.birthdate)) <= #{child_maximum_age} "
   end

   if staff_id.downcase != 'all'
     extra_conditions += " AND obs.creator = '#{staff_id.to_i}' "
   else
     extra_grouping += ", users.username"
   end

   if call_type != 'All'
     case call_type.downcase
     when 'normal'
       call_type_code = 0
     when 'emergency'
       call_type_code = 1
     when 'irrelevant'
       call_type_code = 2
     else
       call_type_code = 0 #not sure as they have not been implemented yet
     end
     extra_conditions += " AND call_log.call_type = '#{call_type_code}' "
   end

   if call_status != 'All'
     extra_conditions = extra_conditions
   end

   query = "SELECT TIME(call_log.start_time) AS call_start_time, " +
           "TIME(call_log.end_time) AS call_end_time, " +
           "users.username, DATE_FORMAT(start_time,'%W') AS day_of_week, " +
           "TIMESTAMPDIFF(SECOND, call_log.start_time, call_log.end_time) AS call_length_seconds, " +
           "TIMESTAMPDIFF(MINUTE, call_log.start_time, call_log.end_time) AS call_length_minutes " +
           "FROM call_log " +
           "INNER JOIN obs ON obs.value_text = call_log.call_log_id " +
           "INNER JOIN person ON person.person_id = obs.person_id " +
           "INNER JOIN users ON users.user_id = obs.creator " +
           "INNER JOIN patient ON patient.patient_id = person.person_id " +
           "WHERE obs.concept_id = #{call_concept_id} " +
           "AND DATE(call_log.start_time) >= '#{date_range.first}' " +
           "AND DATE(call_log.start_time) <= '#{date_range.last}' " +
           " AND obs.voided = 0 " + extra_conditions +
           " GROUP BY call_log.call_log_id" + extra_grouping

   raise query.to_s
   return query
  end

 def self.call_day_distribution(patient_type, grouping, call_type, call_status,
                                     staff_member, start_date, end_date)
  call_data = []

  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]

    date_ranges.map do |date_range|

      query   = self.call_analysis_query_builder(patient_type,
                      date_range, staff_member, call_type, call_status)

      results = CallLog.find_by_sql(query)

      call_statistics = {:start_date => date_range.first,
                            :end_date => date_range.last, :total => results.count,
                            :morning => 0, :morning_pct => 0,
                            :midday => 0, :midday_pct => 0,
                            :afternoon => 0, :afternoon_pct => 0,
                            :evening => 0, :evening_pct => 0
                           }

     results.each do |call|

       if Time.parse(call.call_start_time) >= Time.parse("07:00:00") && Time.parse(call.call_start_time) <= Time.parse("10:00:00")
         call_statistics[:morning] += 1
       elsif Time.parse(call.call_start_time) > Time.parse("10:00:00") && Time.parse(call.call_start_time) <= Time.parse("13:00:00")
         call_statistics[:midday] += 1
       elsif Time.parse(call.call_start_time) > Time.parse("13:00:00") && Time.parse(call.call_start_time) <= Time.parse("16:00:00")
         call_statistics[:afternoon] += 1
       elsif Time.parse(call.call_start_time) > Time.parse("16:00:00") && Time.parse(call.call_start_time) <= Time.parse("19:00:00")
         call_statistics[:evening] += 1
       end
     end #end of results loop

     call_statistics[:morning_pct] = (call_statistics[:morning].to_f / results.count.to_f * 100).round(1) if call_statistics[:morning] != 0
     call_statistics[:midday_pct] = (call_statistics[:midday].to_f / results.count.to_f * 100).round(1) if call_statistics[:midday] != 0
     call_statistics[:afternoon_pct] = (call_statistics[:afternoon].to_f / results.count.to_f * 100).round(1) if call_statistics[:afternoon] != 0
     call_statistics[:evening_pct] = (call_statistics[:evening].to_f / results.count.to_f * 100).round(1) if call_statistics[:evening] != 0


     call_data << call_statistics

    end #end of period loop

   return call_data
 end

end
