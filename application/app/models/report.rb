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

end
