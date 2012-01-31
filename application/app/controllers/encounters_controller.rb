class EncountersController < ApplicationController

  def create

    Encounter.find(params[:encounter_id].to_i).void if(params[:editing] && params[:encounter_id])

    if params['encounter']['encounter_type_name'] == 'ART_INITIAL'
      if params[:observations][0]['concept_name'] == 'EVER RECEIVED ART' and params[:observations][0]['value_coded_or_text'] == 'NO'
        observations = []
        (params[:observations] || []).each do |observation|
          next if observation['concept_name'] == 'HAS TRANSFER LETTER'
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          next if observation['concept_name'] == 'ART NUMBER AT PREVIOUS LOCATION'
          next if observation['concept_name'] == 'DATE ART LAST TAKEN'
          next if observation['concept_name'] == 'LAST ART DRUGS TAKEN'
          observations << observation
        end
      elsif params[:observations][4]['concept_name'] == 'DATE ART LAST TAKEN' and params[:observations][4]['value_datetime'] != 'Unknown'
        observations = []
        (params[:observations] || []).each do |observation|
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO WEEKS'
          next if observation['concept_name'] == 'HAS THE PATIENT TAKEN ART IN THE LAST TWO MONTHS'
          observations << observation
        end
      end
      params[:observations] = observations unless observations.blank?
    end
    
    @patient = Patient.find(params[:encounter][:patient_id])

    #we have to void the previous Tips and reminders encounters
    if params['encounter']['encounter_type_name'] == 'TIPS AND REMINDERS'
      if session[:house_keeping_mode] == true;
        tips_encounters = Encounter.find(:all,
           :conditions => ["patient_id = ? AND encounter_type = ? AND voided = 0",
                           params[:encounter][:patient_id],
                         EncounterType.find_by_name('TIPS AND REMINDERS').id])
        unless tips_encounters.blank?
          tips_encounters.each do |encounter|
            encounter.void('editing tips and and reminders')
          end
        end
      end
    end

    # Go to the dashboard if this is a non-encounter
    redirect_to "/patients/show/#{@patient.id}" unless params[:encounter]

    encounter               = nil
    this_encounter          = params[:encounter][:encounter_type_name]
    exceptional_encounters  = ["REGISTRATION"]
    
	current_observations = nil;
    # added this to append the call id observation the list of observaations
	if params[:observations] != nil
    	current_observations = params[:observations]
	else
		current_observations = []
	end

   	new_observation = {"patient_id"=> "#{@patient.id}", "concept_name" => "CALL ID", "obs_datetime" => "#{DateTime.now()}", "value_coded_or_text" => "#{session[:call_id]}"}
    current_observations << new_observation

    params[:observations] = current_observations
 
    # Handling exceptional encounters i.e. that do not necessarily need observations such as Registration
    encounter = Encounter.create(params[:encounter], session[:datetime]) if (exceptional_encounters.include? this_encounter)

    # Observation handling
    (params[:observations] || []).each do |observation|

      # Check to see if any values are part of this observation
      # This keeps us from saving empty observations
      values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map{|value_name|
        observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
      }.compact

      next if values.length == 0

      # Create an encounter if the obsevations are not empty
      # This keeps us from saving empty encounters
      encounter.nil? ? (encounter = Encounter.create(params[:encounter], session[:datetime])) : (encounter = Encounter.find(encounter.id))

      observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
      observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
      observation[:encounter_id] = encounter.id
      observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
      observation[:person_id] ||= encounter.patient_id
      observation[:concept_name] ||= "DIAGNOSIS" if encounter.type.name == "DIAGNOSIS"
      # Handle multiple select
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
        observation[:value_coded_or_text_multiple].compact!
        observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
      end  
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
        values = observation.delete(:value_coded_or_text_multiple)
        values.each{|value| observation[:value_coded_or_text] = value; Observation.create(observation) }
      else      
        observation.delete(:value_coded_or_text_multiple)
        Observation.create(observation)
      end
    end

    # Program handling
    date_enrolled = params[:programs][0]['date_enrolled'].to_time rescue nil
    date_enrolled = session[:datetime] || Time.now() if date_enrolled.blank?
    (params[:programs] || []).each do |program|
      # Look up the program if the program id is set      
      @patient_program = PatientProgram.find(program[:patient_program_id]) unless program[:patient_program_id].blank?
      # If it wasn't set, we need to create it
      unless (@patient_program)
        @patient_program = @patient.patient_programs.create(
          :program_id => program[:program_id],
          :date_enrolled => date_enrolled)          
      end
      # Lots of states bub
      unless program[:states].blank?
        #adding program_state start date
        program[:states][0]['start_date'] = date_enrolled
      end
      (program[:states] || []).each {|state| @patient_program.transition(state) }
    end

    # Identifier handling
    arv_number_identifier_type = PatientIdentifierType.find_by_name('ARV Number').id
    (params[:identifiers] || []).each do |identifier|
      # Look up the identifier if the patient_identfier_id is set      
      @patient_identifier = PatientIdentifier.find(identifier[:patient_identifier_id]) unless identifier[:patient_identifier_id].blank?
      # Create or update
      type = identifier[:identifier_type].to_i rescue nil
      unless (arv_number_identifier_type != type) and @patient_identifier
        arv_number = identifier[:identifier].strip
        if arv_number.match(/(.*)[A-Z]/i).blank?
          identifier[:identifier] = "#{Location.current_arv_code} #{arv_number}"
        end
      end

      if @patient_identifier
        @patient_identifier.update_attributes(identifier)      
      else
        @patient_identifier = @patient.patient_identifiers.create(identifier)
      end
    end

    session[:mnch_protocol_required]  = true if (encounter && (encounter.name == "PREGNANCY STATUS" || encounter.name == "CHILD HEALTH SYMPTOMS"))
    if (encounter && encounter.name == "UPDATE OUTCOME" && params["select_outcome"] == "REFERRED TO A HEALTH CENTRE")
      session[:outcome_complete]  = true
      session[:health_facility]   = params["health_center"]
    end

    # Go to the next task in the workflow (or dashboard)
    redirect_to next_task(@patient) 
  end

  def new
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    @child_danger_signs = @patient.child_danger_signs
    @child_symptoms = @patient.child_symptoms
    @select_options = select_options
    @phone_numbers = patient_reminders_phone_number(@patient)

    # created a hash of 'upcased' health centers
    @health_facilities = ([""] + ClinicSchedule.health_facilities.map(&:name)).inject([]) do |facility_list, facilities|
      facility_list.push(facilities)
    end

    @tips_and_reminders_enrolled_in = type_of_reminder_enrolled_in(@patient)

    use_regimen_short_names = GlobalProperty.find_by_property(
      "use_regimen_short_names").property_value rescue "false"
    show_other_regimen = GlobalProperty.find_by_property(
      "show_other_regimen").property_value rescue 'false'

    @answer_array = arv_regimen_answers(:patient => @patient,
      :use_short_names    => use_regimen_short_names == "true",
      :show_other_regimen => show_other_regimen      == "true")
    redirect_to "/" and return unless @patient

    @encounter_answers  = {}
    (!params[:encounter_id].blank?) ? (@encounter_id = params[:encounter_id].to_i) : (@encounter_id = nil)
    @encounter_answers  = Encounter.retrieve_previous_encounter(@encounter_id) unless @encounter_id.nil?

    redirect_to next_task(@patient) and return unless params[:encounter_type]

    redirect_to :action => :create, 'encounter[encounter_type_name]' => params[:encounter_type].upcase, 'encounter[patient_id]' => @patient.id and return if ['registration'].include?(params[:encounter_type])

    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def diagnoses
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    outpatient_diagnosis = ConceptName.find_by_name("DIAGNOSIS").concept
    diagnosis_concepts = ConceptClass.find_by_name("Diagnosis", :include => {:concepts => :name}).concepts rescue []    
    # TODO Need to check a global property for which concept set to limit things to
    if (false)
      diagnosis_concept_set = ConceptName.find_by_name('MALAWI NATIONAL DIAGNOSIS').concept
      diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', concept_set.id], :include => [:name])
    end  
    valid_answers = diagnosis_concepts.map{|concept| 
      name = concept.fullname rescue nil
      name.match(search_string) ? name : nil rescue nil
    }.compact
    previous_answers = []
    # TODO Need to check global property to find out if we want previous answers or not (right now we)
    previous_answers = Observation.find_most_common(outpatient_diagnosis, search_string)
    @suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
    render :text => "<li>" + @suggested_answers.join("</li><li>") + "</li>"
  end

  def treatment
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    valid_answers = []
    unless search_string.blank?
      drugs = Drug.find(:all, :conditions => ["name LIKE ?", '%' + search_string + '%'])
      valid_answers = drugs.map {|drug| drug.name.upcase }
    end
    treatment = ConceptName.find_by_name("TREATMENT").concept
    previous_answers = Observation.find_most_common(treatment, search_string)
    suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
    render :text => "<li>" + suggested_answers.join("</li><li>") + "</li>"
  end
  
  def locations
    search_string = (params[:search_string] || 'neno').upcase
    filter_list = params[:filter_list].split(/, */) rescue []    
    locations =  Location.find(:all, :select =>'name', :conditions => ["name LIKE ?", '%' + search_string + '%'])
    render :text => "<li>" + locations.map{|location| location.name }.join("</li><li>") + "</li>"
  end

  #find the most recent tip and reminder of the subscriber to be edited.
  def recent_tip_and_reminder_program
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    @select_options = select_options
    @phone_numbers = patient_reminders_phone_number(@patient)
    @tips_and_reminders_enrolled_in = type_of_reminder_enrolled_in(@patient)

    @encounter_answers  = {}
    (!params[:encounter_id].blank?) ? (@encounter_id = params[:encounter_id].to_i) : (@encounter_id = nil)
    @encounter_answers  = Encounter.retrieve_previous_encounter(@encounter_id) unless @encounter_id.nil?

    @encounter_id = Encounter.find(:last, :conditions => ["encounter_type = ? and patient_id = ? AND voided = 0",EncounterType.find_by_name("TIPS AND REMINDERS").id,@patient.id]).encounter_id
    render :layout => true
  end

  def observations
    # We could eventually include more here, maybe using a scope with includes
    @encounter = Encounter.find(params[:id], :include => [:observations])
    render :layout => false
  end

  def void 
    @encounter = Encounter.find(params[:id])
    @encounter.void
    head :ok
  end

  # List ARV Regimens as options for a select HTML element
  # <tt>options</tt> is a hash which should have the following keys and values
  #
  # <tt>patient</tt>: a Patient whose regimens will be listed
  # <tt>use_short_names</tt>: true, false (whether to use concept short names or
  #  names)
  #
  def arv_regimen_answers(options = {})
    answer_array = Array.new
    regimen_types = ['FIRST LINE ANTIRETROVIRAL REGIMEN', 
                     'ALTERNATIVE FIRST LINE ANTIRETROVIRAL REGIMEN',
                     'SECOND LINE ANTIRETROVIRAL REGIMEN'
                    ]

    regimen_types.collect{|regimen_type|
      Concept.find_by_name(regimen_type).concept_members.flatten.collect{|member|
        next if member.concept.fullname.include?("Triomune Baby") and !options[:patient].child?
        next if member.concept.fullname.include?("Triomune Junior") and !options[:patient].child?
        if options[:use_short_names]
          include_fixed = member.concept.fullname.match("(fixed)")
          answer_array << [member.concept.shortname, member.concept_id] unless include_fixed
          answer_array << ["#{member.concept.shortname} (fixed)", member.concept_id] if include_fixed
          member.concept.shortname
        else
          answer_array << [member.concept.fullname.titleize, member.concept_id] unless member.concept.fullname.include?("+")
          answer_array << [member.concept.fullname, member.concept_id] if member.concept.fullname.include?("+")
        end
      }
    }
    
    if options[:show_other_regimen]
      answer_array << "Other" if !answer_array.blank?
    end
    answer_array

    # raise answer_array.inspect
  end

  def referral_reasons
    search_string = (params[:search_string] || '').upcase
    referral_reasons = ConceptName.find_by_name("REASON FOR REFERRAL").concept
    previous_answers = []
    #previous_answers = Observation.find_most_common(referral_reasons, search_string)
    previous_answers = Observation.find(:all, :conditions => ["concept_id = ? AND value_text like ?", referral_reasons.id, "#{search_string}%"]).collect{|obs| obs.value_text.humanize }.uniq rescue []
    render :text => "<li>" + previous_answers.join("</li><li>") + "</li>"
  end

  def select_options
    select_options = {
      'maternal_health_info' => [
        ['', ''],
        ['Healthcare visits', 'HEALTHCARE VISITS'],
        ['Nutrition', 'NUTRITION'],
        ['Body changes', 'BODY CHANGES'],
        ['Discomfort', 'DISCOMFORT'],
        ['Concerns', 'CONCERNS'],
        ['Emotions', 'EMOTIONS'],
        ['Warning signs', 'WARNING SIGNS'],
        ['Routines', 'ROUTINES'],
        ['Beliefs', 'BELIEFS'],
        ['Baby\'s growth', 'BABY\'S GROWTH'],
        ['Milestones', 'MILESTONES'],
        ['Prevention', 'PREVENTION']
      ],
      'maternal_health_symptoms' => [
        ['',''],
        ['Vaginal Bleeding during pregnancy','VAGINAL BLEEDING DURING PREGNANCY'],
        ['Postnatal bleeding','POSTNATAL BLEEDING'],
        ['Fever during pregnancy','FEVER DURING PREGNANCY SYMPTOM'],
        ['Postnatal fever','POSTNATAL FEVER SYMPTOM'],
        ['Headaches','HEADACHES'],
        ['Fits or convulsions','FITS OR CONVULSIONS SYMPTOM'],
        ['Swollen hands or feet','SWOLLEN HANDS OR FEET SYMPTOM'],
        ['Paleness of the skin and tiredness','PALENESS OF THE SKIN AND TIREDNESS SYMPTOM']
      ],
      'danger_signs' => [
        ['',''],
        ['Heavy vaginal bleeding during pregnancy','HEAVY VAGINAL BLEEDING DURING PREGNANCY'],
        ['Excessive postnatal bleeding','EXCESSIVE POSTNATAL BLEEDING'],
        ['Fever during pregnancy','FEVER DURING PREGNANCY SIGN'],
        ['Postanatal fever','POSTNATAL FEVER SIGN'],
        ['Severe headache','SEVERE HEADACHE'],
        ['Fits or convulsions','FITS OR CONVULSIONS SIGN'],
        ['Swollen hands or feet','SWOLLEN HANDS OR FEET SIGN'],
        ['Paleness of the skin and tiredness','PALENESS OF THE SKIN AND TIREDNESS SIGN'],
        ['No fetal movements','NO FETAL MOVEMENTS SIGN'],
        ['Water breaks','WATER BREAKS SIGN']
      ],
      'child_health_info' => [
        ['',''],
        ['Sleeping','SLEEPING'],
        ['Feeding problems','FEEDING PROBLEMS'],
        ['crying','CRYING'],
        ['Bowel movements','BOWEL MOVEMENTS'],
        ['Skin rashes','SKIN RASHES'],
        ['Skin infections','SKIN INFECTIONS'],
        ['Umbilicus infection','UMBILICUS INFECTION'],
        ['Growth milestones','GROWTH MILESTONES'],
        ['Accessing healthcare services','ACCESSING HEALTHCARE SERVICES'],
        ['Other','OTHER']
      ],
      'type_of_message_content' => [
        ['Pregnancy', 'Pregnancy'],
        ['Postnatal', 'Postnatal'],
        ['Child', 'Child'],
        ['WCBA', 'WCBA'],
        ['Observer', 'Observer']
      ],
      'message_type' => [
        ['', ''],
        ['SMS', 'SMS'],
        ['Voice','VOICE']
      ],
      'phone_type' => [
        ['', ''],
        ['Community phone', 'COMMUNITY PHONE'],
        ['Personal phone', 'PERSONAL PHONE'],
        ['Family member phone', 'FAMILY MEMBER PHONE'],
        ['Neighbour\'s phone', 'NEIGHBOUR\'S PHONE']
      ],
      'language_type' => [
        ['', ''],
        ['Chichewa', 'CHICHEWA'],
        ['Chiyao', 'CHIYAO']
      ],
      'pregnancy_status' => [
         ['', ''],
         ['Pregnant', 'Pregnant'],
         ['NOT pregnant', 'NOT pregnant'],
         ['Delivered', 'Delivered']
      ],
      'child_danger_signs_greater_zero_outcome' => [
         ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
         ['Hospital', 'HOSPITAL'],
         ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
         ['Given advice', 'GIVEN ADVICE'],
         ['Nurse consultation', 'NURSE CONSULTATION']
      ],
      'child_symptoms_greater_zero_outcome' => [
         ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
         ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
         ['Hospital', 'HOSPITAL'],
         ['Given advice', 'GIVEN ADVICE'],
         ['Nurse consultation', 'NURSE CONSULTATION']
      ],
      'general_outcome' => [
         ['Given advice', 'GIVEN ADVICE'],
         ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
         ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
         ['Hospital', 'HOSPITAL'],
         ['Nurse consultation', 'NURSE CONSULTATION']
      ]
    }
  end
end
