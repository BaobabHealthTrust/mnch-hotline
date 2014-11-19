#!/usr/bin/ruby
require 'rubygems'
require 'json'

def textit_integration
  path = "#{Rails.root}/script/"
  file_name = "#{path}AncConnectSync.example.json"
  json = File.read(file_name)
  data = JSON.parse(json)

  User.current_user = User.find(1)
  data.each do |key|
    anc_conn_id = key["anc_conn_id"]
    nickname = key["nickname"]
    lastname = key["lastname"]
    village = key["village"]
    health_facility = key["health_facility"]
    edd = key["edd"] #pregnancy_status enc
    phone = key["phone"]
    registration_time = key["registration_time"]
    next_visit_date = key["next_visit_date"] #birth_plan enc
    
    birth_plan_facility = key["birth_plan_facility"] #birth_plan enc
    delivery_date = key["delivery_date"] #delivery enc
    delivery_facility = key["delivery_facility"] #delivery enc


    ActiveRecord::Base.transaction do
      anc_identifier_type = PatientIdentifierType.find_by_name("ANC Connect ID") rescue nil
      anc_attribute = PersonAttribute.find(:last,:conditions =>["voided = 0 AND person_attribute_type_id = ?
          AND value =?", anc_identifier_type.id, anc_conn_id])

      cell_phone_attribute_id = PersonAttributeType.find_by_name('CELL PHONE NUMBER').id
      
      if (anc_attribute.blank?)
        puts "creating person..."
        person = Person.create({
            :birthdate => (Date.today - 20.years),
            :gender => "F",
            :birthdate_estimated => 1,
            :creator =>  1
        })
        
        patient = person.patient.create
        puts "creating ANC connect ID..."
        patient.patient_identifiers.create({
            :identifier_type => anc_identifier_type.id,
            :identifier => anc_conn_id,
            :creator =>  1
        })
      
        puts "creating person names..."
        person.names.create({
          :family_name_prefix => nickname,
          :family_name => lastname,
           :creator =>  1
        })
      
        puts "creating phone number..."
        person.person_attributes.create({
          :person_attribute_type_id => cell_phone_attribute_id,
          :value => phone,
          :creator =>  1
        })

        puts "creating addresses..."
        person.addresses.create({
          :address2 => village,
          :county_district => "",
          :creator =>  1
        })
        
      else
        patient = anc_attribute.person.patient
        person_name = patient.person.names.last

        person_name.family_name_prefix = nickname
        person_name.family_name = lastname
        person_name.save!
        
        PersonAttribute.create_attribute(patient, phone, "CELL PHONE NUMBER")
        anc_visit_enc_type = Encounter.find_by_name("ANC VISIT").id
        previous_anc_visits = Encounter.find(:all, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, anc_visit_enc_type])
        
        (previous_anc_visits || []).each do |p_visit|
          p_visit.void("Overiding data with that from textit system")
        end
      
        key["anc_visits"].each do |anc_visit|
          visit_date = anc_visit["date"]
          n_visit_date = anc_visit["next_visit_date"]
          
          new_anc_visit_enc = patient.encounters.create({
            :encounter_type => anc_visit_enc_type,
            :encounter_datetime => visit_date,
            :provider_id => 1,
            :creator =>  1
          })
        
          observation = {}
          observation[:concept_name] = "NEXT ANC VISIT DATE"
          observation[:encounter_id] = new_anc_visit_enc.id
          observation[:obs_datetime] = visit_date
          observation[:person_id] = patient.id
          observation[:value_coded_or_text] = n_visit_date
          Observation.create(observation)
        end
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Editing Pregnacy Enc>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        pregnacy_enc_type = Encounter.find_by_name("PREGNANCY STATUS").id
        previous_pregnancy_enc = Encounter.find(:last, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, pregnacy_enc_type])
        previous_pregnancy_enc.void("Overiding data with that from textit system") unless previous_pregnancy_enc.blank?

        new_pregnancy_enc = patient.encounters.create({
            :encounter_type => pregnacy_enc_type,
            :encounter_datetime => registration_time,
            :provider_id => 1,
            :creator =>  1
          })
        observation = {}
        observation[:concept_name] = "PREGNANCY STATUS"
        observation[:encounter_id] = new_pregnancy_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = "PREGNANT"
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "PREGNANCY DUE DATE"
        observation[:encounter_id] = new_pregnancy_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = edd
        Observation.create(observation)

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BIRTH PLAN enc>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        birth_plan_enc_type = Encounter.find_by_name("BIRTH PLAN").id
        previous_birth_plan_enc = Encounter.find(:last, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, birth_plan_enc_type])
        previous_birth_plan_enc.void("Overiding data with that from textit system") unless previous_birth_plan_enc.blank?

        new_birth_plan_enc = patient.encounters.create({
            :encounter_type => birth_plan_enc_type,
            :encounter_datetime => registration_time,
            :provider_id => 1,
            :creator =>  1
        })
      
        observation = {}
        observation[:concept_name] = "BIRTH PLAN"
        observation[:encounter_id] = new_birth_plan_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = "YES"
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "DELIVERY LOCATION"
        observation[:encounter_id] = new_birth_plan_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = birth_plan_facility
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "GO TO HOSPITAL DATE"
        observation[:encounter_id] = new_birth_plan_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = next_visit_date
        Observation.create(observation)
        
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BABY DELIVERY encounter>>>>>>>>>>>>>>>>>>>>
        baby_delivery_enc_type = Encounter.find_by_name("BABY DELIVERY").id
        previous_baby_delivery_enc = Encounter.find(:last, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, baby_delivery_enc_type])
        previous_baby_delivery_enc.void("Overiding data with that from textit system") unless previous_baby_delivery_enc.blank?

        new_baby_delivery_enc = patient.encounters.create({
            :encounter_type => baby_delivery_enc_type,
            :encounter_datetime => registration_time,
            :provider_id => 1,
            :creator =>  1
        })

        observation = {}
        observation[:concept_name] = "DELIVERED"
        observation[:encounter_id] = new_baby_delivery_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = "YES"
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "DELIVERY DATE"
        observation[:encounter_id] = new_baby_delivery_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = delivery_date
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "DELIVERY LOCATION"
        observation[:encounter_id] = new_baby_delivery_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = delivery_facility
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "HEALTH FACILITY NAME"
        observation[:encounter_id] = new_baby_delivery_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = health_facility
        Observation.create(observation)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      end
    end
    
  end
  
end
textit_integration
=begin
  [
	{
		"anc_conn_id": "4450",
		"nickname": "Jane",
		"lastname": "Doe",
		"village": "Thunga 2",
		"health_facility": "Mbera",
		"lmp": "2014-03-15T00:00+0200",
		"edd": "2014-12-15T00:00+0200",
		"phone": "265987654321",
		"hsa_name": "Stella Goma",
		"hsa_phone": "265987654322",
		"registration_time": "2014-03-21T08:31+0200",
		"next_visit_date": "2014-06-01T00:00+0200",
		"anc_visits": {
			"1": {
				"date": "2014-04-01T00:00+0200",
				"next_visit_date": "2014-05-01T00:00+0200"
			},
			"2": {
				"date": "2014-05-01T00:00+0200",
				"next_visit_date": "2014-06-01T00:00+0200"
			}
		},
		"birth_plan_facility": "Balaka Hospital",
		"delivery_date": "2014-12-18T00:00+0200",
		"delivery_facility": "enroute"
	}
]
=end