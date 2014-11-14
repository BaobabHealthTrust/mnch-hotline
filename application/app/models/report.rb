module Report

  def self.generate_report_date_range(start_date, end_date)
    report_date_ranges  = {}

    if end_date
      today       = end_date
      this_week_beginning   = today.beginning_of_week
      last_week_beginning   = (this_week_beginning - 1.week)
      last_week_ending      = (last_week_beginning + 4.days) # the fifth day is the actual beginning of week itself
      this_month_beginning  = today.beginning_of_month
      last_month_beginning  =  today.last_month.beginning_of_month
      last_month_ending = today.last_month.end_of_month

      this_week  = "#{this_week_beginning.strftime("%d-%m")} to #{today.strftime("%d-%m")}"
      last_week  = "#{last_week_beginning.strftime("%d-%m")} to #{last_week_ending.strftime("%d-%m")}"
      this_month = "#{this_month_beginning.strftime("%d-%m")} to #{today.strftime("%d-%m")}"
      last_month = "#{last_month_beginning.strftime("%d-%m")} to #{last_month_ending.strftime("%d-%m")}"

      report_date_ranges["this_week"]   = {"range"      =>["This Week (#{this_week})"],
                                            "datetime"  =>[this_week_beginning.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")]}

      report_date_ranges["last_week"]   = {"range"      =>["Last Week (#{last_week})"],
                                            "datetime"  =>[last_week_beginning.strftime("%Y-%m-%d"), last_week_ending.strftime("%Y-%m-%d")]}

      report_date_ranges["this_month"]  = {"range"      =>["This Month (#{this_month})"],
                                            "datetime"  =>[this_month_beginning.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")]}
      report_date_ranges["last_month"]  = {"range"      =>["Last Month (#{last_month})"],
                                            "datetime"  =>[last_month_beginning.strftime("%Y-%m-%d"), last_month_ending.strftime("%Y-%m-%d")]}

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
          grouping_date_ranges[:date_ranges].push([week_beginning.strftime("%Y-%m-%d"), week_ending.strftime("%Y-%m-%d") + " 23:59:59"])
          current_week    += 1.week
        end while current_week <= final_week

      when "month"
        grouping_date_ranges[:display_text]  = "Month beginning XXXX ending  YYYY"
        final_month   = end_date.beginning_of_month
        current_month = start_date.beginning_of_month

        begin
          month_beginning  = current_month.beginning_of_month
          month_ending     = current_month.end_of_month
          grouping_date_ranges[:date_ranges].push([month_beginning.strftime("%Y-%m-%d"), month_ending.strftime("%Y-%m-%d") + " 23:59:59"])
          current_month    += 1.month
        end while current_month <= final_month
    end

    return grouping_date_ranges
  end

  def self.patient_demographics_query_builder(patient_type, date_range, district_id)
    # Get a list of health centers for the particular district
    health_centers = '"' + get_nearest_health_centers(district_id).map(&:name).join('","') + '"'

    child_maximum_age     = 9 # see definition of a female adult above
    nearest_health_center = PersonAttributeType.find_by_name("NEAREST HEALTH FACILITY").id

    case patient_type.downcase
      when "women"
        pregnancy_status_concept_id         = Concept.find_by_name("PREGNANCY STATUS").concept_id
        pregnancy_status_encounter_type_id  = EncounterType.find_by_name("PREGNANCY STATUS").encounter_type_id
        delivered_status_concept = Concept.find_by_name("Delivered").concept_id
        call_id = Concept.find_by_name("CALL ID").concept_id
        
        extra_parameters = ", CASE pregnancy_status_table.value_coded " +
                           " WHEN #{delivered_status_concept} THEN 'Delivered' " +
                           " ELSE pregnancy_status_table.pregnancy_status " +
                           "END AS pregnancy_status_text "

        extra_conditions = " AND pregnancy_status_table.person_id = p.patient_id " +
                           "AND (YEAR(p.date_created) - YEAR(ps.birthdate)) > #{child_maximum_age} "

        sub_query       = ", (SELECT  o.person_id AS person_id, o.value_coded AS value_coded, " +
                              "c.concept_id, cn.name AS name, o.value_text AS pregnancy_status " +
                              "FROM encounter e " + 
                                "INNER JOIN obs o " + 
                                  "ON e.encounter_id = o.encounter_id AND o.concept_id = #{pregnancy_status_concept_id} " + 
                                "INNER JOIN concept c " + 
                                  "ON c.concept_id = o.concept_id AND c.retired = 0 " + 
                                "INNER JOIN concept_name cn " + 
                                  "ON cn.concept_id = c.concept_id " +
                                "INNER JOIN obs obs_call ON e.encounter_id = obs_call.encounter_id " +
                                  "AND obs_call.concept_id = #{call_id} " +
                                "INNER JOIN call_log cl ON obs_call.value_text = cl.call_log_id " +
                                  "AND cl.district = #{district_id} " +
                            "WHERE e.encounter_type = #{pregnancy_status_encounter_type_id} " +
                              "AND DATE(o.obs_datetime) >= '#{date_range.first}' " +
                              "AND DATE(o.obs_datetime) <= '#{date_range.last}' " +
                              "AND e.voided = 0 " +
                            "GROUP BY person_id " +
                            "ORDER BY o.person_id, o.date_created DESC) pregnancy_status_table "

      extra_group_by = ", pregnancy_status_table.pregnancy_status "

      when "children"
        extra_parameters  = ", ps.gender AS gender "
        extra_conditions  = "AND (YEAR(p.date_created) - YEAR(ps.birthdate)) <= #{child_maximum_age} "
        sub_query         = ""
        extra_group_by    = ", ps.gender "
      else
      extra_parameters  = ", ((YEAR(p.date_created) - YEAR(ps.birthdate)) > #{child_maximum_age}) AS adult "
      extra_conditions  = ""
      sub_query         = ""
      extra_group_by    = ", ps.person_id " #((YEAR(p.date_created) - YEAR(ps.birthdate)) > #{child_maximum_age})"
    end
      patients_with_encounter = " (SELECT DISTINCT e.patient_id " +
                                "FROM patient p " +
                                "  INNER JOIN encounter e ON p.patient_id = e.patient_id " +
                                "WHERE DATE(e.encounter_datetime) >= '#{date_range.first}' " + 
                                "AND DATE(e.encounter_datetime) <= '#{date_range.last}') patients "

    query = "SELECT pa.value AS nearest_health_center, "+
                "COUNT(p.patient_id) AS number_of_patients, " +
                "DATE(p.date_created) AS start_date " + extra_parameters +
            "FROM person_attribute pa LEFT JOIN patient p ON pa.person_id = p.patient_id " +
                "LEFT JOIN person ps ON pa.person_id = ps.person_id " +  
                "INNER JOIN #{patients_with_encounter} ON pa.person_id = patients.patient_id " + sub_query +
            "WHERE pa.person_attribute_type_id = #{nearest_health_center} " + extra_conditions + 
              "AND pa.value IN (#{health_centers}) " +
            "GROUP BY pa.value " + extra_group_by + 
            " ORDER BY p.date_created"

    return query
  end
  
  def self.patient_demographics(patient_type, grouping, start_date, end_date, district)
    
    district_id = District.find_by_name(district).id
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    patients_data = []

    date_ranges.map do |date_range|
      query   = self.patient_demographics_query_builder(patient_type, date_range, district_id)
      
      results = Patient.find_by_sql(query)

      case patient_type.downcase
        when "women"
          new_patients_data = self.women_demographics(results, date_range, district_id)
        when "children"
          new_patients_data = self.children_demographics(results, date_range, district_id)
        else
          new_patients_data = self.all_patients_demographics(results, date_range, district_id)
      end # end case
      patients_data.push(new_patients_data)
    end

    patients_data
  end

  def self.all_patients_demographics(patients_data, date_range, district)
    nearest_health_centers  = []
    
    mnch_health_facilities_list = get_nearest_health_centers(district)
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

  def self.children_demographics(patients_data, date_range, district)
    nearest_health_centers  = []

    mnch_health_facilities_list = get_nearest_health_centers(district)
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

  def self.women_demographics(patients_data, date_range, district)
    nearest_health_centers  = []

    mnch_health_facilities_list = get_nearest_health_centers(district)
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
    miscarried    = 3
    new_patients_data[:pregnancy_status] = [["pregnant", 0], ["non_pregnant", 0], ["delivered", 0], ["miscarried", 0]]

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
            new_patients_data[:pregnancy_status][pregnant][1]     += number_of_patients if(pregnancy_status.to_s.upcase  == "PREGNANT")
            new_patients_data[:pregnancy_status][non_pregnant][1] += number_of_patients if(pregnancy_status.to_s.upcase == "NOT PREGNANT")
            new_patients_data[:pregnancy_status][delivered][1]    += number_of_patients if(pregnancy_status.to_s.upcase == "DELIVERED")
            new_patients_data[:pregnancy_status][miscarried][1]    += number_of_patients if(pregnancy_status.to_s.upcase == "MISCARRIED")
          end
          i += 1
        end
      end
    end
    new_patients_data
  end

  def self.patient_health_issues_query_builder(patient_type, health_task, date_range, essential_params, district_id)
    concept_ids         = essential_params[:concept_ids]
    encounter_type_ids  = essential_params[:encounter_type_ids]
    extra_conditions    = essential_params[:extra_conditions]
    extra_parameters    = essential_params[:extra_parameters]
    #TODO find a better way of getting concpet_names that are not tagged concept_name_tag_map as danger, health_symptom or health info
    concept_names =  '"' + essential_params[:concept_map].inject([]) {|result, concept| result << concept[:concept_name].to_s}.uniq.join('","') + '"'

    value_coded_indicator = Concept.find_by_name("YES").id
    call_id = Concept.find_by_name("CALL ID").id
    
    child_maximum_age = 9
    
    required_tags = ConceptNameTag.find(:all,
                                          :select => "concept_name_tag_id",
                                          :conditions => ["tag IN ('DANGER SIGN', 'HEALTH INFORMATION', 'HEALTH SYMPTOM')"]
                                          ).map(&:concept_name_tag_id).join(', ')

    query = "SELECT encounter_type.name AS encounter_type_name, " +
              "COUNT(obs.person_id) AS number_of_patients," + extra_parameters +
              "obs.concept_id AS concept_id, DATE(encounter.date_created) AS start_date " +
            "FROM obs LEFT JOIN encounter ON encounter.encounter_id = obs.encounter_id " +
              "LEFT JOIN encounter_type on encounter.encounter_type = encounter_type.encounter_type_id " +
              "LEFT JOIN patient ON encounter.patient_id = patient.patient_id " +
              "LEFT JOIN person ON patient.patient_id = person.person_id " +
              "LEFT JOIN concept_name on obs.concept_id = concept_name.concept_id " + 
              "INNER JOIN obs obs_call ON encounter.encounter_id = obs_call.encounter_id " +
                "AND obs_call.concept_id = #{call_id} " +
              "INNER JOIN call_log cl ON obs_call.value_text = cl.call_log_id " +
                "AND cl.district = #{district_id} " +
            "WHERE encounter_type.encounter_type_id IN (#{encounter_type_ids}) " +
              "AND obs.concept_id IN (#{concept_ids}) " +
              "AND encounter.voided = 0 AND obs.voided = 0 AND concept_name.voided = 0 " +
              "AND DATE(obs.date_created) >= '#{date_range.first}' " +
              "AND DATE(obs.date_created) <= '#{date_range.last}' " 
              
    if patient_type.to_s.upcase == "CHILDREN"
      query = query + "AND (YEAR(patient.date_created) - YEAR(person.birthdate)) <= #{child_maximum_age} "
    else
      query = query + "AND (YEAR(patient.date_created) - YEAR(person.birthdate)) > #{child_maximum_age} "
    end
              
    if health_task.to_s.upcase != "OUTCOMES"
      query = query + "AND obs.value_coded = " + value_coded_indicator.to_s 
    end
    
#    query = query + " AND concept_name.concept_name_id = concept_name_tag_map.concept_name_id " 
    
    if health_task.to_s.upcase != "OUTCOMES"
      query = query + " AND concept_name.name IN (#{concept_names}) " #" AND concept_name_tag_map.concept_name_tag_id IN (" + required_tags + ") " 
    end
    
    query = query + " GROUP BY encounter_type.encounter_type_id, " + extra_conditions + "obs.concept_id " +
                    " ORDER BY encounter_type.name, DATE(obs.date_created), obs.concept_id"
#raise query.to_s
    query
  end

  def self.prepopulate_concept_ids_and_extra_parameters(patient_type, health_task)
    if health_task.humanize.downcase == "outcomes"
      concepts_list       = ["OUTCOME","SECONDARY OUTCOME"]
      encounter_type_list = ["UPDATE OUTCOME"]
      outcomes            = ["REFERRED TO A HEALTH CENTRE",
                              "REFERRED TO NEAREST VILLAGE CLINIC",
                              "PATIENT TRIAGED TO NURSE SUPERVISOR",
                              "GIVEN ADVICE NO REFERRAL NEEDED",
                              "HOSPITAL",
                              "REGISTERED FOR TIPS AND REMINDERS"]

      extra_parameters    = " obs.value_text AS concept_name, "
      extra_conditions    = " obs.value_text, DATE(obs.date_created), "
    else
      extra_conditions = " DATE(obs.date_created), "
      extra_parameters = " concept_name.name AS concept_name, "

      if patient_type.downcase == "children"
        encounter_type_list = ["CHILD HEALTH SYMPTOMS"]

        case health_task.humanize.downcase
          when "health symptoms"
            concepts_list = ["FEVER", "DIARRHEA", "COUGH", # feels that this is a danger sign "CONVULSIONS",
                              "NOT EATING","RED EYE", # this is only classified as 'Vomiting Everything' -"VOMITING", 
                              "GAINED OR LOST WEIGHT", "UNCONSCIOUS"] #"VERY SLEEPY" is removed as it is under unconscious

          when "danger warning signs"
            concepts_list = ["FEVER OF 7 DAYS OR MORE",
                              "DIARRHEA FOR 14 DAYS OR MORE",
                              "BLOOD IN STOOL", "COUGH FOR 21 DAYS OR MORE",
                              "CONVULSIONS SIGN", "NOT EATING OR DRINKING ANYTHING",
                              "VOMITING EVERYTHING", #"VISUAL PROBLEMS"
                              "RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS",
                              "VERY SLEEPY OR UNCONSCIOUS", "DRY SKIN",
                              "SWOLLEN HANDS OR FEET SIGN", "VISUAL PROBLEMS"] #"POTENTIAL CHEST INDRAWING"]
#dry skin also known as flaky skin
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
                              "POSTNATAL DISCHARGE BAD SMELL", "ABDOMINAL PAIN",
                              "PROBLEMS WITH MONTHLY PERIODS",
                              "PROBLEMS WITH FAMILY PLANNING METHO", "INFERTILITY",
                              "FREQUENT MISCARRIAGES",
                              "VAGINAL BLEEDING NOT DURING PREGNANCY",
                              "VAGINAL ITCHING","VAGINAL DISCHARGE",
                              "OTHER"
                              ]
                              
          when "danger warning signs"
            concepts_list = ["HEAVY VAGINAL BLEEDING DURING PREGNANCY",
                              "EXCESSIVE POSTNATAL BLEEDING",
                              "FEVER DURING PREGNANCY SIGN",
                              "POSTNATAL FEVER SIGN", "SEVERE HEADACHE",
                              "FITS OR CONVULSIONS SIGN",
                              "SWOLLEN HANDS OR FEET SIGN",
                              "PALENESS OF THE SKIN AND TIREDNESS SIGN",
                              "NO FETAL MOVEMENTS SIGN", "WATER BREAKS SIGN",
                              "ACUTE ABDOMINAL PAIN"
                              ]

          when "health information requested"
            concepts_list = ["HEALTHCARE VISITS", "NUTRITION", "BODY CHANGES",
                              "DISCOMFORT", "CONCERNS", "EMOTIONS",
                              "WARNING SIGNS", "ROUTINES", "BELIEFS",
                              "BABY'S GROWTH", "MILESTONES", "PREVENTION",
                              "FAMILY PLANNING", "BIRTH PLANNING MALE",
                              "BIRTH PLANNING FEMALE","OTHER"]

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
                              "NO FETAL MOVEMENTS SYMPTOM", "WATER BREAKS SYMPTOM",
                              "FEVER", "DIARRHEA", "COUGH", "CONVULSIONS SYMPTOM",
                              "NOT EATING", "VOMITING", "RED EYE",
                              "FAST BREATHING", "VERY SLEEPY", "UNCONSCIOUS",
                              "POSTNATAL DISCHARGE BAD SMELL", "ABDOMINAL PAIN",
                              "PROBLEMS WITH MONTHLY PERIODS",
                              "PROBLEMS WITH FAMILY PLANNING METHO", "INFERTILITY",
                              "FREQUENT MISCARRIAGES",
                              "VAGINAL BLEEDING NOT DURING PREGNANCY",
                              "VAGINAL ITCHING","VAGINAL DISCHARGE",
                              "OTHER"
                              ]
            
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
                              "VERY SLEEPY OR UNCONSCIOUS", "POTENTIAL CHEST INDRAWING",
                               "BIRTH PLANNING MALE",
                              "BIRTH PLANNING FEMALE","OTHER"
                              ]

          when "health information requested"
            concepts_list = ["HEALTHCARE VISITS", "NUTRITION", "BODY CHANGES",
                              "DISCOMFORT", "CONCERNS", "EMOTIONS",
                              "WARNING SIGNS", "ROUTINES", "BELIEFS",
                              "BABY'S GROWTH", "MILESTONES", "PREVENTION",
                              "SLEEPING", "FEEDING PROBLEMS", "CRYING",
                              "BOWEL MOVEMENTS", "SKIN RASHES", "SKIN INFECTIONS",
                              "UMBILICUS INFECTION", "GROWTH MILESTONES",
                              "ACCESSING HEALTHCARE SERVICES", "FAMILY PLANNING",
                              "BIRTH PLANNING MALE",
                              "BIRTH PLANNING FEMALE","OTHER"
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

    return params
  end

  def self.call_count(date_range, patient_type, district_id, count_type = nil)
    call_id = Concept.find_by_name("CALL ID").id
    child_maximum_age = 9
    
    if patient_type.humanize.downcase == "children"
      extra_parameters = "AND (YEAR(o.date_created) - YEAR(p.birthdate)) <= #{child_maximum_age} "
    elsif patient_type.humanize.downcase == "women"
      extra_parameters = "AND (YEAR(o.date_created) - YEAR(p.birthdate)) > #{child_maximum_age} "
    else
      extra_parameters = ""
    end
    
    if count_type.to_s.downcase == 'all'
      select_part = "SELECT o.person_id AS call_count, "
    else
      select_part = "SELECT COUNT(DISTINCT o.person_id) AS call_count, "
    end
    
    query   =  "#{select_part}" +
                  "cn.name AS concept_name, " +
                  "DATE(e.date_created) AS start_date " +
                "FROM encounter e " + 
                  "INNER JOIN obs o ON o.encounter_id = e.encounter_id " + 
                    "AND o.concept_id = #{call_id} " + 
                  "INNER JOIN call_log cl ON cl.call_log_id = o.value_text " + 
                    "AND cl.district = #{district_id} " +  
                  "INNER JOIN person p ON o.person_id = p.person_id " + 
                  "INNER JOIN concept_name cn ON o.concept_id = cn.concept_id " + 
                "WHERE DATE(o.date_created) >= '#{date_range.first}' " +
                  "AND DATE(o.date_created) <= '#{date_range.last}' " + 
                  "AND e.voided = 0 AND o.voided = 0 AND cn.voided = 0 " + 
                  " #{extra_parameters} " +
                "GROUP BY o.concept_id " +
                "ORDER BY DATE(o.date_created), o.concept_id"
 
=begin
    query   =  "#{select_part}" +
                  "concept_name.name AS concept_name, " +
                  "DATE(encounter.date_created) AS start_date " +
                "FROM encounter, encounter_type, obs, concept, concept_name, person " +
                "WHERE concept.concept_id = #{call_id} " +
                  "AND encounter_type.encounter_type_id = encounter.encounter_type " +
                  "AND obs.concept_id = concept_name.concept_id " +
                  "AND obs.person_id = person.person_id " +
                  "AND obs.concept_id = concept.concept_id " +
                  "AND encounter.encounter_id = obs.encounter_id " +
                  "AND DATE(obs.date_created) >= '#{date_range.first}' " +
                  "AND DATE(obs.date_created) <= '#{date_range.last}' " +
                  "AND encounter.voided = 0 AND obs.voided = 0 AND concept_name.voided = 0 " + 
                  " #{extra_parameters}" +
                "GROUP BY obs.concept_id " +
                "ORDER BY encounter_type.name, DATE(obs.date_created), obs.concept_id"
=end

    #raise query.to_s
    Patient.find_by_sql(query)
  end
  
  def self.call_count_for_period(date_range, patient_type, district_id)
    call_id = Concept.find_by_name("CALL ID").id
    child_maximum_age = 9
    
    if patient_type.humanize.downcase == "children"
      extra_parameters = " AND (YEAR(o.date_created) - YEAR(p.birthdate)) <= #{child_maximum_age} "
    elsif patient_type.humanize.downcase == "women"
      extra_parameters = " AND (YEAR(o.date_created) - YEAR(p.birthdate)) > #{child_maximum_age} "
    else
      extra_parameters = ""
    end
    
    query   =  "SELECT distinct o.value_text " +
               "FROM obs o " +
                  "LEFT JOIN person p ON o.person_id = p.person_id " +
                  "INNER JOIN call_log cl ON o.value_text = cl.call_log_id " + 
                    "AND cl.district = #{district_id} " +
               "WHERE o.concept_id = #{call_id} " +
                  "AND DATE(o.date_created) >= '#{date_range.first}' " +
                  "AND DATE(o.date_created) <= '#{date_range.last}' " +
                  "AND o.voided = 0 " + extra_parameters +
               "ORDER BY o.value_text"

#raise query.to_s
=begin    
    query   =  "SELECT distinct obs.value_text " +
               "FROM obs LEFT JOIN person ON obs.person_id = person.person_id " +
               "WHERE obs.concept_id = #{call_id} " +
                  "AND DATE(obs.date_created) >= '#{date_range.first}' " +
                  "AND DATE(obs.date_created) <= '#{date_range.last}' " +
                  "AND obs.voided = 0 " + extra_parameters +
               "ORDER BY obs.value_text"
=end         
    Observation.find_by_sql(query)
    #Patient.find_by_sql(query)
  end
  
  def self.get_callers(date_range, essential_params, patient_type, district_id, task = nil)
    child_maximum_age     = 9 # see definition of a female adult above
    concept_ids = essential_params[:concept_map].inject([]) {|result, concept| result << concept[:concept_id]}.uniq.join(',')
    value_coded_indicator = Concept.find_by_name("YES").id

    call_id = Concept.find_by_name("CALL ID").id

    if patient_type.humanize.downcase == "children"
      extra_parameters = "AND (YEAR(o.date_created) - YEAR(p.birthdate)) <= #{child_maximum_age} "
    elsif patient_type.humanize.downcase == "women"
      extra_parameters = "AND (YEAR(o.date_created) - YEAR(p.birthdate)) > #{child_maximum_age} "
    else
      extra_parameters = ""
    end
    
    query = "SELECT DISTINCT o.person_id " +
            "FROM obs o " +
              "INNER JOIN person p " +
                "ON p.person_id = o.person_id " + 
              "INNER JOIN obs obs_call " +
                "ON o.encounter_id = obs_call.encounter_id " +
                "AND obs_call.concept_id = #{call_id} " +
              "INNER JOIN call_log cl " +
                "ON obs_call.value_text = cl.call_log_id " +
                "AND cl.district = #{district_id} " +
            "WHERE o.concept_id IN (#{concept_ids}) " + extra_parameters +
              "AND DATE(o.date_created) >= '#{date_range.first}' " +
              "AND DATE(o.date_created) <= '#{date_range.last}' " +
              "AND o.voided = 0" 
            
    if task.to_s.upcase != "OUTCOMES"
      query = query + " AND o.value_coded = " + value_coded_indicator.to_s
    end 

    Patient.find_by_sql(query)
    
  end

  def self.patient_health_issues(patient_type, grouping, health_task, start_date, end_date, district)
    district_id = District.find_by_name(district).id
    patients_data = []
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    essential_params  = self.prepopulate_concept_ids_and_extra_parameters(patient_type, health_task)

    date_ranges.map do |date_range|
      query = self.patient_health_issues_query_builder(patient_type, health_task, date_range, essential_params, district_id)
      concept_map           = Marshal.load(Marshal.dump(essential_params[:concept_map]))
      results               = Patient.find_by_sql(query)
      total_call_count      = self.call_count(date_range, patient_type, district_id)
      total_calls_for_period = self.call_count_for_period(date_range, patient_type, district_id)
      total_number_of_calls = total_call_count.first.attributes["call_count"].to_i rescue 0
      total_callers_with_symptoms = self.get_callers(date_range, essential_params, patient_type, district_id, health_task).count

      new_patients_data                 = {}
      new_patients_data[:health_issues] = concept_map
      new_patients_data[:start_date]    = date_range.first
      new_patients_data[:end_date]      = date_range.last
      new_patients_data[:total_calls]   = total_number_of_calls
      new_patients_data[:total_number_of_calls]   = total_callers_with_symptoms
      new_patients_data[:total_number_of_calls_for_period] = total_calls_for_period.count

      symptom_total = results.map(&:number_of_patients).inject(0){|total,n| total = total + n.to_i} # i love ruby :D

      unless results.blank?
        (health_task.humanize.downcase == "outcomes")? outcomes = true : outcomes = false

        results.map do|data|

          concept_name        = data.attributes["concept_name"].to_s.upcase
          concept_id          = data.attributes["concept_id"].to_i
          number_of_patients  = data.attributes["number_of_patients"].to_i
          
          new_patients_data[:health_issues].each_with_index do |health_issue, i|
            update_statistics = false
            if outcomes
              if concept_name.to_s.upcase == "GIVEN ADVICE"
                concept_name = "GIVEN ADVICE NO REFERRAL NEEDED"
              end
              
              if concept_name.to_s.upcase == "NURSE CONSULTATION"
                concept_name = "PATIENT TRIAGED TO NURSE SUPERVISOR"
              end
              
              update_statistics = true if(health_issue[:concept_name].to_s.upcase == concept_name)
            else
              update_statistics = true if(health_issue[:concept_id].to_i == concept_id)
            end
 
            next if !update_statistics

            number_of_patients_so_far  = new_patients_data[:health_issues][i][:call_count]
            number_of_patients_so_far += number_of_patients
            #call_percentage            = ((number_of_patients_so_far * 100.0)/total_callers_with_symptoms).round(1) rescue 0
            call_percentage            = ((number_of_patients_so_far * 100.0)/symptom_total).round(1) rescue 0
            
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

  def self.patient_age_distribution(patient_type, grouping, start_date, end_date, district)
    district_id = District.find_by_name(district).id
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    patients_data = []

    date_ranges.map do |date_range|
      query   = self.patient_demographics_query_builder(patient_type, date_range, district_id)
      results = Patient.find_by_sql(query)

      data_for_patients = {:patient_data => {}, :statistical_data => {}}
      case patient_type.downcase
        when "women"
          new_patients_data = self.women_demographics(results, date_range, district_id)
          statistical_data = Patient.find_by_sql(self.get_age_statistics(patient_type, date_range, district_id))
          patient_statistics = self.create_patient_statistics(patient_type,
                                statistical_data) unless statistical_data.empty?
  
          data_for_patients[:patient_data] = new_patients_data
          data_for_patients[:statistical_data] = patient_statistics rescue ''

        when "children"
          new_patients_data = self.children_demographics(results, date_range, district_id)
          statistical_data = Patient.find_by_sql(self.get_age_statistics(patient_type, date_range, district_id))
          patient_statistics = self.create_patient_statistics(patient_type,
                                statistical_data) unless statistical_data.empty?

          data_for_patients[:patient_data] = new_patients_data
          data_for_patients[:statistical_data] = patient_statistics rescue ''
        else
          new_patients_data = self.all_patients_demographics(results, date_range, district_id)
          
          statistical_data = Patient.find_by_sql(self.get_age_statistics(patient_type, date_range, district_id))
          patient_statistics = self.create_patient_statistics(patient_type,
                                statistical_data) unless statistical_data.empty?

          data_for_patients[:patient_data] = new_patients_data
          data_for_patients[:statistical_data] = patient_statistics rescue ''

      end # end case
      patients_data.push(data_for_patients)
    end
    #raise patients_data.to_yaml
    patients_data
  end

  def self.get_age_statistics(patient_type, date_range, district_id)

    child_maximum_age     = 9 # see definition of a female adult above
    nearest_health_center = PersonAttributeType.find_by_name("NEAREST HEALTH FACILITY").id
    call_id = Concept.find_by_name("CALL ID").concept_id

    case patient_type.downcase
      when "women"
        pregnancy_status_concept_id         = Concept.find_by_name("PREGNANCY STATUS").concept_id
        pregnancy_status_encounter_type_id  = EncounterType.find_by_name("PREGNANCY STATUS").encounter_type_id
        delivered_status_concept = Concept.find_by_name("Delivered").concept_id
        
        extra_parameters = "SELECT (YEAR(p.date_created) - YEAR(ps.birthdate)) AS Age,
                            pregnancy_status_table.pregnancy_status AS pregnancy_status_text "

        extra_conditions = " AND pregnancy_status_table.person_id = p.patient_id " +
                           "AND (YEAR(p.date_created) - YEAR(ps.birthdate)) > #{child_maximum_age} "

        sub_query       = ", (SELECT  o.person_id AS person_id, c.concept_id, cn.name AS name, " +
                              "CASE o.value_coded " +
                              " WHEN #{delivered_status_concept} THEN 'Delivered' " +
                              " ELSE o.value_text " +
                              "END AS pregnancy_status " +
                              "FROM encounter e " + 
                                "INNER JOIN obs o " + 
                                  "ON e.encounter_id = o.encounter_id AND o.concept_id = #{pregnancy_status_concept_id} " + 
                                "INNER JOIN concept c " + 
                                  "ON c.concept_id = o.concept_id AND c.retired = 0 " + 
                                "INNER JOIN concept_name cn " + 
                                  "ON cn.concept_id = c.concept_id " +
                                "INNER JOIN obs obs_call ON e.encounter_id = obs_call.encounter_id " +
                                  "AND obs_call.concept_id = #{call_id} " +
                                "INNER JOIN call_log cl ON obs_call.value_text = cl.call_log_id " +
                                  "AND cl.district = #{district_id} " +
                            "WHERE e.encounter_type = #{pregnancy_status_encounter_type_id} " +
                              "AND DATE(o.obs_datetime) >= '#{date_range.first}' " +
                              "AND DATE(o.obs_datetime) <= '#{date_range.last}' " +
                              "AND e.voided = 0 " +
                            "GROUP BY person_id " +
                            "ORDER BY o.person_id) pregnancy_status_table "

      extra_group_by = ", pregnancy_status_table.pregnancy_status "

      when "children"
        extra_parameters  = "SELECT PERIOD_DIFF(CONCAT(YEAR(p.date_created), 
                              IF(MONTH(p.date_created)<10,'0',''),
                              MONTH(p.date_created)),
                              CONCAT(YEAR(ps.birthdate), 
                              IF(MONTH(ps.birthdate)<10,'0',''), 
                              MONTH(ps.birthdate))) AS Age, ps.gender AS gender " 
        extra_conditions  = "AND (YEAR(p.date_created) - YEAR(ps.birthdate)) <= #{child_maximum_age} "
        sub_query         = ""
        extra_group_by    = ", ps.gender "
      else
      extra_parameters  = "SELECT PERIOD_DIFF(CONCAT(YEAR(p.date_created), 
                              IF(MONTH(p.date_created)<10,'0',''), 
                              MONTH(p.date_created)), 
                              CONCAT(YEAR(ps.birthdate), 
                              IF(MONTH(ps.birthdate)<10,'0',''), 
                              MONTH(ps.birthdate))) AS age_in_months, 
                          (YEAR(p.date_created) - YEAR(ps.birthdate)) as age_in_years, 
                          ((YEAR(p.date_created) - YEAR(ps.birthdate)) > #{child_maximum_age}) AS adult " 
      extra_conditions  = "" 
      sub_query         = "" 
      extra_group_by    = ",((YEAR(p.date_created) - YEAR(ps.birthdate)) > #{child_maximum_age}) " 
      
    end
          patients_with_encounter = " (SELECT DISTINCT e.patient_id " +
                                "FROM patient p " +
                                "  INNER JOIN encounter e ON p.patient_id = e.patient_id " +
                                "  INNER JOIN obs obs_call on e.encounter_id = obs_call.encounter_id " + 
                                "     AND obs_call.concept_id = #{call_id} " +
                                "  INNER JOIN call_log cl ON obs_call.value_text = cl.call_log_id " +
                                  "AND cl.district = #{district_id} " +
                                "WHERE DATE(e.encounter_datetime) >= '#{date_range.first}' " + 
                                "AND DATE(e.encounter_datetime) <= '#{date_range.last}') patients "
    

    query = extra_parameters +
          "FROM person_attribute pa LEFT JOIN patient p ON pa.person_id = p.patient_id " +
                      "LEFT JOIN person ps ON pa.person_id = ps.person_id " +  
                      "INNER JOIN #{patients_with_encounter} ON pa.person_id = patients.patient_id " + sub_query +
                  "WHERE pa.person_attribute_type_id = #{nearest_health_center} " + extra_conditions + 
                  "GROUP BY pa.value, ps.person_id" + extra_group_by +
                  " ORDER BY p.date_created"
          
    return query
  end

  def self.create_patient_statistics(patient_type, patient_data)

    case patient_type.downcase
      when 'women'
        women_grouping = {:pregnant => {}, :nonpregnant => {},
                          :delivered => {}, :miscarried => {}
        }
        pregnant_data = []
        nonpregnant_data = []
        delivered_data = []
        miscarried_data = []

        unless patient_data.empty?
          patient_data.each do |value|
            case value[:pregnancy_status_text].downcase
            when 'pregnant'
              pregnant_data << value[:Age].to_i 
            when 'not pregnant'
              nonpregnant_data << value[:Age].to_i
            when 'delivered'
              delivered_data << value[:Age].to_i
            when 'miscarried'
              miscarried_data << value[:Age].to_i
            end
          end
        end

      unless pregnant_data.empty?
          pregnant_statistics = {:total => pregnant_data.count, :percentage => 0,
                         :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          pregnant_statistics[:min] = pregnant_data.min
          pregnant_statistics[:max] = pregnant_data.max
          pregnant_statistics[:percentage] = (pregnant_data.count.to_f / patient_data.count.to_f * 100).round(1)
          pregnant_statistics[:average] = self.calculate_average(pregnant_data.flatten)
          pregnant_statistics[:sdev] = self.calculate_sdev(pregnant_data)

          women_grouping[:pregnant][:statistical_info] = pregnant_statistics
        end

        unless nonpregnant_data.empty?
          nonpregnant_statistics = {:total => nonpregnant_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          nonpregnant_statistics[:min] = nonpregnant_data.min
          nonpregnant_statistics[:max] = nonpregnant_data.max
          nonpregnant_statistics[:percentage] = (nonpregnant_data.count.to_f / patient_data.count.to_f * 100).round(1)
          nonpregnant_statistics[:average] = self.calculate_average(nonpregnant_data)
          nonpregnant_statistics[:sdev] = self.calculate_sdev(nonpregnant_data)

          women_grouping[:nonpregnant][:statistical_info] = nonpregnant_statistics

        end
        unless delivered_data.empty?
          delivered = {:total => delivered_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          delivered[:min] = delivered_data.min
          delivered[:max] = delivered_data.max
          delivered[:percentage] = (delivered_data.count.to_f / patient_data.count.to_f * 100).round(1)
          delivered[:average] = self.calculate_average(delivered_data)
          delivered[:sdev] = self.calculate_sdev(delivered_data)

          women_grouping[:delivered][:statistical_info] = delivered
        end
        unless miscarried_data.empty?
          miscarried = {:total => miscarried_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          miscarried[:min] = miscarried_data.min
          miscarried[:max] = miscarried_data.max
          miscarried[:percentage] = (miscarried_data.count.to_f / patient_data.count.to_f * 100).round(1)
          miscarried[:average] = self.calculate_average(miscarried_data)
          miscarried[:sdev] = self.calculate_sdev(miscarried_data)

          women_grouping[:miscarried][:statistical_info] = miscarried
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
          female_statistics = {:total => female_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          female_statistics[:min] = female_data.min
          female_statistics[:max] = female_data.max
          female_statistics[:percentage] = (female_data.count.to_f / patient_data.count.to_f * 100).round(1)
          female_statistics[:average] = self.calculate_average(female_data)
          female_statistics[:sdev] = self.calculate_sdev(female_data)

          child_grouping[:female][:statistical_info] = female_statistics
        end

        unless male_data.empty?
          male_statistics = {:total => male_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          male_statistics[:min] = male_data.min
          male_statistics[:max] = male_data.max
          male_statistics[:percentage] = (male_data.count.to_f / patient_data.count.to_f  * 100).round(1)
          male_statistics[:average] = self.calculate_average(male_data)
          male_statistics[:sdev] = self.calculate_sdev(male_data)

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
          child_statistics = {:total => child_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          child_statistics[:min] = child_data.min
          child_statistics[:max] = child_data.max
          child_statistics[:percentage] = (child_data.count.to_f / patient_data.count.to_f  * 100).round(1)
          child_statistics[:average] = self.calculate_average(child_data)
          child_statistics[:sdev] = self.calculate_sdev(child_data)

          all_grouping[:child][:statistical_info] = child_statistics
        end

        unless women_data.empty?
          women_statistics = {:total => women_data.count, :percentage => 0,
                        :average => 0, :min => 0, :max => 0, :sdev => 0
                       }
          women_statistics[:min] = women_data.min
          women_statistics[:max] = women_data.max
          women_statistics[:percentage] = (women_data.count.to_f / patient_data.count.to_f  * 100).round(1)
          women_statistics[:average] = self.calculate_average(women_data)
          women_statistics[:sdev] = self.calculate_sdev(women_data)

          all_grouping[:women][:statistical_info] = women_statistics
        end

      return_data = all_grouping

    end

    return return_data
  end

 def self.calculate_average(data)
   return  (data.inject{ |sum, el| sum + el }.to_f / data.size).round(1)
 end

 def self.calculate_sdev(data)
  return 0 if data.size == 1

   mean = data.sum / data.length
   new_data = []

   data.each do |el|
      new_data << ((el - mean) * (el - mean))
   end

   sdev = Math.sqrt(new_data.sum / (new_data.count - 1)).round(1)

   return sdev
 end

 def self.patient_activity(patient_type, grouping, start_date, end_date, district)
  district_id = District.find_by_name(district).id
  patients_data = []
  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      
      query   = self.patient_demographics_query_builder(patient_type, date_range, district_id)
      results = Patient.find_by_sql(query)
      total_calls_for_period = self.call_count_for_period(date_range, patient_type, district_id)
      #data_for_patients = {:patient_data => {}, :statistical_data => {}}
      patient_statistics = {:start_date => date_range.first, 
                            :end_date => date_range.last, :total => 0,
                            :total_calls_for_period => total_calls_for_period.count,
                            :symptoms => 0, :symptoms_pct => 0,
                            :danger => 0, :danger_pct => 0,
                            :info => 0, :info_pct => 0
      }
      activity_type = ["symptoms","danger","info"]
      case patient_type.downcase
        when "women"
          new_patients_data = self.women_demographics(results, date_range, district_id)
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
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params, district_id)
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
          new_patients_data = self.children_demographics(results, date_range, district_id)     
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
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params, district_id)
            #raise data_query.to_s
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
          new_patients_data = self.all_patients_demographics(results, date_range, district_id)
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
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params, district_id)
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

 def self.patient_activity_query_builder(patient_type, health_task, date_range, essential_params, district_id)
    call_id = Concept.find_by_name("CALL ID").id
    concept_ids         = essential_params[:concept_ids]
    encounter_type_ids  = essential_params[:encounter_type_ids]
    #extra_conditions    = essential_params[:extra_conditions]
    #extra_parameters    = essential_params[:extra_parameters]
    
    value_coded_indicator = Concept.find_by_name("YES").id
=begin
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
=end
    query = "SELECT COUNT(DISTINCT o.person_id) AS number_of_patients "  +
            "FROM encounter e " +
              "INNER JOIN obs o ON e.encounter_id = o.encounter_id " + 
              "INNER JOIN obs obs_call ON o.encounter_id = obs_call.encounter_id " +
                "AND obs_call.concept_id = #{call_id} " +
              "INNER JOIN call_log cl ON obs_call.value_text = cl.call_log_id " +
                "AND cl.district = #{district_id} " +
            "WHERE e.encounter_type IN (#{encounter_type_ids}) " +
              "AND o.concept_id IN (#{concept_ids}) " +
              "AND DATE(o.date_created) >= '#{date_range.first}' " +
              "AND DATE(o.date_created) <= '#{date_range.last}' " +
              "AND e.voided = 0 AND o.voided = 0 " +
              "AND o.value_coded = " + value_coded_indicator.to_s 

    #raise query.to_s
    query
  end

 def self.patient_referral_followup(patient_type, grouping, outcome, start_date, end_date, district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id
    patient_data = []
    youth_age = 9
    
    other_outcomes = ["GIVEN ADVICE NO REFERRAL NEEDED","GIVEN ADVICE"]
   if outcome == "GIVEN ADVICE NO REFERRAL NEEDED"
     outcome = other_outcomes
   end
   #raise outcome.to_yaml
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                        end_date)[:date_ranges]

    date_ranges.map do |date_range|
      patient_info = []
      patient_data_elements = {:date_range => [], :patient_info => []}

      if patient_type.downcase == "women"
        condition_options = ["encounter_type = ?
                              AND encounter_datetime >= ?
                              AND encounter_datetime <= ?
                              AND obs.concept_id = ?
                              AND obs.value_text IN (?)
                              AND (YEAR(encounter.encounter_datetime) - YEAR(person.birthdate)) > ?",
                      EncounterType.find_by_name("Update Outcome").id,
                      date_range.first, date_range.last,
                      Concept.find_by_name("Outcome").id,
                      outcome, youth_age]
      elsif patient_type.downcase == 'children'
        condition_options = ["encounter_type = ?
                              AND encounter_datetime >= ?
                              AND encounter_datetime <= ?
                              AND obs.concept_id = ?
                              AND obs.value_text IN (?)
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
                              AND obs.value_text IN (?)",
                      EncounterType.find_by_name("Update Outcome").id,
                      date_range.first, date_range.last,
                      Concept.find_by_name("Outcome").id,
                      outcome]

      end
      
      o_encounters = Encounter.find(:all,
                   :joins =>"INNER JOIN obs ON encounter.encounter_id = obs.encounter_id
                             INNER JOIN person ON patient_id = person.person_id
                             INNER JOIN obs obs_call ON obs_call.encounter_id = obs.encounter_id
                              AND obs_call.concept_id = #{call_id}
                              INNER JOIN call_log cl ON obs_call.value_text = cl.call_log_id 
                                AND cl.district = #{district_id}" ,
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


   encounter_type_list = ["MATERNAL HEALTH SYMPTOMS",
                           "CHILD HEALTH SYMPTOMS"]
   encounter_types = self.get_encounter_types(encounter_type_list)

   patient_encounters = Encounter.find(:all,
                   :conditions =>["encounter_type IN (?)
                                  AND encounter_datetime like ?
                                  AND patient_id = ?",
                                  encounter_types, "#{encounter_date}%", patient_id
                  ])
   return_string = ""
   patient_encounters.each do |a_encounter|
     return_string = return_string + " " + a_encounter.to_s
   end
   return return_string
 end

 def self.call_day_distribution(patient_type, grouping, call_type, call_status,
                                     staff_member, start_date, end_date, district)
  district_id = District.find_by_name(district).id
  call_data = []

  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]

    date_ranges.map do |date_range|

      query   = self.call_analysis_query_builder(patient_type,
                      date_range, staff_member, call_type, call_status, district_id)

      results = CallLog.find_by_sql(query)

      # create row template
      call_statistics = {:start_date => date_range.first,
                          :end_date => date_range.last, :total => results.count,
                          :monday => 0, :monday_pct => 0,
                          :tuesday => 0, :tuesday_pct => 0,
                          :wednesday => 0, :wednesday_pct => 0,
                          :thursday => 0, :thursday_pct => 0,
                          :friday => 0, :friday_pct=> 0,
                          :saturday => 0, :saturday_pct => 0,
                          :sunday => 0, :sunday_pct=> 0
                           }

      results.group_by(&:day_of_week).each do |day, data|
        call_statistics[:"#{day.downcase}"] = data.count
        call_statistics[:"#{day.downcase}_pct"] = (call_statistics[:"#{day.downcase}"].to_f / results.count.to_f * 100).round(1) if call_statistics[:"#{day.downcase}"] != 0
      end

      call_data << call_statistics

    end #end of period loop

   return call_data
 end

 def self.call_analysis_query_builder(patient_type, date_range, staff_id, call_type, call_status, district_id)
   
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
     extra_conditions += " AND call_log.creator = '#{staff_id.to_i}' "
   else
     extra_grouping += ", users.username"
   end

   if call_type != 'All'
     case call_type.downcase
     when 'normal'
       call_type_code = 0
       extra_conditions += " AND obs.concept_id = #{call_concept_id} AND obs.voided = 0"
     when 'emergency'
       call_type_code = 1
     when 'irrelevant'
       call_type_code = 2
     when 'dropped'
       call_type_code = 3 
     end
     extra_conditions += " AND call_log.call_type = '#{call_type_code}' "
   end

=begin
   if call_status = 'All'
   elsif call_status = 'Yes'
     extra_conditions +=
   else
   
   end
=end
   
   query = "SELECT TIME(call_log.start_time) AS call_start_time, " +
              "TIME(call_log.end_time) AS call_end_time, " +
              "users.username, DATE_FORMAT(start_time,'%W') AS day_of_week, " +
              "TIMESTAMPDIFF(SECOND, call_log.start_time, call_log.end_time) AS call_length_seconds, " +
              "TIMESTAMPDIFF(MINUTE, call_log.start_time, call_log.end_time) AS call_length_minutes " +
           "FROM call_log " +
              "LEFT JOIN obs ON obs.value_text = call_log.call_log_id " +
              "LEFT JOIN person ON person.person_id = obs.person_id " +
              "LEFT JOIN users ON users.user_id = obs.creator " +
              "LEFT JOIN patient ON patient.patient_id = person.person_id " +
           "WHERE DATE(call_log.start_time) >= '#{date_range.first}' " +
              "AND DATE(call_log.start_time) <= '#{date_range.last}' " +
              "AND call_log.district = '#{district_id}' " +
               extra_conditions +
           " GROUP BY call_log.call_log_id" + extra_grouping

   #raise query.to_s
   return query
  end

 def self.call_time_of_day(patient_type, grouping, call_type, call_status,
                                     staff_member, start_date, end_date, district)
  district_id = District.find_by_name(district).id
  call_data = []
  norm_date = Date.today

  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]

    date_ranges.map do |date_range|

      query   = self.call_analysis_query_builder(patient_type,
                      date_range, staff_member, call_type, call_status, district_id)

      results = CallLog.find_by_sql(query)

      call_statistics = { :start_date => date_range.first,
                          :end_date => date_range.last, :total => results.count,
                          :morning => 0, :morning_pct => 0,
                          :midday => 0, :midday_pct => 0,
                          :afternoon => 0, :afternoon_pct => 0,
                          :evening => 0, :evening_pct => 0
                           }

     results.each do |call|

       if Time.parse("#{call.call_start_time}") >= Time.parse("07:00:00") && 
          Time.parse("#{call.call_start_time}") <= Time.parse("10:00:00")
         call_statistics[:morning] += 1
       elsif Time.parse("#{call.call_start_time}") > Time.parse("10:00:00") && 
             Time.parse("#{call.call_start_time}") <= Time.parse("13:00:00")
         call_statistics[:midday] += 1
       elsif Time.parse("#{call.call_start_time}") > Time.parse("13:00:00") && 
             Time.parse("#{call.call_start_time}") <= Time.parse("16:00:00")
         call_statistics[:afternoon] += 1
       elsif Time.parse("#{call.call_start_time}") > Time.parse("16:00:00") && 
             Time.parse("#{call.call_start_time}") <= Time.parse("19:00:00")
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

  def self.call_lengths(patient_type, grouping, call_type, call_status,
                     staff_member, start_date, end_date, district)
  district_id = District.find_by_name(district).id
  call_data = []
  norm_date = Date.today

  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]

    date_ranges.map do |date_range|

      query   = self.call_analysis_query_builder(patient_type,
                      date_range, staff_member, call_type, call_status, district_id)
#raise query.to_s 
      results = CallLog.find_by_sql(query)

      call_statistics = {
      :start_date => date_range.first,
      :end_date => date_range.last, :total => results.count,
      :morning => 0, :m_len => [], :m_avg => 0, :m_sdev => 0, :m_min => 0,
      :midday => 0, :mid_len => [], :mid_avg => 0, :mid_sdev => 0, :mid_min => 0,
      :afternoon => 0, :a_len => [], :a_avg => 0, :a_sdev => 0, :a_min => 0,
      :evening => 0, :e_len => [], :e_avg => 0, :e_sdev => 0, :e_min => 0
                         }
                          
     results.each do |call|
      date_comp = "#{norm_date} #{call.call_start_time}"

       if Time.parse("#{call.call_start_time}") >= Time.parse("07:00:00") &&
          Time.parse("#{call.call_start_time}") <= Time.parse("10:00:00")
         call_statistics[:morning] += 1
         call_statistics[:m_len] << call.call_length_seconds.to_i
       elsif Time.parse("#{call.call_start_time}") > Time.parse("10:00:00") &&
             Time.parse("#{call.call_start_time}") <= Time.parse("13:00:00")
         call_statistics[:midday] += 1
         call_statistics[:mid_len] << call.call_length_seconds.to_i
       elsif Time.parse("#{call.call_start_time}") > Time.parse("13:00:00") &&
             Time.parse("#{call.call_start_time}") <= Time.parse("16:00:00")
         call_statistics[:afternoon] += 1
         call_statistics[:a_len] << call.call_length_seconds.to_i
       elsif Time.parse("#{call.call_start_time}") > Time.parse("16:00:00") &&
             Time.parse("#{call.call_start_time}") <= Time.parse("19:00:00")
         call_statistics[:evening] += 1
         call_statistics[:e_len] << call.call_length_seconds.to_i
       end
     end #end of results loop

     unless call_statistics[:m_len].empty?
      call_statistics[:m_avg] = self.calculate_average(call_statistics[:m_len])
      call_statistics[:m_sdev] = self.calculate_sdev(call_statistics[:m_len])
      call_statistics[:m_min] = call_statistics[:m_len].min
     end

      unless call_statistics[:mid_len].empty?
      call_statistics[:mid_avg] = self.calculate_average(call_statistics[:mid_len])
      call_statistics[:mid_sdev] = self.calculate_sdev(call_statistics[:mid_len])
      call_statistics[:mid_min] = call_statistics[:mid_len].min
     end

     unless call_statistics[:a_len].empty?
      call_statistics[:a_avg] = self.calculate_average(call_statistics[:a_len])
      call_statistics[:a_sdev] = self.calculate_sdev(call_statistics[:a_len])
      call_statistics[:a_min] = call_statistics[:a_len].min
     end

     unless call_statistics[:e_len].empty?
      call_statistics[:e_avg] = self.calculate_average(call_statistics[:e_len])
      call_statistics[:e_sdev] = self.calculate_sdev(call_statistics[:e_len])
      call_statistics[:e_min] = call_statistics[:e_len].min
     end

     call_data << call_statistics

    end #end of period loop

   return call_data
 end
 def self.tips_activity(start_date, end_date, grouping, content_type, language,
                        phone_type, delivery, number_prefix, district)
 
 district_id = District.find_by_name(district).id
 call_data = []
 
 # main obs conceps
 content_concept = Concept.find_by_name('TYPE OF MESSAGE CONTENT').id
 language_concept = Concept.find_by_name('LANGUAGE PREFERENCE').id
 delivery_concept = Concept.find_by_name('TYPE OF MESSAGE').id
 #data elements concepts
 pregnancy_concept = Concept.find_by_name('pregnancy').id
 child_concept = Concept.find_by_name('child').id
 yao_concept = Concept.find_by_name('chiyao').id
 chewa_concept = Concept.find_by_name('chichewa').id
 sms_concept = Concept.find_by_name('sms').id
 voice_concept = Concept.find_by_name('voice').id


 date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]
  date_ranges.map do |date_range|
   encounters = self.get_tips_data(date_range, district_id)
   total_calls = self.get_total_tips_calls(date_range, district_id)

   row_data = {:start_date => date_range.first,:end_date => date_range.last,
              :total => total_calls,
              :pregnancy => 0, :pregnancy_pct => 0,:child => 0,:child_pct => 0,
              :yao => 0, :yao_pct => 0, :chewa => 0, :chewa_pct => 0,
              :sms => 0, :sms_pct => 0, :voice => 0, :voice_pct => 0
            }

   encounters.each do |encounter|
     encounter.observations.each do |observation|
       if observation.concept_id == content_concept then
         row_data[:pregnancy] += 1 if observation.value_coded == pregnancy_concept
         row_data[:child] += 1 if observation.value_coded == child_concept
       elsif observation.concept_id == language_concept
         row_data[:yao] += 1 if observation.value_coded == yao_concept
         row_data[:chewa] += 1 if observation.value_coded == chewa_concept
       elsif observation.concept_id == delivery_concept then
         row_data[:sms] += 1 if observation.value_coded == sms_concept
         row_data[:voice] += 1 if observation.value_coded == voice_concept
       end
     end
   end
   #calculate percentages
   #changed the denominator to be the total number of calls
   row_data[:pregnancy_pct] = (row_data[:pregnancy].to_f / total_calls.to_f * 100).round(1) if row_data[:pregnancy] != 0
   row_data[:child_pct] = (row_data[:child].to_f / total_calls.to_f * 100).round(1) rescue 0 if row_data[:child] != 0 
   row_data[:yao_pct] = (row_data[:yao].to_f / total_calls.to_f * 100).round(1) if row_data[:yao] != 0
   row_data[:chewa_pct] = (row_data[:chewa].to_f / total_calls.to_f * 100).round(1) rescue 0 if row_data[:chewa] != 0
   row_data[:sms_pct] = (row_data[:sms].to_f / total_calls.to_f * 100).round(1) if row_data[:sms] != 0
   row_data[:voice_pct] = (row_data[:voice].to_f / total_calls.to_f * 100).round(1) rescue 0 if row_data[:voice] != 0
   #add to the call_data array

   call_data << row_data
  end
 
  return call_data
 end

 def self.get_tips_data(date_range, district_id)

  call_id = Concept.find_by_name("CALL ID").id
  encounter_type_list = ["TIPS AND REMINDERS"]
  encounter_types = self.get_encounter_types(encounter_type_list)
  encounters_list = Encounter.find(:all,
                                   :joins => "INNER JOIN obs ON encounter.encounter_id = obs.encounter_id
                                                AND obs.concept_id = #{call_id}
                                              INNER JOIN call_log ON obs.value_text = call_log.call_log_id
                                                AND call_log.district = #{district_id}",
                                   :conditions => ["encounter_type IN (?) AND
                                                    encounter_datetime >= ? AND
                                                    encounter_datetime <= ? AND
                                                    encounter.voided = ?",
                                                   encounter_types,
                                                   date_range.first,
                                                   date_range.last, 0],
                                  :include => 'observations')

  return encounters_list

 end

 def self.get_total_tips_calls(date_range, district_id)

  encounter_type_list = ["TIPS AND REMINDERS"]
  encounter_types = self.get_encounter_types(encounter_type_list)
  call_id = Concept.find_by_name("CALL ID").id

   query = "SELECT COUNT(DISTINCT obs.value_text) AS count " +
            "FROM encounter " +
              "INNER JOIN obs " +
                "ON encounter.encounter_id = obs.encounter_id " +
                  "AND obs.concept_id = #{call_id} " + 
              "INNER JOIN call_log cl " +
                "ON obs.value_text = cl.call_log_id " + 
                  "AND cl.district = #{district_id} " + 
            "WHERE encounter.encounter_type IN (#{encounter_types}) " +
              "AND DATE(encounter.date_created) >= '#{date_range.first}' " +
              "AND DATE(encounter.date_created) <= '#{date_range.last}' " +
              "AND encounter.voided = 0"

    total_calls = Patient.find_by_sql(query).first.count
    
    if total_calls.blank?
      return 0
    else
      return total_calls.to_i 
    end
 end

 def self.get_tips_data_by_catchment_area(date_range, district_id)

  health_centers = '"' + get_nearest_health_centers(district_id).map(&:name).join('","') + '"'
  nearest_health_center = PersonAttributeType.find_by_name("NEAREST HEALTH FACILITY").id
  encounter_type_list = ["TIPS AND REMINDERS"]
  encounter_types = self.get_encounter_types(encounter_type_list)
  call_id = Concept.find_by_name("CALL ID").id

   query = "SELECT pa.value AS catchment, o.* " +
           "FROM obs o " +
              "INNER JOIN encounter e " +
                "ON e.encounter_id = o.encounter_id AND o.concept_id = #{call_id} " +
              "INNER JOIN call_log cl " +
                "ON o.value_text = cl.call_log_id " + 
                  "AND cl.district = #{district_id} " + 
              "LEFT JOIN person_attribute pa " +
                "ON e.patient_id = pa.person_id " +
            "WHERE pa.person_attribute_type_id = #{nearest_health_center} AND " +
                  "e.encounter_datetime >= '#{date_range.first}' AND " +
                  "e.encounter_datetime <= '#{date_range.last}' AND " +
                  "e.encounter_type IN (#{encounter_types}) AND " + 
                  "e.voided = 0 AND o.voided = 0 AND pa.value IN (#{health_centers}) " 
=begin
  encounters_list = Encounter.find(:all,
                                   :joins => "LEFT JOIN person_attribute ON person_attribute.person_id = encounter.patient_id",
                                   :conditions => ["encounter.encounter_type IN (?) AND
                                                    encounter.encounter_datetime >= ? AND
                                                    encounter.encounter_datetime <= ? AND
                                                    person_attribute.person_attribute_type_id = ?",
                                                   encounter_types,
                                                   date_range.first,
                                                   date_range.last,
                                                   nearest_health_center],
                                   :include => 'observations')
=end

  data_list = Encounter.find_by_sql(query)
  #raise data_list.to_yaml
  return data_list
 end

 def self.get_encounter_types(type_names)
   encounter_types = EncounterType.find(:all,
                                 :conditions =>["name IN (?)",
                                   type_names]).map(&:encounter_type_id)

   return encounter_types
 end
=begin

   result = CallLog.select("user.username,
                            cl.start_time.strftime('%A') as day_of_week,
                            cl.start_time as call_start_time,
                            cl.end_time as call_end_time")
   
=end

 def self.current_enrollment_totals(start_date, end_date, grouping, content_type, language,
                        delivery, number_prefix, district)
   district_id = District.find_by_name(district).id
   call_data = []

   # main obs conceps
   content_concept = Concept.find_by_name('TYPE OF MESSAGE CONTENT').id
   language_concept = Concept.find_by_name('LANGUAGE PREFERENCE').id
   delivery_concept = Concept.find_by_name('TYPE OF MESSAGE').id
   #data elements concepts
   pregnancy_concept = Concept.find_by_name('pregnancy').id
   child_concept = Concept.find_by_name('child').id
   yao_concept = Concept.find_by_name('chiyao').id
   chewa_concept = Concept.find_by_name('chichewa').id
   sms_concept = Concept.find_by_name('sms').id
   voice_concept = Concept.find_by_name('voice').id
   wcba_concept = Concept.find_by_name('WCBA').id

   date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]

   @date_ranges = date_ranges.reverse
    period_data = []
   count = 0
   date_ranges.map do |date_range|
     period_data = []
     period_total_callers = 0
     count += 1
     #encounters_count = self.get_total_tips_encounters(date_range)
     encounters = self.get_tips_data_by_catchment_area(date_range, district_id)

     encounters.group_by(&:catchment).each do |area, data|
     
     encounters_count = data.group_by(&:person_id).count
     
     period_total_callers += encounters_count.to_i
     
     row_data = {:start_date => date_range.first,:end_date => date_range.last,
               :catchment => area, :total_for_period => 0,
               :total => encounters_count,
               :pregnancy => 0, :pregnancy_pct => 0,:child => 0,:child_pct => 0,
               :wcba => 0, :wcba_pct => 0,
               :yao => 0, :yao_pct => 0, :chewa => 0, :chewa_pct => 0,
               :sms => 0, :sms_pct => 0, :voice => 0, :voice_pct => 0
            }

    data.each do |observation|
      if observation.concept_id.to_i == content_concept then
         row_data[:pregnancy] += 1 if observation.value_coded.to_i == pregnancy_concept
         row_data[:child] += 1 if observation.value_coded.to_i == child_concept
         row_data[:wcba] += 1 if observation.value_coded.to_i == wcba_concept
       elsif observation.concept_id.to_i == language_concept
         row_data[:yao] += 1 if observation.value_coded.to_i == yao_concept
         row_data[:chewa] += 1 if observation.value_coded.to_i == chewa_concept
       elsif observation.concept_id.to_i == delivery_concept then
         row_data[:sms] += 1 if observation.value_coded.to_i == sms_concept
         row_data[:voice] += 1 if observation.value_coded.to_i == voice_concept
       end
    end
      #calculate percentages
     row_data[:pregnancy_pct] = (row_data[:pregnancy].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:pregnancy] != 0
     row_data[:child_pct] = (row_data[:child].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:child] != 0
     row_data[:wcba_pct] = (row_data[:wcba].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:wcba] != 0
     row_data[:yao_pct] = (row_data[:yao].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:yao] != 0
     row_data[:chewa_pct] = (row_data[:chewa].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:chewa] != 0
     row_data[:sms_pct] = (row_data[:sms].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:sms] != 0
     row_data[:voice_pct] = (row_data[:voice].to_f / encounters_count.to_f * 100).round(1) rescue 0 if row_data[:voice] != 0
     
     #add to the call_data array   
     period_data << row_data

   end
=begin
   #append total_callers for the month to the rows
   period_data.each do |row|
        row[:total_for_period] = period_total_callers
   end
=end
   call_data << period_data
  end

  return call_data
 end

 def self.individual_current_enrollments(start_date, end_date, grouping, content_type, language,
                        phone_type, delivery, number_prefix, district)
 district_id = District.find_by_name(district).id
 call_data = []

   # main obs concepts
   content_concept = Concept.find_by_name('TYPE OF MESSAGE CONTENT').id
   language_concept = Concept.find_by_name('LANGUAGE PREFERENCE').id
   delivery_concept = Concept.find_by_name('TYPE OF MESSAGE').id
   phone_type_concept = Concept.find_by_name('PHONE TYPE').id
   phone_number_concept = Concept.find_by_name('PHONE NUMBER').id
   on_tips_concept = Concept.find_by_name('ON TIPS AND REMINDERS PROGRAM').id
   #data elements concepts
   pregnancy_concept = Concept.find_by_name('pregnancy').id
   child_concept = Concept.find_by_name('child').id
   yao_concept = Concept.find_by_name('chiyao').id
   chewa_concept = Concept.find_by_name('chichewa').id
   sms_concept = Concept.find_by_name('sms').id
   voice_concept = Concept.find_by_name('voice').id

   if grouping == "None"
     date_ranges = [[start_date, (end_date + " 23:59:59")]]
   else
     date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date,
                                                      end_date)[:date_ranges]
   end
   
   period_data = []

   date_ranges.map do |date_range|

     period_data = []
     encounters_count = self.get_total_tips_encounters(date_range, district_id)
     encounters = self.get_tips_data_by_name(date_range, district_id)

     encounters.group_by(&:patient_name).each do |name, data|

     row_data = {:start_date => date_range.first,:end_date => date_range.last,
               :person_name => name,
               :total => encounters_count,
               :on_tips => '--', :phone_type => '--',:phone_number => '--',
               :language => '--', :message_type => '--', :content => '--',
               :relevant_date => "--"
            }
        data.each do |observation|
           if observation.concept_id.to_i == content_concept then
              actual_content_concept = Concept.find(observation.value_coded.to_i).fullname rescue nil
              if not actual_content_concept == "WCBA"
                row_data[:content] = actual_content_concept.to_s.capitalize
              else
                row_data[:content] = actual_content_concept
              end

              row_data[:relevant_date] = self.get_relevant_date(actual_content_concept,
                                                                observation[:person_id])
           elsif observation.concept_id.to_i == language_concept
              row_data[:language] = Concept.find(observation.value_coded.to_i).fullname rescue nil
           elsif observation.concept_id.to_i == delivery_concept then
              row_data[:message_type] = Concept.find(observation.value_coded.to_i).fullname rescue nil
           elsif observation.concept_id.to_i == phone_type_concept
              row_data[:phone_type] = Concept.find(observation.value_coded.to_i).fullname rescue nil
           elsif observation.concept_id.to_i == phone_number_concept then
              row_data[:phone_number] = observation.value_text
           elsif observation.concept_id.to_i == on_tips_concept then
              row_data[:on_tips] = Concept.find(observation.value_coded.to_i).fullname rescue nil
           end
        end
    period_data << row_data
   end
   call_data << period_data
  end

  return call_data
   
 end

 def self.get_total_tips_encounters(date_range, district_id)
  encounter_type_list = ["TIPS AND REMINDERS"]
  encounter_types = self.get_encounter_types(encounter_type_list)

  encounters_list = Encounter.find(:all,
                                   :conditions => ["encounter_type IN (?) AND
                                                    encounter_datetime >= ? AND
                                                    encounter_datetime <= ?",
                                                   encounter_types,
                                                   date_range.first,
                                                   date_range.last])
  encounters_list.count
 end

 def self.get_tips_data_by_name(date_range, district_id)
  
  call_id = Concept.find_by_name("CALL ID").id
  encounter_type_list = ["TIPS AND REMINDERS"]
  encounter_types = self.get_encounter_types(encounter_type_list)
                 
    query = "SELECT CONCAT_WS(' ',pn.given_name, pn.family_name) AS patient_name, o.* " +
           "FROM obs o " +
              "INNER JOIN encounter e " +
                "ON e.encounter_id = o.encounter_id AND o.concept_id = #{call_id} " +
              "INNER JOIN call_log cl " +
                "ON o.value_text = cl.call_log_id " + 
                  "AND cl.district = #{district_id} " + 
              "LEFT JOIN person_name pn " +
                "ON e.patient_id = pn.person_id " +
            "WHERE  " +
                  "e.encounter_datetime >= '#{date_range.first}' AND " +
                  "e.encounter_datetime <= '#{date_range.last}' AND " +
                  "e.encounter_type IN (#{encounter_types}) AND " + 
                  "e.voided = 0 AND o.voided = 0 "
=begin
  encounters_list = Encounter.find(:all,
                                   :joins => "LEFT JOIN person_attribute ON person_attribute.person_id = encounter.patient_id",
                                   :conditions => ["encounter.encounter_type IN (?) AND
                                                    encounter.encounter_datetime >= ? AND
                                                    encounter.encounter_datetime <= ? AND
                                                    person_attribute.person_attribute_type_id = ?",
                                                   encounter_types,
                                                   date_range.first,
                                                   date_range.last,
                                                   nearest_health_center],
                                   :include => 'observations')
=end

  data_list = Encounter.find_by_sql(query)

  data_list
 end

 def self.get_relevant_date(content_type , patient_id)

    content_type = content_type.to_s.upcase
    relevant_date = '--'

   if content_type == "CHILD"
     patient = Person.find(patient_id)

     relevant_date = patient.birthdate.to_date.strftime('%Y-%m-%d')

   elsif content_type == "PREGNANCY"

     pregnancy_concept = Concept.find_by_name("EXPECTED DUE DATE").id
     pregnancy_obs = Observation.find(:last,
                                      :select => "value_text",
                                      :conditions => ["concept_id = ? AND person_id = ?",
                                                      pregnancy_concept, patient_id]) rescue nil
     relevant_date = pregnancy_obs[:value_text].to_s if not pregnancy_obs == nil
   elsif content_type == "WCBA"
     tips_encounter_type = EncounterType.find_by_name("TIPS AND REMINDERS").id
     tips_concept = Concept.find_by_name("On tips and reminders program").id
     tips_yes_concept = Concept.find_by_name("Yes").id

     tips_obs = Encounter.find( :last,
                                :conditions => ["encounter_type = ? AND patient_id = ?",
                                                  tips_encounter_type, patient_id]
                              ).observations
     tips_obs.each do | obs |
       if obs[:concept_id] == tips_concept && obs[:value_coded] == tips_yes_concept
          relevant_date = obs[:obs_datetime].to_date.strftime('%Y-%m-%d')
       end
     end
   else
     relevant_date = "--"
   end

   relevant_date
 end
 
 def self.family_planning_satisfaction(start_date, end_date, grouping, district)
   
    district_id = District.find_by_name(district).id
    patients_data = []
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      total_callers = self.get_total_nonpregnant_callers(date_range.first, 
                            date_range.last, 
                            district_id).map(&:patient_id).uniq.count

      query   = self.create_family_planning_query(date_range.first, date_range.last, district_id)
      results = Patient.find_by_sql(query)
      total_callers_on_family_planning = results.map(&:patient_id).uniq.count
      
      row_data = {:start_date => date_range.first,:end_date => date_range.last,
                  :total_callers => total_callers,
                  :total_callers_on_fp => total_callers_on_family_planning,
                  :percentage_of_callers_on_fp => 0, :total_breakdown => 0,
                  :pills => 0, :condoms => 0, :injectables => 0,
                  :implants => 0, :other => 0,
                  :percentage_of_satisfied_with_fpm => 0,
                  :number_wanting_more_info => 0,
                  :percentage_of_callers_wanting_info => 0
            }
            
      results.each do |patient|
        if patient.family_planning_satisfied_vc == 1065
          birth_method = patient.birth_method_vt
          if birth_method.blank?
            birth_method = patient.birth_method_vc
          end
          
          if birth_method == "Injectables"
            row_data[:injectables] += 1
          elsif birth_method == "Implants"
            row_data[:implants] += 1
          elsif birth_method == 190
            row_data[:condoms] += 1
          elsif birth_method == 13
            row_data[:pills] += 1
          else
            row_data[:other] += 1
          end
        end
        if patient.family_planning_info_vc == 1065
          row_data[:number_wanting_more_info] += 1
        end
      end
      row_data[:percentage_of_callers_on_fp] = ((row_data[:total_callers_on_fp].to_f / row_data[:total_callers].to_f) * 100).round(1) if row_data[:total_callers_on_fp] != 0
      row_data[:total_breakdown] = row_data[:pills] + row_data[:condoms] + row_data[:other] + row_data[:injectables] + row_data[:implants]
      row_data[:percentage_of_satisfied_with_fpm] = ((row_data[:total_breakdown].to_f / row_data[:total_callers_on_fp].to_f)* 100).round(1) if row_data[:total_breakdown] != 0
      row_data[:percentage_of_callers_wanting_info] = ((row_data[:number_wanting_more_info].to_f / row_data[:total_callers].to_f) * 100).round(1) if row_data[:number_wanting_more_info] != 0
      patients_data << row_data
    end
  #raise patients_data.to_yaml
  return patients_data
 end
 
 def self.create_family_planning_query(start_date, end_date, district)
#TODO - Remove the hard coding of the ids  
   query = "select e.patient_id AS patient_id, obc.value_text AS call_id,
           ofplan.value_coded_name_id AS family_planning_method_vcni, 
           ofplan.value_coded AS family_planning_method_vc,
           obmethod.value_coded_name_id AS birth_method_vcni, 
           obmethod.value_coded AS birth_method_vc,
           obmethod.value_text AS birth_method_vt,
           ofsatisfied.value_coded_name_id AS family_planning_satisfied_vcni, 
           ofsatisfied.value_coded AS family_planning_satisfied_vc,
           ofinfo.value_coded_name_id AS family_planning_info_vcni, 
           ofinfo.value_coded AS family_planning_info_vc
        from encounter e
            inner join obs ob on e.encounter_id = ob.encounter_id 
                    and ob.concept_id = 5272 and ob.value_text = 'Not pregnant'
            inner join obs obc on e.encounter_id = obc.encounter_id and obc.concept_id = 8304
            inner join call_log cl on obc.value_text = cl.call_log_id and district = #{district}
            inner join encounter efs on efs.encounter_type = 72 and efs.voided = 0
            inner join obs ofs on efs.encounter_id = ofs.encounter_id
                    and ofs.concept_id = 8304 and ofs.value_text = obc.value_text
            inner join obs ofplan on ofplan.encounter_id = ofs.encounter_id and ofplan.concept_id = 1717
            inner join obs obmethod on obmethod.encounter_id = ofs.encounter_id and obmethod.concept_id = 374
            inner join obs ofsatisfied on ofsatisfied.encounter_id = ofs.encounter_id and ofsatisfied.concept_id = 9159
            inner join obs ofinfo on ofinfo.encounter_id = ofs.encounter_id and ofinfo.concept_id = 9160
            where
                e.encounter_type = 111 
                and e.voided = 0
                and e.encounter_datetime >= '#{start_date}' and e.encounter_datetime <= '#{end_date}'"

    return query
 end

 def self.get_total_nonpregnant_callers(start_date, end_date, district)
    query = "select e.patient_id
              from encounter e
                inner join obs ob on e.encounter_id = ob.encounter_id 
                        and ob.concept_id = 5272 and ob.value_text = 'Not pregnant'
                inner join obs obc on e.encounter_id = obc.encounter_id and obc.concept_id = 8304
                inner join call_log cl on obc.value_text = cl.call_log_id and district = #{district}
              where
                  e.encounter_type = 111 
                  and e.voided = 0
                  and e.encounter_datetime >= '#{start_date}' and e.encounter_datetime <= '#{end_date}'"
    result = Patient.find_by_sql(query)
    return result
 end
 def self.info_on_family_planning(start_date, end_date, grouping, district)
   
    district_id = District.find_by_name(district).id
    patients_data = []
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      total_callers = self.get_total_nonpregnant_callers(date_range.first, 
                            date_range.last, 
                            district_id).map(&:patient_id).uniq.count

      query   = self.create_family_planning_info_query(date_range.first, date_range.last, district_id)
      results = Patient.find_by_sql(query)
 
            row_data = {:start_date => date_range.first,:end_date => date_range.last,
                  :total_callers => total_callers,
                  :number_wanting_more_info => 0,
                  :percentage_of_callers_wanting_info => 0
            }
            
      results.each do |patient|
        if patient.family_planning_info_vc == 1065
          row_data[:number_wanting_more_info] += 1
        end
      end
      row_data[:percentage_of_callers_wanting_info] = ((row_data[:number_wanting_more_info].to_f / row_data[:total_callers].to_f) * 100).round(1) if row_data[:number_wanting_more_info] != 0
      patients_data << row_data
    end
  #raise patients_data.to_yaml
  return patients_data
 end
 
 def self.create_family_planning_info_query(start_date, end_date, district)
   query = "select e.patient_id AS patient_id, obc.value_text AS call_id,
           ofplan.value_coded_name_id AS family_planning_method_vcni, 
           ofplan.value_coded AS family_planning_method_vc,
           ofinfo.value_coded_name_id AS family_planning_info_vcni, 
           ofinfo.value_coded AS family_planning_info_vc
        from encounter e
            inner join obs ob on e.encounter_id = ob.encounter_id 
                    and ob.concept_id = 5272 and ob.value_text = 'Not pregnant'
            inner join obs obc on e.encounter_id = obc.encounter_id and obc.concept_id = 8304
            inner join call_log cl on obc.value_text = cl.call_log_id and district = #{district}
            inner join encounter efs on efs.encounter_type = 72 and efs.voided = 0
            inner join obs ofs on efs.encounter_id = ofs.encounter_id
                    and ofs.concept_id = 8304 and ofs.value_text = obc.value_text
            inner join obs ofplan on ofplan.encounter_id = ofs.encounter_id and ofplan.concept_id = 1717
            inner join obs ofinfo on ofinfo.encounter_id = ofs.encounter_id and ofinfo.concept_id = 9160
            where
                e.encounter_type = 111 
                and e.voided = 0
                and e.encounter_datetime >= '#{start_date}' and e.encounter_datetime <= '#{end_date}'"

    return query
 end

 def self.get_nearest_health_centers(district)
    district_id = district
    hc_conditions = ["district = ?", district_id]

    health_centers = HealthCenter.find(:all,:conditions => hc_conditions, :order => 'name') 
    
    return health_centers
    
 end
 def self.new_vs_repeat_callers_report(start_date, end_date, grouping, district)
    district_id = District.find_by_name(district).id
    patients_data = []
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      row_data = {:start_date => date_range.first,:end_date => date_range.last,
                  :total_calls => 0,
                  :new_calls => 0,
                  :new_calls_percentage => 0,
                  :repeat_calls => 0,
                  :repeat_calls_percentage => 0
            }
      
      call_data = CallLog.find(:all,
                               :conditions => ["district = ? AND start_time >= ?
                                 AND start_time <= ?", district_id, date_range.first,
                                 date_range.last])
      row_data[:total_calls] = call_data.count
      call_data.group_by(&:call_mode).each do |mode, call|
        if mode == 1 #new call
          row_data[:new_calls] = call.count 
          row_data[:new_calls_percentage] = (row_data[:new_calls].to_f / row_data[:total_calls].to_f * 100).round(1) if row_data[:total_calls].to_f != 0
        elsif mode == 2 #repeat call
          row_data[:repeat_calls] = call.count 
          row_data[:repeat_calls_percentage] = (row_data[:repeat_calls].to_f / row_data[:total_calls].to_f * 100).round(1) if row_data[:total_calls].to_f != 0
        end 
      end
      
      patients_data << row_data
    end
  #raise patients_data.to_yaml
  return patients_data
 end
 def self.follow_up_report(start_date, end_date, grouping, district)
   district_id = District.find_by_name(district).id
   patients_data = []
   #follow_up_reasons = self.create_follow_up_structure
   date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      
      follow_ups = FollowUp.find(:all,
                                 :conditions => ["district = ? AND date_created >= ?
                                 AND date_created <= ?", district_id, date_range.first,
                                 date_range.last])
      new_follow_up_data                 = {}
      new_follow_up_data[:reasons] = self.create_follow_up_structure
      new_follow_up_data[:start_date]    = date_range.first
      new_follow_up_data[:end_date]      = date_range.last
      new_follow_up_data[:total_calls]   = follow_ups.count 
      
      new_follow_up_data[:reasons].each do |reason|
        follow_ups.group_by(&:result).each do |result, data|
          if result == reason[:reason_concept]
            reason[:call_count] = data.count 
            reason[:call_percentage] = (reason[:call_count].to_f / new_follow_up_data[:total_calls].to_f * 100).round(1) if new_follow_up_data[:total_calls].to_f != 0
          end
        end
      end
      patients_data.push(new_follow_up_data)
      
    end

    return patients_data
 end
 
 def self.create_follow_up_structure
   follow_up_map = []
   
   follow_up_reasons = [
          ['Pregnant woman miscarried', 'Pregnant woman miscarried'],
          ['Child died', 'Child dies'],
          ['Client followed-up on referral and improved', 'Client followed-up on referral and improved'],
          ['Client followed up on referral and did not improve', 'Client followed up on referral and did not improve'],
          ['Client did not follow the referral advice and improved', 'Client did not follow the referral advice and improved'],
          ['Client did not follow the referral advice and did not improve', 'Client did not follow the referral advice and did not improve'],
          ['Client went to the health facility but was unable to get treatment', 'Client went to the health facility but was unable to get treatment'],
          ['Client unable to follow-up on referral', 'Client unable to follow-up on referral'],
          ['Client appreciates service', 'Client appreciates service'],
          ['Other','OTHER']]
   
   follow_up_reasons.each do |reason|
     mapping = {:reason_name  => reason.first,  :reason_concept => reason.last,
                :call_count  => 0,    :call_percentage  => 0}
    follow_up_map << mapping
   end

   return follow_up_map
 end

 def self.anc_connect_clients( grouping, start_date, end_date, district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id
    date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]
    patients_data = []
    program_id = Program.find_by_name('ANC CONNECT PROGRAM').id
    
    date_ranges.map do |date_range|
        patients = Patient.find_by_sql("
            select pp.patient_id, pn.given_name,
            (select value from person_attribute where person_id=pp.patient_id AND person_attribute_type_id = #{cell_phone_attribute_type}
            ORDER BY DATE(date_created) DESC LIMIT 1) as cell_phone_number, 
            pn.middle_name, pn.family_name, p.birthdate, pa.address2 as home_village
            from patient_program pp inner join obs o on pp.patient_id = o.person_id and o.concept_id = #{call_id}
            inner join call_log cl on o.value_text = cl.call_log_id and cl.district = #{district_id}
            inner join person_name pn on pp.patient_id = pn.person_id
            inner join person_address pa on pp.patient_id = pa.person_id
            inner join person p on p.person_id = pp.patient_id
            where pp.program_id = #{program_id}
            and DATE(pp.date_enrolled) >= '#{date_range.first.to_date}' and DATE(pp.date_enrolled) <= '#{date_range.last.to_date }'
            and pp.voided=0 GROUP BY pp.patient_id"
         )
         dates = {:start_date => date_range.first, :end_date => date_range.last}
        patients_data.push([dates, patients]) unless patients.blank?
    end
    return patients_data
  end
end
