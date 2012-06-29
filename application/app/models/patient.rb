class Patient < ActiveRecord::Base
  set_table_name "patient"
  set_primary_key "patient_id"
  include Openmrs

  has_one :person, :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :patient_programs, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :orders, :conditions => {:voided => 0}
  has_many :encounters, :conditions => {:voided => 0} do 
    def find_by_date(encounter_date)
      encounter_date = Date.today unless encounter_date
      find(:all, :conditions => ["DATE(encounter_datetime) = DATE(?)", encounter_date]) # Use the SQL DATE function to compare just the date part
    end
  end

  def after_void(reason = nil)
    self.person.void(reason) rescue nil
    self.patient_identifiers.each {|row| row.void(reason) }
    self.patient_programs.each {|row| row.void(reason) }
    self.orders.each {|row| row.void(reason) }
    self.encounters.each {|row| row.void(reason) }
  end

  def current_diagnoses
    self.encounters.current.all(:include => [:observations]).map{|encounter| 
      encounter.observations.all(
        :conditions => ["obs.concept_id = ? OR obs.concept_id = ?", 
        ConceptName.find_by_name("DIAGNOSIS").concept_id,
        ConceptName.find_by_name("DIAGNOSIS, NON-CODED").concept_id])
    }.flatten.compact
  end

  def current_treatment_encounter(date = Time.now())
    type = EncounterType.find_by_name("TREATMENT")
    encounter = encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= encounters.create(:encounter_type => type.id,:encounter_datetime => date)
  end

  def current_dispensation_encounter(date = Time.now())
    type = EncounterType.find_by_name("DISPENSING")
    encounter = encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= encounters.create(:encounter_type => type.id,:encounter_datetime => date)
  end
    
  def alerts
    # next appt
    # adherence
    # drug auto-expiry
    # cd4 due    
  end
  
  def summary
