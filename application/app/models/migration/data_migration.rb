class DataMigration
National_ID = PatientIdentifierType.find_by_name('National id')
ARV_Number = PatientIdentifierType.find_by_name('ARV Number')
Pre_ARV_Number = PatientIdentifierType.find_by_name('Pre ART Number (Old format)')
VHW_ID = PatientIdentifierType.find_by_name('VHW ID')
Dummy_ID = PatientIdentifierType.find_by_name('Dummy ID')
EID_Number = PatientIdentifierType.find_by_name('EID Number')
MDR_TB_Program = PatientIdentifierType.find_by_name('MDR-TB Program Identifier')
Part_Number = PatientIdentifierType.find_by_name('PART Number')
Diabetes_Number = PatientIdentifierType.find_by_name('Diabetes Number')
LAB_IDENTIFIER = PatientIdentifierType.find_by_name('LAB IDENTIFIER')
DS_Number = PatientIdentifierType.find_by_name('DS Number')
Old_Identification_Number = PatientIdentifierType.find_by_name('Old Identification Number')
OpenMrs_Identification_Number = PatientIdentifierType.find_by_name('OpenMRS Identification Number')

Ancestral_Traditional_Authority = PersonAttributeType.find_by_name('Ancestral Traditional Authority')
Birthplace = PersonAttributeType.find_by_name('Birthplace')
Cell_Phone_Number = PersonAttributeType.find_by_name('Cell Phone Number')
Citizenship = PersonAttributeType.find_by_name('Citizenship')
Current_Place_Of_Residence = PersonAttributeType.find_by_name('Current Place Of Residence')
Health_District = PersonAttributeType.find_by_name('Health District')
Home_Phone_Number = PersonAttributeType.find_by_name('Home Phone Number')
Home_Village = PersonAttributeType.find_by_name('Home Village')
Landmark = PersonAttributeType.find_by_name('Landmark Or Plot Number')
TB_Patient_Contact_ID_Number = PersonAttributeType.find_by_name('MDR-TB Patient Contact ID Number')
Mothers_Maiden_Name = PersonAttributeType.find_by_name("Mother's Maiden Name")
Occupation = PersonAttributeType.find_by_name('Occupation')
Office_Phone_Number = PersonAttributeType.find_by_name('Office Phone Number')
Race = PersonAttributeType.find_by_name('Race')
Treatment_Supporter = PersonAttributeType.find_by_name('Treatment Supporter')

Old_Data = Pat.find(:all,:conditions =>["patient_id <> 1"],:limit => 10000)
User_ID = Old_Data.last.patient_id rescue 0



ART_INITIAL = EncounterType.find_by_name('ART_INITIAL')
HIV_RECEPTION = EncounterType.find_by_name('HIV RECEPTION')
VITALS = EncounterType.find_by_name('VITALS')
HIV_STAGING = EncounterType.find_by_name('HIV STAGING')
ART_VISIT = EncounterType.find_by_name('ART VISIT')
ART_ADHERENCE = EncounterType.find_by_name('ART ADHERENCE')
TREATMENT = EncounterType.find_by_name('TREATMENT')
DISPENSING = EncounterType.find_by_name('DISPENSING')
APPOINTMENT = EncounterType.find_by_name('APPOINTMENT')


OLD_ENCOUNTER_TYPE_IDS = EncType.find(:all,:conditions =>['name IN (?)',['HIV First visit','ART Visit','Give drugs','Date of ART initiation','HIV Staging','HIV Reception','Height/Weight','Update outcome']]).map{| e |e.encounter_type_id}

