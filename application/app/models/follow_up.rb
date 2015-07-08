class FollowUp < ActiveRecord::Base
  set_table_name "follow_up"
  set_primary_key "follow_up_id"
  include Openmrs

  def self.get_follow_ups(district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date

    encounter_type = EncounterType.find_by_name('UPDATE OUTCOME').id
    concept_id = ConceptName.find_by_name('Outcome').concept_id

    text_values = ['REFERRED TO A HEALTH CENTRE','REFERRED TO NEAREST VILLAGE CLINIC']

    patients = Encounter.find_by_sql("
        select e.patient_id, pn.given_name,pn.middle_name, pn.family_name, p.birthdate, pa.address2, pat.value
            from encounter e
                inner join obs o on e.encounter_id = o.encounter_id
                inner join obs obs_call on o.encounter_id = obs_call.encounter_id
                  and obs_call.concept_id = #{call_id}
                inner join call_log cl on obs_call.value_text = cl.call_log_id
                  and cl.district = #{district_id}
                inner join person_name pn on e.patient_id = pn.person_id
                inner join person_address pa on e.patient_id = pa.person_id
                inner join person p on p.person_id = e.patient_id
                inner join person_attribute pat on e.patient_id = pat.person_id
            where e.encounter_type = #{encounter_type}
                and o.concept_id = #{concept_id} and pat.voided = 0
                and o.value_text in ('REFERRED TO A HEALTH CENTRE','REFERRED TO NEAREST VILLAGE CLINIC')
                and e.encounter_datetime >= '#{start_date} 00:00' and encounter_datetime <= '#{current_date} 23:59'
                and pat.person_attribute_type_id = #{cell_phone_attribute_type}
                and e.patient_id NOT IN (SELECT patient_id FROM follow_up WHERE date_created >= '#{start_date} 00:00' AND date_created <='#{current_date} 23:59')
                GROUP BY e.patient_id ")

    return patients
  end

  def self.get_anc_follow_ups(district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date
    last_anc_date = (current_date - (14 * followup_threshhold)).to_date

    encounter_type = EncounterType.find_by_name('PREGNANCY STATUS').id
    concept_id = ConceptName.find_by_name('Expected due date').concept_id
    anc_connect_program_id = Program.find_by_name('ANC CONNECT PROGRAM').program_id
    next_visit_date_concept_id = ConceptName.find_by_name('Next ANC Visit Date').concept_id
    anc_encounter_type = EncounterType.find_by_name("ANC VISIT").id

=begin
    patients = Encounter.find_by_sql("SELECT e.patient_id, pn.given_name,pn.family_name,pn.family_name_prefix,
                                      pa.city_village,pa.county_district,o.concept_id,o.value_text,
                                      floor((280 - (DATE(o.value_text) - curdate()))/7) as gestation_age FROM encounter e
                                      INNER JOIN person_name pn ON e.patient_id = pn.person_id
                                      INNER JOIN person_address pa ON e.patient_id = pa.person_id
                                      INNER JOIN person p ON p.person_id = e.patient_id
                                      INNER JOIN patient_program pp ON pp.patient_id = e.patient_id
                                      INNER JOIN obs o ON o.encounter_id = e.encounter_id
                                      INNER JOIN obs obs_call on o.encounter_id = obs_call.encounter_id
                                      AND obs_call.concept_id = #{call_id}
                                      INNER JOIN call_log cl on obs_call.value_text = cl.call_log_id
                                      AND cl.district = #{district_id}
                                      WHERE e.encounter_type = #{encounter_type}
                                      AND pp.program_id = #{anc_connect_program_id}
                                      AND o.concept_id = #{concept_id} and o.value_text IS NOT NULL
                                      AND floor((280 - (DATE(o.value_text) - curdate()))/7) < 42
                                      AND floor((280 - (DATE(o.value_text) - curdate()))/7) > 0
                                      AND e.voided = 0
                                      AND e.patient_id IN(SELECT ee.patient_id
                                                          FROM encounter ee
                                                          INNER JOIN obs oo
                                                          ON ee.encounter_id = oo.encounter_id
                                                          WHERE ee.encounter_type = #{anc_encounter_type}
                                                          AND oo.concept_id = #{next_visit_date_concept_id}
                                                          AND DATE(oo.value_text) <= '#{last_anc_date} 23:59'
                                                          AND oo.voided = 0
                                                          GROUP BY ee.patient_id
                                                          HAVING COUNT(ee.patient_id) < 4)
                                      AND e.patient_id NOT IN (SELECT ee.patient_id
                                                               FROM encounter ee
                                                               WHERE ee.encounter_type = #{encounter_type}
                                                               AND ee.date_created >= '#{start_date} 00:00'
                                                               AND ee.date_created <='#{current_date} 23:59'
                                                               AND ee.voided = 0)
                                      GROUP BY e.patient_id
                                      ORDER BY e.encounter_datetime DESC")
=end
    patients = Encounter.find_by_sql("SELECT
                                          *
                                      FROM
                                          anc_connect_program_clients
                                      WHERE
                                          gestation_age < 42 and gestation_age > 0
                                              AND DATE(next_visit_date) <= '#{last_anc_date} 23:59'
                                              AND district = #{district_id}
                                      UNION SELECT
                                          *
                                      FROM
                                          anc_connect_program_clients
                                      WHERE
                                          gestation_age < 42 and gestation_age > 0
                                              AND next_visit_date IS NULL
                                              AND number_of_days_after_reg >= 21
                                              AND district = #{district_id}")

    data = patients.select{|p| HsaVillage.is_patient_village_in_anc_connect(p.patient_id, district)}
    return data
  end

  def self.get_client_follow_ups(client_id, district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date

    encounter_type = EncounterType.find_by_name('UPDATE OUTCOME').id
    concept_id = ConceptName.find_by_name('Outcome').concept_id

    text_values = ['REFERRED TO A HEALTH CENTRE','REFERRED TO NEAREST VILLAGE CLINIC']

    patients = Encounter.find_by_sql("
        select e.patient_id, pn.given_name,pn.middle_name, pn.family_name, p.birthdate, pa.address2, pat.value
            from encounter e
                inner join obs o on e.encounter_id = o.encounter_id
                inner join obs obs_call on o.encounter_id = obs_call.encounter_id
                  and obs_call.concept_id = #{call_id}
                inner join call_log cl on obs_call.value_text = cl.call_log_id
                  and cl.district = #{district_id}
                inner join person_name pn on e.patient_id = pn.person_id
                inner join person_address pa on e.patient_id = pa.person_id
                inner join person p on p.person_id = e.patient_id
                inner join person_attribute pat on e.patient_id = pat.person_id
            where e.encounter_type = #{encounter_type}
                and o.concept_id = #{concept_id} and pat.voided = 0
                and o.value_text in ('REFERRED TO A HEALTH CENTRE','REFERRED TO NEAREST VILLAGE CLINIC')
                and e.encounter_datetime >= '#{start_date} 00:00' and encounter_datetime <= '#{current_date} 23:59'
                and pat.person_attribute_type_id = #{cell_phone_attribute_type}
                and (e.patient_id NOT IN (SELECT patient_id FROM follow_up WHERE date_created >= '#{start_date} 00:00'
              AND date_created <='#{current_date} 23:59' and patient_id = #{client_id}) AND e.patient_id = #{client_id})
               ")

    return patients
  end

  def self.is_patient_on_anc_follow_ups(followup_patient_id, district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date
    last_anc_date = (current_date - (14 * followup_threshhold)).to_date

    encounter_type = EncounterType.find_by_name('PREGNANCY STATUS').id
    concept_id = ConceptName.find_by_name('Expected due date').concept_id
    anc_connect_program_id = Program.find_by_name('ANC CONNECT PROGRAM').program_id
=begin
    patients = Encounter.find_by_sql("SELECT e.patient_id, pn.given_name,pn.family_name,pn.family_name_prefix,
                                      pa.city_village,pa.county_district,o.concept_id,o.value_text,
                                      floor((280 - (DATE(o.value_text) - curdate()))/7) as gestation_age FROM encounter e
                                      INNER JOIN person_name pn ON e.patient_id = pn.person_id
                                      INNER JOIN person_address pa ON e.patient_id = pa.person_id
                                      INNER JOIN person p ON p.person_id = e.patient_id
                                      INNER JOIN patient_program pp ON pp.patient_id = e.patient_id
                                      INNER JOIN obs o ON o.encounter_id = e.encounter_id
                                      INNER JOIN obs obs_call on o.encounter_id = obs_call.encounter_id
                                      AND obs_call.concept_id = #{call_id}
                                      INNER JOIN call_log cl on obs_call.value_text = cl.call_log_id
                                      AND cl.district = #{district_id}
                                      WHERE e.encounter_type = #{encounter_type}
                                      AND pp.program_id = #{anc_connect_program_id}
                                      AND o.concept_id = #{concept_id} and o.value_text IS NOT NULL
                                      AND floor((280 - (DATE(o.value_text) - curdate()))/7) > 0
                                      AND floor((280 - (DATE(o.value_text) - curdate()))/7) < 42
                                      AND e.voided = 0
                                      GROUP BY e.patient_id
                                      ORDER BY e.encounter_datetime DESC")
=end
        patients = Encounter.find_by_sql("SELECT
                                                  *
                                              FROM
                                                  anc_connect_program_clients
                                              WHERE
                                                  gestation_age < 42 and gestation_age > 0
                                                      AND DATE(next_visit_date) <= '#{last_anc_date} 23:59'
                                                      AND patient_id =  #{followup_patient_id}
                                              AND district = #{district_id}
                                              UNION SELECT
                                                  *
                                              FROM
                                                  anc_connect_program_clients
                                              WHERE
                                                  gestation_age < 42 and gestation_age > 0
                                              AND next_visit_date IS NULL
                                              AND number_of_days_after_reg >= 21
                                                      AND patient_id =  #{followup_patient_id}
                                                     AND district = #{district_id}")

    data = patients.select{|p| HsaVillage.is_patient_village_in_anc_connect(p.patient_id,district)}
    return data.present?
  end

  def self.client_needs_followup(followup_patient_id, district)
    #added this to speed up search for one client

    data = false
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date
    last_anc_date = (current_date - (14 * followup_threshhold)).to_date

    encounter_type = EncounterType.find_by_name('PREGNANCY STATUS').id
    concept_id = ConceptName.find_by_name('Expected due date').concept_id
    anc_connect_program_id = Program.find_by_name('ANC CONNECT PROGRAM').program_id

    patient = Patient.find_by_sql("SELECT
                              client_needs_followup(#{followup_patient_id},#{district_id}, '#{last_anc_date} 23:59') as test")

    if patient.first.test = 1
      data = HsaVillage.is_patient_village_in_anc_connect(followup_patient_id,district)
    else
      data = false
    end

    return data
  end

  def self.get_birth_plan_follow_ups(district)

    district_id = District.find_by_name(district).id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date

    encounter_type = EncounterType.find_by_name('PREGNANCY STATUS').id
    concept_id = ConceptName.find_by_name('Expected due date').concept_id

    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id
    anc_connect_program_id = Program.find_by_name('ANC CONNECT PROGRAM').program_id
=begin
    patients = Encounter.find_by_sql("
				SELECT e.patient_id, pn.given_name, p.birthdate, pn.family_name,pn.family_name_prefix,
					pa.city_village,pa.county_district,o.concept_id,o.value_text, floor((280 - (DATE(o.value_text) - curdate()))/7) as gestation_age
					FROM encounter e
						INNER JOIN person_name pn ON e.patient_id = pn.person_id
						INNER JOIN person_address pa ON e.patient_id = pa.person_id
						INNER JOIN person p ON p.person_id = e.patient_id
						INNER JOIN obs o ON o.encounter_id = e.encounter_id
						INNER JOIN patient_program pp ON pp.patient_id = e.patient_id
					WHERE e.encounter_type = #{encounter_type}
							AND o.concept_id = #{concept_id} and o.value_text IS NOT NULL
							AND floor((280 - (DATE(o.value_text) - curdate()))/7) < 40
							AND floor((280 - (DATE(o.value_text) - curdate()))/7) >= 38
							AND pp.program_id = #{anc_connect_program_id}
							AND e.voided = 0
				GROUP BY e.patient_id;
    ")
=end
        patients = Encounter.find_by_sql("SELECT
                                                  *
                                              FROM
                                                  anc_connect_program_clients
                                              WHERE
                                                  gestation_age < 42 and gestation_age >= 38
                                              AND district = #{district_id}")

		data = patients.select {|p| birth_plan_encounter(p.patient_id).nil? }

    return data
  end

  def self.birth_plan_encounter(patient_id)
  	encounter_type = EncounterType.find_by_name('BIRTH PLAN').id
  	Encounter.find_by_sql("
			SELECT encounter_datetime
				FROM encounter
			WHERE encounter_type = #{encounter_type} and patient_id = #{patient_id}
						and voided=0
			ORDER BY encounter_datetime DESC
			LIMIT 1
		").first.encounter_datetime.to_date rescue nil
  end


  def self.get_anc_delivery_follow_ups(district)
    district_id = District.find_by_name(district).id
    call_id = Concept.find_by_name("CALL ID").id

    followup_threshhold = GlobalProperty.get_property('followup.threshhold').value rescue 1
    cell_phone_attribute_type = PersonAttributeType.find_by_name('Cell Phone Number').id

    current_date = Date.today.to_date
    start_date = (current_date - (7 * followup_threshhold)).to_date
    baby_delivery_date = (current_date - 280).to_date

    encounter_type = EncounterType.find_by_name('PREGNANCY STATUS').id
    concept_id = ConceptName.find_by_name('Expected due date').concept_id
    anc_connect_program_id = Program.find_by_name('ANC CONNECT PROGRAM').program_id
    baby_encounter_type = EncounterType.find_by_name('BABY DELIVERY').id
=begin
    patients = Encounter.find_by_sql("SELECT e.patient_id, pn.given_name,pn.family_name,pn.family_name_prefix,
                                      pa.city_village,pa.county_district,o.concept_id,o.value_text,
                                      floor((280 - (DATE(o.value_text) - curdate()))/7) as gestation_age FROM encounter e
                                      INNER JOIN person_name pn ON e.patient_id = pn.person_id
                                      INNER JOIN person_address pa ON e.patient_id = pa.person_id
                                      INNER JOIN person p ON p.person_id = e.patient_id
                                      INNER JOIN patient_program pp ON pp.patient_id = e.patient_id
                                      INNER JOIN obs o ON o.encounter_id = e.encounter_id
                                      INNER JOIN obs obs_call on o.encounter_id = obs_call.encounter_id
                                      AND obs_call.concept_id = #{call_id}
                                      INNER JOIN call_log cl on obs_call.value_text = cl.call_log_id
                                      AND cl.district = #{district_id}
                                      WHERE e.encounter_type = #{encounter_type}
                                      AND pp.program_id = #{anc_connect_program_id}
                                      AND o.concept_id = #{concept_id} and o.value_text IS NOT NULL
                                      AND floor((280 - (DATE(o.value_text) - curdate()))/7) >= 42
                                      AND floor((280 - (DATE(o.value_text) - curdate()))/7) <= 46
                                      AND e.patient_id NOT IN (SELECT ee.patient_id
                                                               FROM encounter ee
                                                               WHERE ee.encounter_type = #{encounter_type}
                                                               AND ee.date_created >= '#{start_date} 00:00'
                                                               AND ee.date_created <='#{current_date} 23:59'
                                                               AND ee.voided = 0)
                                      AND e.patient_id NOT IN (SELECT eee.patient_id
                                                               FROM encounter eee
                                                               WHERE eee.encounter_type = #{baby_encounter_type}
                                                               AND eee.date_created >= '#{baby_delivery_date} 00:00'
                                                               AND eee.date_created <='#{current_date} 23:59'
                                                               AND eee.voided = 0)
                                      AND e.voided = 0
                                      GROUP BY e.patient_id
                                      ORDER BY floor((280 - (DATE(o.value_text) - curdate()))/7) DESC;")
=end
           patients = Encounter.find_by_sql("SELECT
                                                  *
                                              FROM
                                                  anc_connect_program_clients
                                              WHERE
                                                  gestation_age <= 46 and gestation_age >= 42
                                              AND district = #{district_id}")


		data = patients.select {|p| delivery_encounter(p.patient_id).nil? }

    return data
  end

  def self.delivery_encounter(patient_id)
  	encounter_type = EncounterType.find_by_name('BABY DELIVERY').id
  	Encounter.find_by_sql("
			SELECT encounter_datetime
				FROM encounter
			WHERE encounter_type = #{encounter_type} and patient_id = #{patient_id}
						and voided=0
			ORDER BY encounter_datetime DESC
			LIMIT 1
		").first.encounter_datetime.to_date rescue nil
  end

end