#    verbiage << "Last seen #{visits.recent(1)}"
    verbiage = []
    verbiage << patient_programs.map{|prog| "Started #{prog.program.name.humanize} #{prog.date_enrolled.strftime('%b-%Y')}" rescue nil }
    verbiage << orders.unfinished.prescriptions.map{|presc| presc.to_s}
    verbiage.flatten.compact.join(', ') 
  end

  def national_id(force = true)
    id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => self).identifier
    id
  end

  def national_id_with_dashes(force = true)
    id = self.national_id(force)
    id[0..4] + "-" + id[5..8] + "-" + id[9..-1] rescue id
  end

  def national_id_label
    return unless self.national_id
    sex =  self.person.gender.match(/F/i) ? "(F)" : "(M)"
    address = self.person.address.strip[0..24].humanize.delete("'") rescue ""
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,5,15,120,false,"#{self.national_id}")
    label.draw_multi_text("#{self.person.name.titleize.delete("'")}") #'
    label.draw_multi_text("#{self.national_id_with_dashes} #{self.person.birthdate_formatted}#{sex}")
    label.draw_multi_text("#{address}")
    label.print(1)
  end
  
  def visit_label(date = Date.today)
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 50
    encs = encounters.find(:all,:conditions =>["DATE(encounter_datetime) = ?",date])
    return nil if encs.blank?
    
    label.draw_multi_text("Visit: #{encs.first.encounter_datetime.strftime("%d/%b/%Y %H:%M")}", :font_reverse => true)    
    encs.each {|encounter|
      next if encounter.name.humanize == "Registration"
      label.draw_multi_text("#{encounter.name.humanize}: #{encounter.to_s}", :font_reverse => false)
    }
    label.print(1)
  end
  
  def get_identifier(type = 'National id')
    identifier_type = PatientIdentifierType.find_by_name(type)
    return if identifier_type.blank?
    identifiers = self.patient_identifiers.find_all_by_identifier_type(identifier_type.id)
    return if identifiers.blank?
    identifiers.map{|i|i.identifier}.join(' , ') rescue nil
  end
  
  def current_weight
    obs = person.observations.recent(1).question("WEIGHT (KG)").all
    obs.first.value_numeric rescue 0
  end
  
  def current_height
    obs = person.observations.recent(1).question("HEIGHT (CM)").all
    obs.first.value_numeric rescue 0
  end
  
  def initial_weight
    obs = person.observations.recent(1).question("WEIGHT (KG)").all
    obs.last.value_numeric rescue 0
  end
  
  def initial_height
    obs = person.observations.recent(1).question("HEIGHT (CM)").all
    obs.last.value_numeric rescue 0
  end

  def initial_bmi
    obs = person.observations.recent(1).question("BMI").all
    obs.last.value_numeric rescue nil
  end

  def min_weight
    WeightHeight.min_weight(person.gender, person.age_in_months).to_f
  end
  
  def max_weight
    WeightHeight.max_weight(person.gender, person.age_in_months).to_f
  end
  
  def min_height
    WeightHeight.min_height(person.gender, person.age_in_months).to_f
  end
  
  def max_height
    WeightHeight.max_height(person.gender, person.age_in_months).to_f
  end
  
  def given_arvs_before?
    self.orders.each{|order|
      drug_order = order.drug_order
      next if drug_order == nil
      next if drug_order.quantity == nil
      next unless drug_order.quantity > 0
      return true if drug_order.drug.arv?
    }
    false
  end

  def name
    "#{self.person.name}"
  end

 def self.dead_with_visits(start_date, end_date)
  national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
  arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
  patient_died_concept    = ConceptName.find_by_name('PATIENT DIED').concept_id

  dead_patients = "SELECT dead_patient_program.patient_program_id,
    dead_state.state, dead_patient_program.patient_id, dead_state.date_changed
    FROM patient_state dead_state INNER JOIN patient_program dead_patient_program
    ON   dead_state.patient_program_id = dead_patient_program.patient_program_id
    WHERE  EXISTS
      (SELECT * FROM program_workflow_state p
        WHERE dead_state.state = program_workflow_state_id AND concept_id = #{patient_died_concept})
          AND dead_state.date_changed >='#{start_date}' AND dead_state.date_changed <= '#{end_date}'"

  living_patients = "SELECT living_patient_program.patient_program_id,
    living_state.state, living_patient_program.patient_id, living_state.date_changed
    FROM patient_state living_state
    INNER JOIN patient_program living_patient_program
    ON living_state.patient_program_id = living_patient_program.patient_program_id
    WHERE  NOT EXISTS
      (SELECT * FROM program_workflow_state p
        WHERE living_state.state = program_workflow_state_id AND concept_id =  #{patient_died_concept})"

  dead_patients_with_observations_visits = "SELECT death_observations.person_id,death_observations.obs_datetime AS date_of_death, active_visits.obs_datetime AS date_living
    FROM obs active_visits INNER JOIN obs death_observations
    ON death_observations.person_id = active_visits.person_id
    WHERE death_observations.concept_id != active_visits.concept_id AND death_observations.concept_id =  #{patient_died_concept} AND death_observations.obs_datetime < active_visits.obs_datetime
      AND death_observations.obs_datetime >='#{start_date}' AND death_observations.obs_datetime <= '#{end_date}'"

  all_dead_patients_with_visits = " SELECT dead.patient_id, dead.date_changed AS date_of_death, living.date_changed
    FROM (#{dead_patients}) dead,  (#{living_patients}) living
    WHERE living.patient_id = dead.patient_id AND dead.date_changed < living.date_changed
    UNION ALL #{dead_patients_with_observations_visits}"

    patients = self.find_by_sql([all_dead_patients_with_visits])
    patients_data  = []
    patients.each do |patient_data_row|
    patient        = Person.find(patient_data_row[:patient_id].to_i)
    national_id    = PatientIdentifier.identifier(patient_data_row[:patient_id], national_identifier_id).identifier rescue ""
    arv_number     = PatientIdentifier.identifier(patient_data_row[:patient_id], arv_number_id).identifier rescue ""
    patients_data <<[patient_data_row[:patient_id], arv_number, patient.name,
                    national_id,patient.gender,patient.age,patient.birthdate, patient.phone_numbers, patient_data_row[:date_changed]]
    end
    patients_data
  end

  def self.males_allegedly_pregnant(start_date, end_date)
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    pregnant_patient_concept_id = ConceptName.find_by_name('PATIENT PREGNANT').concept_id

    patients = PatientIdentifier.find_by_sql(["SELECT person.person_id,obs.obs_datetime
                                   FROM obs INNER JOIN person
                                   ON obs.person_id = person.person_id
                                   WHERE person.gender = 'M' AND
                                   obs.concept_id = ? AND obs.obs_datetime >= ? AND obs.obs_datetime <= ?",
                                    pregnant_patient_concept_id, '2008-12-23 00:00:00', end_date])

    patients_data  = []
    patients.each do |patient_data_row|
    patient        = Person.find(patient_data_row[:person_id].to_i)
    national_id    = PatientIdentifier.identifier(patient_data_row[:person_id], national_identifier_id).identifier rescue ""
    arv_number     = PatientIdentifier.identifier(patient_data_row[:person_id], arv_number_id).identifier rescue ""
    patients_data <<[patient_data_row[:person_id], arv_number, patient.name,
                    national_id,patient.gender,patient.age,patient.birthdate, patient.phone_numbers, patient_data_row[:obs_datetime]]
    end
    patients_data
  end

  def self.with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)

    arv_drugs_concepts      = Drug.arv_drugs.inject([]) {|result, drug| result << drug.concept_id}
    on_arv_concept_id       = ConceptName.find_by_name('ON ANTIRETROVIRALS').concept_id
    hvi_program_id          = Program.find_by_name('HIV PROGRAM').program_id
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id

    patients_on_antiretrovirals_sql = "
         (SELECT p.patient_id, s.date_created as Date_Started_ARV
          FROM patient_program p INNER JOIN patient_state s
          ON  p.patient_program_id = s.patient_program_id
          WHERE s.state IN (SELECT program_workflow_state_id
                            FROM program_workflow_state g
                            WHERE g.concept_id = #{on_arv_concept_id})
                            AND p.program_id = #{hvi_program_id}
         ) patients_on_antiretrovirals"

    antiretrovirals_obs_sql = "
         (SELECT * FROM obs
          WHERE  value_drug IN (SELECT drug_id FROM drug
          WHERE concept_id IN ( #{arv_drugs_concepts.join(', ')} ) )
         ) antiretrovirals_obs"

    drug_start_dates_less_than_program_enrollment_dates_sql= "
      SELECT patients_on_antiretrovirals.patient_id, patients_on_antiretrovirals.date_started_ARV,
             antiretrovirals_obs.obs_datetime, antiretrovirals_obs.value_drug
      FROM #{patients_on_antiretrovirals_sql}, #{antiretrovirals_obs_sql}
      WHERE patients_on_antiretrovirals.Date_Started_ARV > antiretrovirals_obs.obs_datetime
            AND patients_on_antiretrovirals.patient_id = antiretrovirals_obs.person_id
            AND patients_on_antiretrovirals.Date_Started_ARV >='#{start_date}' AND patients_on_antiretrovirals.Date_Started_ARV <= '#{end_date}'"

    patients       = self.find_by_sql(drug_start_dates_less_than_program_enrollment_dates_sql)
    patients_data  = []
    patients.each do |patient_data_row|
    patient     = Person.find(patient_data_row[:patient_id].to_i)
    national_id = PatientIdentifier.identifier(patient_data_row[:patient_id], national_identifier_id).identifier rescue ""
    arv_number  = PatientIdentifier.identifier(patient_data_row[:patient_id], arv_number_id).identifier rescue ""
    patients_data <<[patient_data_row[:patient_id], arv_number, patient.name,
                    national_id,patient.gender,patient.age,patient.birthdate, patient.phone_numbers, patient_data_row[:date_started_ARV]]
    end
    patients_data
  end

  def self.appointment_dates(start_date, end_date = nil)

    end_date = start_date if end_date.nil?

    appointment_date_concept_id = Concept.find_by_name("APPOINTMENT DATE").concept_id rescue nil

    appointments = Patient.find(:all,
                :joins      => 'INNER JOIN obs ON patient.patient_id = obs.person_id',
                :conditions => ["DATE(obs.value_datetime) >= ? AND DATE(obs.value_datetime) <= ? AND obs.concept_id = ? AND obs.voided = 0", start_date.to_date, end_date.to_date, appointment_date_concept_id],
                :group      => "obs.person_id")

    appointments
  end

  def arv_number
    arv_number_id = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    PatientIdentifier.identifier(self.patient_id, arv_number_id).identifier rescue nil
  end

  def age_at_initiation(initiation_date)
    patient = Person.find(self.id)
    return patient.age(initiation_date) unless initiation_date.nil?
  end

  def set_received_regimen(encounter,order)
    dispense_finish = true ; dispensed_drugs_concept_ids = []
    
    ( order.encounter.orders || [] ).each do | order |
      dispense_finish = false if order.drug_order.amount_needed > 0
      dispensed_drugs_concept_ids << Drug.find(order.drug_order.drug_inventory_id).concept_id
    end

    return unless dispense_finish

    regimen_id = ActiveRecord::Base.connection.select_value <<EOF
SELECT concept_id FROM drug_ingredient 
WHERE ingredient_id IN (SELECT distinct ingredient_id 
FROM drug_ingredient 
WHERE concept_id IN (#{dispensed_drugs_concept_ids.join(',')}))
GROUP BY concept_id
HAVING COUNT(*) = (SELECT COUNT(distinct ingredient_id) 
FROM drug_ingredient 
WHERE concept_id IN (#{dispensed_drugs_concept_ids.join(',')}))
EOF
  
    regimen_prescribed = regimen_id.to_i rescue ConceptName.find_by_name('UNKNOWN ANTIRETROVIRAL DRUG').concept_id
    
    if (Observation.find(:first,:conditions => ["person_id = ? AND encounter_id = ? AND concept_id = ?",
        self.id,encounter.id,ConceptName.find_by_name('ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT').concept_id])).blank? 
        regimen_value_text = Concept.find(regimen_prescribed).shortname
        regimen_value_text = ConceptName.find_by_concept_id(regimen_prescribed).name if regimen_value_text.blank?
      obs = Observation.new(
        :concept_name => "ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT",
        :person_id => self.id,
        :encounter_id => encounter.id,
        :value_text => regimen_value_text,
        :value_coded => regimen_prescribed,
        :obs_datetime => encounter.encounter_datetime)
      obs.save
      return obs.value_text 
    end
 end

  def gender
    self.person.sex
  end

  def last_art_visit_before(date = Date.today)
    art_encounters = ['ART_INITIAL','HIV RECEPTION','VITALS','HIV STAGING','ART VISIT','ART ADHERENCE','TREATMENT','DISPENSING']
    art_encounter_type_ids = EncounterType.find(:all,:conditions => ["name IN (?)",art_encounters]).map{|e|e.encounter_type_id}
    Encounter.find(:first,
                   :conditions => ["DATE(encounter_datetime) < ? AND patient_id = ? AND encounter_type IN (?)",date,
                   self.id,art_encounter_type_ids],
                   :order => 'encounter_datetime DESC').encounter_datetime.to_date rescue nil
  end
  
  def drug_given_before(date = Date.today)
    encounter_type = EncounterType.find_by_name('TREATMENT')
    Encounter.find(:first,
               :joins => 'INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
               INNER JOIN drug_order ON orders.order_id = orders.order_id', 
               :conditions => ["quantity IS NOT NULL AND encounter_type = ? AND 
               encounter.patient_id = ? AND DATE(encounter_datetime) < ?",
               encounter_type.id,self.id,date.to_date],:order => 'encounter_datetime DESC').orders rescue []
  end

  def prescribe_arv_this_visit(date = Date.today)
    encounter_type = EncounterType.find_by_name('ART VISIT')
    yes_concept = ConceptName.find_by_name('YES').concept_id
    refer_concept = ConceptName.find_by_name('PRESCRIBE ARVS THIS VISIT').concept_id
    refer_patient = Encounter.find(:first,
               :joins => 'INNER JOIN obs USING (encounter_id)', 
               :conditions => ["encounter_type = ? AND concept_id = ? AND person_id = ? AND value_coded = ? AND DATE(obs_datetime) = ?",
               encounter_type.id,refer_concept,self.id,yes_concept,date.to_date],:order => 'encounter_datetime DESC')
    return false if refer_patient.blank?
    return true
  end

  def number_of_days_to_add_to_next_appointment_date(date = Date.today)
    #because a dispension/pill count can have several drugs,we pick the drug with the lowest pill count
    #and we also make sure the drugs in the pill count/Adherence encounter are the same as the one in Dispension encounter
    
    concept_id = ConceptName.find_by_name('AMOUNT OF DRUG BROUGHT TO CLINIC').concept_id
    encounter_type = EncounterType.find_by_name('ART ADHERENCE')
    adherence = Observation.find(:all,
                :joins => 'INNER JOIN encounter USING(encounter_id)',
                :conditions =>["encounter_type = ? AND patient_id = ? AND concept_id = ? AND DATE(encounter_datetime)=?",
                encounter_type.id,self.id,concept_id,date.to_date],:order => 'encounter_datetime DESC')
    return 0 if adherence.blank?
    concept_id = ConceptName.find_by_name('AMOUNT DISPENSED').concept_id
    encounter_type = EncounterType.find_by_name('DISPENSING')
    drug_dispensed = Observation.find(:all,
                     :joins => 'INNER JOIN encounter USING(encounter_id)',
                     :conditions =>["encounter_type = ? AND patient_id = ? AND concept_id = ? AND DATE(encounter_datetime)=?",
                     encounter_type.id,self.id,concept_id,date.to_date],:order => 'encounter_datetime DESC')

    #check if what was dispensed is what was counted as remaing pills
    return 0 unless (drug_dispensed.map{| d | d.value_drug } - adherence.map{|a|a.order.drug_order.drug_inventory_id}) == []
   
    #the folliwing block of code picks the drug with the lowest pill count
    count_drug_count = []
    (adherence).each do | adh |
      unless count_drug_count.blank?
        if adh.value_numeric < count_drug_count[1]
          count_drug_count = [adh.order.drug_order.drug_inventory_id,adh.value_numeric]
        end
      end
      count_drug_count = [adh.order.drug_order.drug_inventory_id,adh.value_numeric] if count_drug_count.blank?
    end

    #from the drug dispensed on that day,we pick the drug "plus it's daily dose" that match the drug with the lowest pill count    
    equivalent_daily_dose = 1
    (drug_dispensed).each do | dispensed_drug |
      drug_order = dispensed_drug.order.drug_order
      if count_drug_count[0] == drug_order.drug_inventory_id
        equivalent_daily_dose = drug_order.equivalent_daily_dose
      end
    end
    (count_drug_count[1] / equivalent_daily_dose).to_i
  end

  def female_adult?
    (gender == "Female" && self.person.age > 9) ? true : false
  end

  def pregnancy_status
    pregnancy_statuses  = Encounter.get_pregnancy_statuses(self.id)
    current_status      = nil
    status_date         = nil

    unless pregnancy_statuses.nil?
      pregnancy_statuses.last.observations.each do | observation|
        current_status  = observation.answer_string if(observation.concept.name == "PREGNANCY STATUS")
      end
    end
    unless current_status.nil?
      pregnancy_statuses.last.observations.each do | observation|
        status_date     = observation.answer_string if(observation.concept.name == "EXPECTED DUE DATE" || observation.concept.name =="DELIVERY DATE")
      end
    end

    return [current_status, status_date]
  end

  def create_ivr_access_code(force = true)
    id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("IVR Access Code").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("IVR Access Code").next_identifier(:patient => self).identifier
    id
  end

  def ivr_access_code
    create_ivr_access_code(force = true)
  end

  def create_national_id(force = true)
    id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => self).identifier
    id
  end

  def male_adult?
    (gender == "Male" && self.person.age > 5) ? true : false
  end

  def child_danger_signs
    symptoms_obs = Hash.new
  	recorded_danger_signs = Array.new
 
  	danger_signs = ["FEVER OF 7 DAYS OR MORE","DIARRHEA FOR 14 DAYS OR MORE",
					"COUGH FOR 21 DAYS OR MORE", "CONVULSIONS SIGN","BLOOD IN STOOL",
					"NOT EATING OR DRINKING ANYTHING","VOMITING EVERYTHING",
 					"RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS",
 					"RED EYE", "UNCONSCIOUS","FLAKY SKIN","SWOLLEN HANDS OR FEET SIGN"]
 					
 	type = EncounterType.find_by_name("CHILD HEALTH SYMPTOMS")
    encounter = self.encounters.current.find(:first, :conditions =>["encounter_type = ?",type.id])

    encounter.observations.all.each{|obs|
      symptoms_obs[obs.to_s.split(':')[0].strip] = obs.to_s.split(':')[1].strip}  rescue nil

  return get_child_symptoms(symptoms_obs,"Danger")
  
  end
  
  def child_symptoms
  	symptoms_obs = Hash.new
  	recorded_symptoms = Array.new
 
  	symptoms = ["FEVER", "DIARRHEA", "COUGH", "CONVULSIONS", "NOT EATING OR DRINKING ANYTHING", 
  		    "RED EYE", "VERY SLEEPY OR UNCONSCIOUS","WEIGHT CHANGE"]
 					
    encounter = self.encounters.current.find(:first, 
                                             :conditions =>["encounter_type = ?",
                                             EncounterType.find_by_name("CHILD HEALTH SYMPTOMS").id])

    encounter.observations.all.each{|obs| symptoms_obs[obs.to_s.split(':')[0].strip] = obs.to_s.split(':')[1].strip} rescue nil 

   return get_child_symptoms(symptoms_obs,"Symptom")
  end

  def female_danger_signs
    symptoms_obs = Array.new
  	recorded_danger_signs = Array.new

  	danger_signs =  ['HEAVY VAGINAL BLEEDING DURING PREGNANCY',
                    'EXCESSIVE POSTNATAL BLEEDING',
                    'FEVER DURING PREGNANCY SIGN',
                    'POSTNATAL FEVER SIGN',
                    'SEVERE HEADACHE',
                    'FITS OR CONVULSIONS SIGN',
                    'SWOLLEN HANDS OR FEET SIGN',
                    'PALENESS OF THE SKIN AND TIREDNESS SIGN',
                    'NO FETAL MOVEMENTS SIGN',
                    'WATER BREAKS SIGN']

 	type = EncounterType.find_by_name("MATERNAL HEALTH SYMPTOMS")
    encounter = self.encounters.current.find(:first,
                  :conditions =>["encounter_type = ?",type.id])

    encounter.observations.all.each{|obs| 
      symptoms_obs << obs.name_to_s}  rescue nil

  return get_female_symptoms(symptoms_obs,"Danger")

  end

  def female_symptoms
    symptoms_obs = Array.new
  	recorded_symptoms = Array.new

  	danger_signs =  ['VAGINAL BLEEDING DURING PREGNANCY',
                    'POSTNATAL BLEEDING',
                    'FEVER DURING PREGNANCY SYMPTOM',
                    'POSTNATAL FEVER SYMPTOM',
                    'HEADACHES',
                    'FITS OR CONVULSIONS SYMPTOM',
                    'SWOLLEN HANDS OR FEET SYMPTOM',
                    'PALENESS OF THE SKIN AND TIREDNESS SYMPTOM']

 	type = EncounterType.find_by_name("MATERNAL HEALTH SYMPTOMS")
    encounter = self.encounters.current.find(:first, :conditions =>["encounter_type = ?",type.id])

    encounter.observations.all.each{|obs|
      symptoms_obs << obs.name_to_s}  rescue nil

  return get_female_symptoms(symptoms_obs,"Symptom")

  end
  
  def get_child_symptoms(sign, type)
  danger_signs = []
  health_information = []
  health_symptoms = []
  return_value = "No"
  required_tags = ConceptNameTag.find(:all,
                                          :select => "concept_name_tag_id",
                                          :conditions => ["tag IN ('DANGER SIGN', 'HEALTH INFORMATION', 'HEALTH SYMPTOM')"]
                                          ).map(&:concept_name_tag_id)
      #raise symptoms_obs.to_yaml
     if not sign.blank?
      sign.each do |symptom|
        if symptom[0].upcase != "CALL ID" || symptom[0].upcase != "SEVERITY OF COUGH" ||
           symptom[0].upcase != "SEVERITY OF FEVER" || symptom[0].upcase != "SEVERITY OF DIARRHEA" ||
           symptom[0].upcase != "SEVERITY OF RED EYE"

           if symptom[1].upcase == "YES"
           
              if symptom[0].downcase == "skin dryness" || symptom[0] == "skin dry" || symptom[0] == "skindryness"
                actual_symptom = "Flaky skin"
                symptom[0] = "Dry Skin"
              else
                actual_symptom = symptom[0]
              end
             
              name_tag_id = ConceptNameTagMap.find(:all,
                                                    :joins => "INNER JOIN concept_name
                                                              ON concept_name.concept_name_id = concept_name_tag_map.concept_name_id ",
                                                    :conditions =>["concept_name.concept_id = ?",                                                   
#                                                      concept_name_tag_map.concept_name_tag_id IN (?)",
                                                      ConceptName.find_by_name(actual_symptom).concept_id],
#                                                      required_tags ],
                                                    :select => "concept_name_tag_id",
                                                    :order => "concept_name_tag_map.concept_name_tag_id ASC"
                                                   ).last

            symptom_type = ConceptNameTag.find(:all,
                                                  :conditions =>["concept_name_tag_id = ?", name_tag_id.concept_name_tag_id],
                                                  :select => "tag"
                                                  ).uniq #rescue nil #to check this
                if not symptom_type.nil?
                symptom_type.each{|symptom_tag|
                  if symptom_tag.tag == "HEALTH INFORMATION"
                    health_information << symptom[0]
                  elsif symptom_tag.tag == "DANGER SIGN"
                    danger_signs << symptom[0]
                  elsif symptom_tag.tag == "HEALTH SYMPTOM"
                    health_symptoms << symptom[0] 
                  end
                }
                end
           end #-
      end #-
    end 
    end 
    if type == "Danger"
      if danger_signs.length != 0
        return_value = "Yes"
      end
    elsif type == "Symptom"
      if health_symptoms.length != 0
        return_value = "Yes"
      end
    end
    
    return return_value
  end
  
  def get_female_symptoms(sign, type)
  danger_signs = []
  health_information = []
  health_symptoms = []
  return_value = "No"
     
    sign.each {|obs|
          if obs.to_s.downcase != "call id"
            sign_id = Concept.find_by_name(obs).concept_id
            name_tag_id = ConceptNameTagMap.find(:all,
                                                  :joins => "INNER JOIN concept_name
                                                            ON concept_name.concept_name_id = concept_name_tag_map.concept_name_id ",
                                                  :conditions =>["concept_name.concept_id = ?", sign_id],
                                                  :select => "concept_name_tag_id"
                                                 ).last

             symptom_type = ConceptNameTag.find(:all,
                                                :conditions =>["concept_name_tag_id = ?", name_tag_id.concept_name_tag_id],
                                                :select => "tag"
                                                ).uniq

            symptom_type.each{|symptom|
              if symptom.tag == "HEALTH INFORMATION"
                health_information << obs
              elsif symptom.tag == "DANGER SIGN"
                danger_signs << obs
              elsif symptom.tag == "HEALTH SYMPTOM"
                health_symptoms << obs
              end
            }
          end
    }
        
        if type == "Danger"
          if danger_signs.length != 0
            return_value = "Yes"
          end
        elsif type == "Symptom"
          if health_symptoms.length != 0
            return_value = "Yes"
          end
        end
    
    return return_value
  end
  
end