def self.migrate_data
  puts "All patients: #{Old_Data.length}"
  (Old_Data || []).each do | pat |
    next if pat.patient_id.blank?
    puts ">>>>>>>>>>>> patient id: #{pat.id} creator ::: #{pat.creator}"

    person = Person.new()
    person.person_id = pat.id
    person.creator = self.find_creator(pat.creator)
    person.date_created = pat.date_created
    person.birthdate = pat.birthdate
    person.gender = pat.gender

    if pat.voided
      person.voided = 1
      person.voided_by = self.find_creator(pat.voided_by)
      person.void_reason = pat.void_reason
      person.date_voided = pat.date_voided
    end

    if pat.dead
      person.dead = 1
      person.death_date = pat.death_date
    end
    person.save

    unless pat.birthplace.blank?
      person_attribute = PersonAttribute.new()
      person_attribute.person_id = person.person_id
      person_attribute.value = pat.birthplace
      person_attribute.person_attribute_type_id = Birthplace.id
      person_attribute.creator = self.find_creator(person.creator)
      person_attribute.date_created = person.date_created
      person_attribute.voided = pat.voided
      person_attribute.void_reason = pat.void_reason
      person_attribute.voided_by = self.find_creator(pat.voided_by)
      person_attribute.date_voided = pat.date_voided
      person_attribute.save
    end

    PatAddress.find(:all,:conditions => ["patient_id = ?",pat.patient_id]).each do | patient_address |
      person_attribute = PersonAttribute.new()
      person_attribute.person_id = person.person_id
      person_attribute.value = patient_address.city_village
      person_attribute.person_attribute_type_id = Home_Village.id
      person_attribute.creator = self.find_creator(patient_address.creator)
      person_attribute.date_created = patient_address.date_created
      person_attribute.voided = patient_address.voided
      person_attribute.void_reason = patient_address.void_reason
      person_attribute.voided_by = self.find_creator(patient_address.voided_by)
      person_attribute.date_voided = patient_address.date_voided
      person_attribute.save
    end

    PatName.find(:all,:conditions => ["patient_id = ?",pat.patient_id]).each do | patient_name |
      name = PersonName.new()
      name.given_name = patient_name.given_name
      name.family_name = patient_name.family_name
      name.person_id = person.person_id
      name.creator = self.find_creator(patient_name.creator)
      name.date_created = patient_name.date_created
      name.voided = patient_name.voided
      name.void_reason = patient_name.void_reason
      name.date_voided = patient_name.date_voided
      name.save
    end

    #now from the person object we create the patient object in OpneMRS 1.5
    patient = Patient.new()
    patient.patient_id = person.person_id
    patient.creator = self.find_creator(person.creator)
    patient.date_created = person.date_created
    patient.voided = person.voided
    patient.voided_by = self.find_creator(person.voided_by)
    patient.date_voided = person.date_voided
    patient.void_reason = person.void_reason
    patient.save

     #now we create the patient's identifiers. if the patient does not have any identifiers we skip!
    patient_identifiers = PatIdentifier.find(:all,:conditions =>["patient_id = ?",pat.patient_id])
    (patient_identifiers || []).each do | identifier |
      identifier_name = identifier.name rescue ''
      if identifier_name == 'National id'
        self.identifier_create(pat,identifier,National_ID)
      elsif identifier_name == 'Other name'
        self.person_attribute_create(pat,identifier,Mothers_Maiden_Name)
      elsif identifier_name == 'Occupation'
        self.person_attribute_create(pat,identifier,Occupation)
      elsif identifier_name == 'Cell phone number'
        self.person_attribute_create(pat,identifier,Cell_Phone_Number)
      elsif identifier_name == 'Physical address'
        self.person_attribute_create(pat,identifier,Landmark)
      elsif identifier_name == 'Heard about'
      elsif identifier_name == 'Traditional authority'
        self.person_attribute_create(pat,identifier,Ancestral_Traditional_Authority)
      elsif identifier_name == 'Filing number'
      elsif identifier_name == 'Home phone number'
        self.person_attribute_create(pat,identifier,Home_Phone_Number)
      elsif identifier_name == 'Office phone number'
        self.person_attribute_create(pat,identifier,Office_Phone_Number)
      elsif identifier_name == 'Legacy national id'
      elsif identifier_name == 'Legacy pediatric id'
      elsif identifier_name == 'Arv national id'
        self.identifier_create(pat,identifier,ARV_Number)
      elsif identifier_name == 'Archived filing number'
      elsif identifier_name == 'Legacy Lighthouse ID'
      elsif identifier_name == 'TB treatment ID'
      elsif identifier_name == 'Pre ARV number ID'
      elsif identifier_name == 'Stand alone ARV number ID'
      elsif identifier_name == 'Migrated WHO stage'
      elsif identifier_name == 'New national id'
      elsif identifier_name == 'Nearest Health Clinic'
      elsif identifier_name == 'Previous ARV number'
      end
    end



     art_encounters = ['ART_INITIAL','HIV RECEPTION','VITALS','HIV STAGING','ART VISIT','ART ADHERENCE','TREATMENT','DISPENSING','APPOINTMENT']
     old_art_encounters = ['HIV First visit','ART Visit','Give drugs','Date of ART initiation','HIV Staging','HIV Reception','Height/Weight','Update outcome']

     old_patient_encounters = Enc.find(:all,:conditions => ['patient_id = ? AND encounter_type IN (?)',patient.patient_id,OLD_ENCOUNTER_TYPE_IDS])

     self.creating_encounters(old_patient_encounters)
  end

  end

  def self.creating_encounters(encounters)
    (encounters || []).each do | encounter |
      enc_name = encounter.name rescue ''
      if enc_name == 'HIV First visit'
        self.encounter_observations(ART_INITIAL,encounter,encounter.observations)
      elsif enc_name == 'ART Visit'
        self.encounter_observations(ART_VISIT,encounter,encounter.observations)
      elsif enc_name == 'Give drugs'
      elsif enc_name == 'Date of ART initiation'
      elsif enc_name == 'HIV Staging'
        self.encounter_observations(HIV_STAGING,encounter,encounter.observations)
      elsif enc_name == 'HIV Reception'
        self.encounter_observations(HIV_RECEPTION,encounter,encounter.observations)
      elsif enc_name == 'Height/Weight'
        self.encounter_observations(VITALS,encounter,encounter.observations)
      elsif enc_name == 'Update outcome'
      end
    end
  end

  def self.person_attribute_create(patient,attribute,attribute_type)
    person_attribute = PersonAttribute.new()
    person_attribute.person_id = patient.patient_id
    person_attribute.value = attribute.identifier
    person_attribute.person_attribute_type_id = attribute_type.id
    person_attribute.creator = self.find_creator(attribute.creator)
    person_attribute.date_created = attribute.date_created
    person_attribute.voided = attribute.voided
    person_attribute.void_reason = attribute.void_reason
    person_attribute.voided_by = self.find_creator(attribute.voided_by)
    person_attribute.date_voided = attribute.date_voided
    person_attribute.save
    puts "created attribute: #{attribute.identifier rescue 'Did not save'}" 
  end

  def self.identifier_create(patient,identifier,identifier_type)
    patient_identifier = PatientIdentifier.new()
    patient_identifier.identifier = identifier.identifier
    patient_identifier.identifier_type = identifier_type.id
    patient_identifier.patient_id = patient.patient_id
    patient_identifier.date_created = identifier.date_created
    patient_identifier.voided = identifier.voided
    patient_identifier.void_reason = identifier.void_reason
    patient_identifier.voided_by = self.find_creator(identifier.voided_by)
    patient_identifier.date_voided = identifier.date_voided
    patient_identifier.location_id = identifier.location_id
    patient_identifier.creator = self.find_creator(identifier.creator)
    patient_identifier.save
    puts "created identifier: #{identifier.identifier rescue 'Did not save'}" 
  end

  def self.create_users
    puts "Creating users .........."
    Users.find(:all).each do | user |
      user_id = (user.user_id + User_ID)
      user_exisit = User.find(user_id) rescue []
      next unless user_exisit.blank?
      puts "new user id: #{user_id}"
      person = Person.new()
      person.person_id = user_id
      person.creator = User.current_user.id
      person.date_created = user.date_created
      person.voided = user.voided
      person.save

      name = PersonName.new()
      name.given_name = user.first_name
      name.family_name = user.last_name
      name.person_id = person.person_id
      name.creator = User.current_user.id
      name.date_created = user.date_created
      name.voided = user.voided
      name.save

      user = User.new()
      user.user_id = person.person_id
      user.username = user.username
      user.salt = user.salt
      user.password = user.password
      user.creator = User.current_user.id
      user.date_created = user.date_created
      user.voided = user.voided
      user.save
      puts "Created user, user_id: #{user.user_id}"
    end
  end

  def self.find_creator(user_id)
    return User.find((User_ID + user_id)).id rescue User.current_user.id
  end

  def self.create_locations
     ActiveRecord::Base.connection.execute <<EOF
DELETE FROM program_location_restriction;
EOF

     ActiveRecord::Base.connection.execute <<EOF
DELETE FROM location;
EOF

    puts "creating locations"
    Locations.find(:all).each do | location |
      l = Location.new()
      l.location_id = location.location_id
      l.name = location.name
      l.description = location.description
      l.creator = self.find_creator(location.creator)
      l.date_created = location.date_created
      l.retired = 0
      l.save
      puts "created location: #{l.name}"
    end
  end

end
