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
                and o.concept_id = #{concept_id}
                and o.value_text in ('REFERRED TO A HEALTH CENTRE','REFERRED TO NEAREST VILLAGE CLINIC')
                and pat.person_attribute_type_id = #{cell_phone_attribute_type}
                and e.encounter_datetime >= '#{start_date} 00:00' and encounter_datetime <= '#{current_date} 23:59' 
                and e.patient_id NOT IN (SELECT patient_id FROM follow_up WHERE date_created >= '#{start_date} 00:00' AND date_created <='#{current_date} 23:59') ")
    return patients
  end


end
