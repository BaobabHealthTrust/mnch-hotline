#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'logger'

def textit_integration
  config = YAML.load_file("config/report.yml")
  path = config["config"]["anc_connect_file"]
  json = File.read(path)
  data = JSON.parse(json)

  User.current_user = User.find(1)

  log = Logger.new( 'log/textit_integration.txt', 'monthly' ) #After a month, the old file will be deleted and a new one will be created
  log.debug "************************************************"
  log.debug "DATE:   #{Date.today.strftime("%d-%b-%Y")} TIME:#{Time.now.strftime("%H:%M")}"
  log.debug "************************************************"
  data.each do |key|
    anc_conn_id = key["anc_conn_id"]
    nickname = key["nickname"]
    lastname = key["lastname"]
    village = key["village"]
    health_facility = key["health_facility"]
    edd = key["edd"].to_date #pregnancy_status enc
    phone = key["phone"].to_s
    registration_time = key["registration_time"].to_date
    next_visit_date = key["next_visit_date"] #birth_plan enc
    
    birth_plan_facility = key["birth_plan_facility"] #birth_plan enc
    delivery_date = key["delivery_date"] #delivery enc
    delivery_facility = key["delivery_facility"] #delivery enc
    hsa_name = key["hsa_name"]
    #village_id = Village.find_by_name(village).id rescue 99999999
    #hsa_id = HsaVillage.find_by_village_id(village_id).hsa_id rescue 99999999


    hsa_phone = key["hsa_phone"]
    start_pos = hsa_phone.length - 9 #Only interested with the last 9 digits
    trimmed_hsa_phone_number = hsa_phone[start_pos, 9] #something like 999606901
    phone_types = ["Cell Phone Number", "Office Phone Number"]
    attribute_ids = []
    phone_types.each do |phone_type|
      attribute_ids << PersonAttributeType.find_by_name(phone_type).id
    end

    hsa = PersonAttribute.find(:last, :conditions => ["person_attribute_type_id IN (?) AND
                RIGHT(value, 9) =?", attribute_ids, trimmed_hsa_phone_number])
    hsa_ta_name = ""
    hsa_district = ""
    hsa_village_available = false
    unless hsa.blank?
      hsa_id = hsa.person_id
      hsa_data = Person.find_by_sql("select vg.name as village_name, hsa.village_id as village_id,
                       hsa.district_id as district_id, vg.traditional_authority_id as ta_id,
                     ta.name as ta_name
                  FROM hsa_villages hsa INNER JOIN village vg on hsa.village_id = vg.village_id
              INNER JOIN traditional_authority ta ON vg.traditional_authority_id = ta.traditional_authority_id
            WHERE hsa.hsa_id = #{hsa.person_id}")
      
      (hsa_data || []).each do |d|
        village_name = d.village_name
        village_id = d.village_id
        district_id = d.district_id
        ta_id = d.district_id
        ta_name = d.ta_name
        next unless (village.squish.downcase == village_name.squish.downcase)
        hsa_village_available = true
        hsa_ta_name = ta_name
        hsa_district = district_id
        break
      end
  if (hsa_village_available)
    ActiveRecord::Base.transaction do
      anc_identifier_type = PatientIdentifierType.find_by_name("ANC Connect ID") rescue nil
      anc_identifier = PatientIdentifier.find(:last,:conditions =>["voided = 0 AND identifier_type = ?
          AND identifier =?", anc_identifier_type.id, anc_conn_id])

      cell_phone_attribute_id = PersonAttributeType.find_by_name('CELL PHONE NUMBER').id
      concept_id = Concept.find_by_name("PATIENT ENROLLED").id
      program_id = Program.find_by_name("ANC Connect Program").program_id
      program_workflow_state_id = ProgramWorkflowState.find_by_concept_id(concept_id).id
      patient = ""
      
      if (anc_identifier.blank?)
        puts "creating person... ID=#{Person.last.id + 1}"
        person = Person.create({
            :birthdate => (Date.today - 20.years),
            :gender => "F",
            :birthdate_estimated => 1,
            :creator =>  1
        })
      
        puts "creating patient..."
        patient = person.create_patient
        
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
          :city_village => village,
          :county_district => hsa_ta_name,
          :creator =>  1
        })
        #>>>>>>>>>>>>>>>>>>>>>>>>>>Enrolling ANC connect program<<<<<<<<<<<<<<<<
        puts "Enrolling the client in ANC connect program..."
        
        patient_program = patient.patient_programs.create({
            :program_id => program_id,
            :date_enrolled => registration_time
        })

        patient_program.patient_states.create({
          :state => program_workflow_state_id,
          :start_date => registration_time
        })
        #>>>>>>>>>>>>>>>>>>>>>>>>>Enrollment done<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      else
        puts "Existing patient found. ID=#{anc_identifier.patient.id}"
        puts "<<<<<<Working on patient with ID #{anc_identifier.patient.id}>>>>>>"
        patient = anc_identifier.patient
        person = patient.person
        person_name = patient.person.names.last

        person_name.family_name_prefix = nickname
        person_name.family_name = lastname
        person_name.save!
        
        person.addresses.last.update_attributes({
          :address2 => village,
          :city_village => village,
          :county_district => hsa_ta_name,
          :creator =>  1
        })

        PersonAttribute.create_attribute(patient, phone, "CELL PHONE NUMBER")
      end

        anc_visit_enc_type = EncounterType.find_by_name("ANC VISIT").id
        previous_anc_visits = Encounter.find(:all, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, anc_visit_enc_type])

        puts "Voiding past ANC visits. #{previous_anc_visits.count} encounters found" unless previous_anc_visits.blank?
        (previous_anc_visits || []).each do |p_visit|
          p_visit.void("Overiding data with that from textit system")
        end

        puts "Creating ANC visits encounter"
        puts "------------------------------"
        
        (key["anc_visits"] || []).each do |anc_visit|
          visit_date = anc_visit["date"].to_date
          n_visit_date = anc_visit["next_visit_date"].to_date
          new_anc_visit_enc = patient.encounters.create({
            :encounter_type => anc_visit_enc_type,
            :encounter_datetime => visit_date,
            :provider_id => hsa_id,
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
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Editing Pregnancy Enc>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        pregnacy_enc_type = EncounterType.find_by_name("PREGNANCY STATUS").id
        previous_pregnancy_enc = Encounter.find(:last, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, pregnacy_enc_type])
        puts "Voiding previous pregnancy encounter" unless previous_pregnancy_enc.blank?
        previous_pregnancy_enc.void("Overiding data with that from textit system") unless previous_pregnancy_enc.blank?

        puts "Creating Pregnancy Status encounter"
        puts "------------------------------"
        new_pregnancy_enc = patient.encounters.create({
            :encounter_type => pregnacy_enc_type,
            :encounter_datetime => registration_time,
            :provider_id => hsa_id,
            :creator =>  1
          })
        puts "Creating pregnancy encounter observations..."
        observation = {}
        observation[:concept_name] = "PREGNANCY STATUS"
        observation[:encounter_id] = new_pregnancy_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = "Pregnant"
        Observation.create(observation)

        observation = {}
        observation[:concept_name] = "PREGNANCY DUE DATE"
        observation[:encounter_id] = new_pregnancy_enc.id
        observation[:obs_datetime] = registration_time
        observation[:person_id] = patient.id
        observation[:value_coded_or_text] = edd
        Observation.create(observation)

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BIRTH PLAN enc>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        birth_plan_enc_type = EncounterType.find_by_name("BIRTH PLAN").id
        previous_birth_plan_enc = Encounter.find(:last, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, birth_plan_enc_type])
        previous_birth_plan_enc.void("Overiding data with that from textit system") unless previous_birth_plan_enc.blank?
        puts "Creating Birth plan encounter"
        puts "------------------------------"
        new_birth_plan_enc = patient.encounters.create({
            :encounter_type => birth_plan_enc_type,
            :encounter_datetime => registration_time,
            :provider_id => hsa_id,
            :creator =>  1
        })
         puts "Creating birthplan observations ..."
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
        baby_delivery_enc_type = EncounterType.find_by_name("BABY DELIVERY").id
        previous_baby_delivery_enc = Encounter.find(:last, :conditions => ["patient_id =?
          AND encounter_type =?", patient.id, baby_delivery_enc_type])
        previous_baby_delivery_enc.void("Overiding data with that from textit system") unless previous_baby_delivery_enc.blank?
        puts "Creating Baby Delivery encounter"
        puts "------------------------------"
        new_baby_delivery_enc = patient.encounters.create({
            :encounter_type => baby_delivery_enc_type,
            :encounter_datetime => registration_time,
            :provider_id => hsa_id,
            :creator =>  1
        })
        puts "Creating baby delivery observations ..."
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

        #>>>>>>>>>>>>>>>>>>>>>>>>>>Enrolling ANC connect program<<<<<<<<<<<<<<<<
        pp =  patient.patient_programs.find(:last, :conditions => ["program_id =?", program_id])
        if (pp.blank?)
          puts "Enrolling the client in ANC connect program..."
          patient_program = patient.patient_programs.create({
              :program_id => program_id,
              :date_enrolled => registration_time
          })

          patient_program.patient_states.create({
            :state => program_workflow_state_id,
            :start_date => registration_time
          })
        end
        #>>>>>>>>>>>>>>>>>>>>>>>>>Enrollment done<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

     end
    else
      log.error "\t\tError: Village #{village} missing!!!"
      log.debug "\t\tHSA found with this phone number: #{hsa_phone}"
      log.debug "\t\tBut records not created because this village #{village} not found"
      log.debug "\t\t---------------------------------------------------------------"
   end
  else
     log.error "\t\tError: HSA record not found"
     log.debug "\t\t HSA not found with this phone number: #{hsa_phone}"
     log.debug "\t\tAll associated records with this HSA (#{hsa_name}) not recorded"
     log.debug "\t\t----------------------------------------------------------------"
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