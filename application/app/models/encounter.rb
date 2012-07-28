class Encounter < ActiveRecord::Base
  set_table_name :encounter
  set_primary_key :encounter_id
  include Openmrs
  has_many :observations, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :drug_orders,  :through   => :orders,  :foreign_key => 'order_id'
  has_many :orders, :dependent => :destroy, :conditions => {:voided => 0}
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type, :conditions => {:retired => 0}
  belongs_to :provider, :class_name => "User", :foreign_key => :provider_id, :conditions => {:voided => 0}
  belongs_to :patient, :conditions => {:voided => 0}

  # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
  named_scope :current, :conditions => 'DATE(encounter.encounter_datetime) = CURRENT_DATE()'

  def before_save    
    self.provider = User.current_user if self.provider.blank?
    # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
    self.encounter_datetime = Time.now if self.encounter_datetime.blank?
  end

  def after_void(reason = nil)
    self.orders.each{|row| Pharmacy.voided_stock_adjustment(order) if row.order_type_id == 1 } rescue []
    self.observations.each{|row| row.void(reason) } rescue []
    self.find_by_sql("SELECT * FROM encounter ORDER BY encounter_datetime DESC LIMIT 1").orders.each{|row| row.void(reason) } rescue []
  end

  def encounter_type_name=(encounter_type_name)
    self.type = EncounterType.find_by_name(encounter_type_name)
    raise "#{encounter_type_name} not a valid encounter_type" if self.type.nil?
  end

  def self.initial_encounter
    self.find_by_sql("SELECT * FROM encounter ORDER BY encounter_datetime LIMIT 1").first
  end

  def voided_observations
    voided_obs = Observation.find_by_sql("SELECT * FROM obs WHERE obs.encounter_id = #{self.encounter_id} AND obs.voided = 1")
    (!voided_obs.empty?) ? voided_obs : nil
  end

  def voided_orders
    voided_orders = Order.find_by_sql("SELECT * FROM orders WHERE orders.encounter_id = #{self.encounter_id} AND orders.voided = 1")
    (!voided_orders.empty?) ? voided_orders : nil
  end

  def name
    self.type.name rescue "N/A"
  end

  def to_s
    if name == 'REGISTRATION'
      "Patient was seen at the registration desk at #{encounter_datetime.strftime('%I:%M')}" 
    elsif name == 'TREATMENT'
      o = orders.collect{|order| order.to_s}.join("\n")
      o = "No prescriptions have been made" if o.blank?
      o
    elsif name == 'VITALS'
      temp = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("TEMPERATURE (C)") && "#{obs.answer_string}".upcase != 'UNKNOWN' }
      weight = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("WEIGHT (KG)") && "#{obs.answer_string}".upcase != '0.0' }
      height = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("HEIGHT (CM)") && "#{obs.answer_string}".upcase != '0.0' }
      vitals = [weight_str = weight.first.answer_string + 'KG' rescue 'UNKNOWN WEIGHT',
                height_str = height.first.answer_string + 'CM' rescue 'UNKNOWN HEIGHT']
      temp_str = temp.first.answer_string + '°C' rescue nil
      vitals << temp_str if temp_str                          
      vitals.join(', ')
    elsif name == 'MATERNAL HEALTH SYMPTOMS' || name == "CHILD HEALTH SYMPTOMS"
      danger_signs = []
      health_information = []
      health_symptoms = []
      symptoms_obs = Hash.new
      return_string = ""
      if name == "MATERNAL HEALTH SYMPTOMS"
        for obs in observations do
          if obs.name_to_s != "Call ID"
            name_tag_id = ConceptNameTagMap.find(:all,
                                                  :joins => "INNER JOIN concept_name
                                                            ON concept_name.concept_name_id = concept_name_tag_map.concept_name_id ",
                                                  :conditions =>["concept_name.concept_id = ?", obs.concept_id],
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
      else
        observations.all.each{|obs|
          symptoms_obs[obs.to_s.split(':')[0].strip] = obs.to_s.split(':')[1].strip
        } rescue nil
      end
      
      required_tags = ConceptNameTag.find(:all,
                                          :select => "concept_name_tag_id",
                                          :conditions => ["tag IN ('DANGER SIGN', 'HEALTH INFORMATION', 'HEALTH SYMPTOM')"]
                                          ).map(&:concept_name_tag_id)
      
      symptoms_obs.each do |symptom|
        if symptom[0].upcase != "CALL ID" || symptom[0].upcase != "SEVERITY OF COUGH" ||
           symptom[0].upcase != "SEVERITY OF FEVER" || symptom[0].upcase != "SEVERITY OF DIARRHEA" ||
           symptom[0].upcase != "SEVERITY OF RED EYE"

           if symptom[1].upcase == "YES"
              name_tag_id = ConceptNameTagMap.find(:all,
                                                    :joins => "INNER JOIN concept_name
                                                              ON concept_name.concept_name_id = concept_name_tag_map.concept_name_id ",
                                                    :conditions =>["concept_name.concept_id = ? AND                                                   
                                                      concept_name_tag_map.concept_name_tag_id IN (?)",
                                                      ConceptName.find_by_name(symptom[0]).concept_id,
                                                      required_tags ],
                                                    :select => "concept_name_tag_id"
                                                   ).last
                

               symptom_type = ConceptNameTag.find(:all,
                                                  :conditions =>["concept_name_tag_id = ?", name_tag_id.concept_name_tag_id],
                                                  :select => "tag"
                                                  ).uniq rescue nil
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

      return return_string
      
    elsif name == 'TIPS AND REMINDERS'
       observations.collect{|observation| observation.to_s_with_bold_name}.join(", ")
    else
      #changed the line below, from observation.answer_string to observation.to_s
      observations.collect{|observation| observation.to_s_with_bold_name}.join(", ")
    end  
  end

  def self.count_by_type_for_date(date)  
    # This query can be very time consuming, because of this we will not consider
    # that some of the encounters on the specific date may have been voided
    ActiveRecord::Base.connection.select_all("SELECT count(*) as number, encounter_type FROM encounter GROUP BY encounter_type")
    todays_encounters = Encounter.find(:all, :include => "type", :conditions => ["DATE(encounter_datetime) = ?",date])
    encounters_by_type = Hash.new(0)
    todays_encounters.each{|encounter|
      next if encounter.type.nil?
      encounters_by_type[encounter.type.name] += 1
    }
    encounters_by_type
  end

  def self.statistics(encounter_types, opts={})
    encounter_types = EncounterType.all(:conditions => ['name IN (?)', encounter_types])
    encounter_types_hash = encounter_types.inject({}) {|result, row| result[row.encounter_type_id] = row.name; result }
    with_scope(:find => opts) do
      rows = self.all(
         :select => 'count(*) as number, encounter_type', 
         :group => 'encounter.encounter_type',
         :conditions => ['encounter_type IN (?)', encounter_types.map(&:encounter_type_id)]) 
      return rows.inject({}) {|result, row| result[encounter_types_hash[row['encounter_type']]] = row['number']; result }
    end     
  end

  def self.visits_by_day(start_date,end_date)
    required_encounters = ["ART ADHERENCE", "ART_FOLLOWUP",   "ART_INITIAL",
                           "ART VISIT",     "HIV RECEPTION",  "HIV STAGING",
                           "PART_FOLLOWUP", "PART_INITIAL",   "VITALS"]

    required_encounters_ids = required_encounters.inject([]) do |encounters_ids, encounter_type|
      encounters_ids << EncounterType.find_by_name(encounter_type).id rescue nil
      encounters_ids
    end

    required_encounters_ids.sort!

    Encounter.find(:all,
      :joins      => ["INNER JOIN obs     ON obs.encounter_id    = encounter.encounter_id",
                      "INNER JOIN patient ON patient.patient_id  = encounter.patient_id"],
      :conditions => ["obs.voided = 0 AND encounter_type IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",required_encounters_ids,start_date,end_date],
      :group      => "encounter.patient_id,DATE(encounter_datetime)",
      :order      => "encounter.encounter_datetime ASC")
  end

  def self.create(params, session_datetime = nil)
    encounter = Encounter.new(params)
    encounter.encounter_datetime = session_datetime unless session_datetime.blank?
    encounter.save
    encounter
  end

  def self.show_encounter_types
    types = GlobalProperty.find_by_property("statistics.show_encounter_types").property_value rescue EncounterType.all.map(&:name).join(", ")
    types = types.split(", ")
  end

  def self.get_pregnancy_statuses(patient_id)
    pregnancy_statuses = self.all(
              :conditions => ["encounter.encounter_type = ? and encounter.voided = ? and patient_id = ?",
                  EncounterType.find_by_name('PREGNANCY STATUS').encounter_type_id, 0, patient_id],
              :include => [:observations]
            )

    pregnancy_statuses
  end

  def self.get_previous_symptoms(patient_id)
    previous_symptoms = self.all(
              :conditions => ["(encounter.encounter_type = ? or encounter.encounter_type = ?) and encounter.voided = ? and patient_id = ?",
                  EncounterType.find_by_name('MATERNAL HEALTH SYMPTOMS').encounter_type_id, EncounterType.find_by_name('CHILD HEALTH SYMPTOMS').encounter_type_id, 0, patient_id],
              :include => [:observations]
            )

    return previous_symptoms
  end

  def self.get_previous_encounters(patient_id)
    previous_encounters = self.all(
              :conditions => ["encounter.voided = ? and patient_id = ?", 0, patient_id],
              :include => [:observations]
            )
    return previous_encounters
  end

  def self.get_recent_calls(patient_id)
    recent_encounters = get_previous_encounters(patient_id)
    call_list = Array.new
    search_id = Concept.find_by_name("CALL ID").concept_id
    for encounter in recent_encounters do
      for obs in encounter.observations do
        if obs.concept_id == search_id
          call_list << obs.value_text
        end
      end
    end

    return call_list
  end

  def self.get_previous_tips_and_reminders(patient_id)
   previous_tips_and_reminders = self.all(
              :conditions => ["encounter.encounter_type = ? and encounter.voided = ? and patient_id = ?",
                  EncounterType.find_by_name('TIPS AND REMINDERS ').encounter_type_id, 0, patient_id],
              :include => [:observations]
            )

   return previous_tips_and_reminders
  end

  def self.retrieve_previous_encounter(encounter_id)
    encounter = Encounter.find(encounter_id)

    case encounter.name
      when "CHILD HEALTH SYMPTOMS", "MATERNAL HEALTH SYMPTOMS"
        values_hash = health_symptoms_values(encounter)
      when "PREGNANCY STATUS", "TIPS AND REMINDERS", "UPDATE OUTCOME"
        values_hash = standard_encounter_values(encounter)
      else
        values_hash = {}
    end

    return values_hash
  end

  def self.health_symptoms_values(encounter)
    # child health symptoms
    child_health_symptoms = {:health_symptoms => ["FEVER", "DIARRHEA", "COUGH",
                                              "CONVULSIONS SYMPTOM", "NOT EATING",
                                              "VOMITING", "RED EYE", "FAST BREATHING",
                                              "VERY SLEEPY", "UNCONSCIOUS"],
                            :danger_warning_signs => ["FEVER OF 7 DAYS OR MORE","DIARRHEA FOR 14 DAYS OR MORE",
                                        "BLOOD IN STOOL", "COUGH FOR 21 DAYS OR MORE", "CONVULSIONS SIGN",
                                        "NOT EATING OR DRINKING ANYTHING", "VOMITING EVERYTHING",
                                        "RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS",
                                        "VERY SLEEPY OR UNCONSCIOUS", "POTENTIAL CHEST INDRAWING"],
                            :health_info => ["SLEEPING", "FEEDING PROBLEMS", "CRYING",
                                        "BOWEL MOVEMENTS", "SKIN RASHES", "SKIN INFECTIONS",
                                        "UMBILICUS INFECTION", "GROWTH MILESTONES",
                                        "ACCESSING HEALTHCARE SERVICES"]
                        }

    #maternal_health_symptoms
    maternal_health_symptoms = {:health_symptoms => ["VAGINAL BLEEDING DURING PREGNANCY", "POSTNATAL BLEEDING",
                                        "FEVER DURING PREGNANCY SYMPTOM", "POSTNATAL FEVER SYMPTOM",
                                        "HEADACHES", "FITS OR CONVULSIONS SYMPTOM", "SWOLLEN HANDS OR FEET SYMPTOM",
                                        "PALENESS OF THE SKIN AND TIREDNESS SYMPTOM", "NO FETAL MOVEMENTS SYMPTOM",
                                        "WATER BREAKS SYMPTOM"],
                              :danger_warning_signs => ["HEAVY VAGINAL BLEEDING DURING PREGNANCY",
                                        "EXCESSIVE POSTNATAL BLEEDING","FEVER DURING PREGNANCY SIGN", "POSTNATAL FEVER SIGN",
                                        "SEVERE HEADACHE", "FITS OR CONVULSIONS SIGN", "SWOLLEN HANDS OR FEET SIGN",
                                        "PALENESS OF THE SKIN AND TIREDNESS SIGN", "NO FETAL MOVEMENTS SIGN", "WATER BREAKS SIGN"],
                              :health_info => ["HEALTHCARE VISITS","NUTRITION","BODY CHANGES",
                                        "DISCOMFORT","CONCERNS","EMOTIONS","WARNING SIGNS",
                                        "ROUTINES","BELIEFS","BABY'S GROWTH","MILESTONES","PREVENTION"]
                        }

    encounter.name == "CHILD HEALTH SYMPTOMS" ? health_symptoms = child_health_symptoms : health_symptoms = maternal_health_symptoms

    observations        = encounter.observations.map{|obs| [obs.concept.name, obs.answer_string] } rescue nil
    observation_names   = []
    observation_answers = []

    observations.map do |concept, value|
      observation_names   << concept
      observation_answers << value
    end

    values_string = {:health_symptoms => nil, :danger_warning_signs => nil, :health_info => nil }

    observation_names.map do |value|
      if health_symptoms[:health_symptoms].include? value
        (values_string[:health_symptoms].nil?) ? (values_string[:health_symptoms] = [value]) : (values_string[:health_symptoms].push value)
      elsif health_symptoms[:danger_warning_signs].include? value
        (values_string[:danger_warning_signs].nil?) ? (values_string[:danger_warning_signs] = [value]) : (values_string[:danger_warning_signs].push value)
      elsif health_symptoms[:health_info].include? value
        (values_string[:health_info].nil?) ? (values_string[:health_info] = [value]) : (values_string[:health_info].push value)
      end
    end

    values_string
  end

  def self.standard_encounter_values(encounter)
    values_string = {}

    observations  = encounter.observations.map{|obs| [obs.concept.name, obs.answer_string] } rescue nil

    unless observations.nil?
      observations.map do |obs_name, value|
          values_string[obs_name.downcase.gsub(' ','_').to_sym] = value
      end
    end

    values_string
  end

end
