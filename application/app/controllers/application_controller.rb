class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  require "fastercsv"

  helper :all
  helper_method :next_task
  filter_parameter_logging :password
  before_filter :login_required, :except => ['login', 'logout','demographics','reports',
                                          'individual_current_enrollments', 'patient_demographics_report',
                                          'patient_health_issues_report','patient_age_distribution_report',
                                          'patient_activity_report','patient_referral_report',
                                          'call_time_of_day','call_day_distribution',
                                          'call_lengths','tips_activity','current_enrollment_totals'
                                         ]
  before_filter :location_required, :except => ['login', 'logout', 'location','demographics','reports',
                                            'individual_current_enrollments', 'patient_demographics_report',
                                            'patient_health_issues_report','patient_age_distribution_report',
                                            'patient_activity_report','patient_referral_report',
                                            'call_time_of_day','call_day_distribution',
                                            'call_lengths','tips_activity','current_enrollment_totals'
                                            ]
  
  def rescue_action_in_public(exception)
    @message = exception.message
    @backtrace = exception.backtrace.join("\n") unless exception.nil?
    render :file => "#{RAILS_ROOT}/app/views/errors/error.rhtml", :layout=> false, :status => 404
  end if RAILS_ENV == 'development' || RAILS_ENV == 'test'

  def rescue_action(exception)
    @message = exception.message
    @backtrace = exception.backtrace.join("\n") unless exception.nil?
    render :file => "#{RAILS_ROOT}/app/views/errors/error.rhtml", :layout=> false, :status => 404
  end if RAILS_ENV == 'production'

  def next_task(patient)

    session_date = session[:datetime].to_date rescue Date.today

    # a fix to allow for redirections from outcome to clinic schedules
    if session[:outcome_complete]
      session.delete(:outcome_complete) # delete the session variable completely to avoid endless iterations
      return "/clinic/schedules?patient_id="+ patient.patient_id.to_s + "&source_url=patient_dashboard"
    end
 
    if (session[:recent_anc_connect])
      #This section is for editing ANC connect
      session.delete(:recent_anc_connect)
      return "/encounters/recent_anc_connect?patient_id=#{patient.patient_id.to_s}"
    end

    if (session[:anc_visit_pregnancy_encounter])
      #This section is for editing ANC connect
      session.delete(:anc_visit_pregnancy_encounter)
      return "/encounters/anc_visit_pregnacy_encounter?patient_id=#{patient.patient_id.to_s}"
    end
    
    if (session[:anc_connect_workflow_start])
      session.delete(:anc_connect_workflow_start)
      return "/patients/anc_connect?patient_id=#{patient.patient_id.to_s}"
    end

    if (session[:anc_visit_update])
      session.delete(:anc_visit_update)
      return "/encounters/new/anc_visit?patient_id=#{patient.patient_id.to_s}"
    end

    if (session[:birth_plan_update])
      session.delete(:birth_plan_update)
      return "/encounters/new/birth_plan?patient_id=#{patient.patient_id.to_s}"
    end

    if (session[:delivery_update])
      session.delete(:delivery_update)
      return "/encounters/new/delivery_update?patient_id=#{patient.patient_id.to_s}"
    end

    if (session[:clinic_dashboard])
      session.delete(:clinic_dashboard)
      return "/clinic/district?district=#{session[:district]}&task=anc"
    end
    
    todays_encounter_types = patient.encounters.find_by_date(session_date).map{|e| e.type.name rescue ''}.uniq rescue []
    if (session[:mnch_protocol_required] || (!todays_encounter_types.include?"REGISTRATION"))
      task = Task.next_task(Location.current_location, patient, session_date, todays_encounter_types)
      return task.url if task.present? && task.url.present?
    end

    return "/patients/show/#{patient.id}" 
  end

  def print_and_redirect(print_url, redirect_url, message = "Printing, please wait...")
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    render :template => 'print/print', :layout => nil
  end

  def void_encounter(reason = "Cancelled")
    @encounter = Encounter.find(params[:encounter_id])
    ActiveRecord::Base.transaction do
      @encounter.void(reason)
    end
    return
  end

  def void_clinic_schedule(reason = "Removed")
    schedule_id = params[:schedule_id] || params[:clinic_schedule_id]
    @schedule = ClinicSchedule.find(schedule_id)
    ActiveRecord::Base.transaction do
      @schedule.void(reason)
    end
    return
  end

  # find if the patient is enrolled on any tips and reminders content
  def type_of_reminder_enrolled_in(patient)
    @patient = Patient.find(patient.patient_id)
    @tips_and_reminders_enrolled_in = []

    Observation.find(:all, :conditions => ["concept_id = ? AND person_id = ? AND voided = 0",
      ConceptName.find_by_name("TYPE OF MESSAGE CONTENT").concept_id, @patient.id]).map do |obs|
        @tips_and_reminders_enrolled_in << ConceptName.find_by_concept_id(obs.value_coded).name.capitalize rescue nil
      end
    return @tips_and_reminders_enrolled_in
  end

  #find the subscriber's number.
  def patient_reminders_phone_number(patient)
    @patient = @patient = Patient.find(patient.patient_id)
    @numbers = Observation.find(:all, :conditions => ["concept_id = ? AND person_id = ? AND voided = 0",
      ConceptName.find_by_name("TELEPHONE NUMBER").concept_id, @patient.id]).map {|obs| obs.value_text}

    if @numbers.blank?
      number = @patient.person.phone_numbers[:cell_phone_number_]
      if number != "Unknown" and number != ""
        @number = number
      end
    else
      @number = @numbers.last
    end
    return @number
  end

  def get_obs_value(value_coded, value_coded_id)
    obs_value = ConceptName.find(:first,
                  :conditions => ["concept_id = ? AND concept_name_id = ? AND voided = 0",
                  value_coded, value_coded_id]).name rescue nil

    return obs_value.to_s
  end
  #please note that any changes to the block below should also be reflected in concept_set in encounter model
  def concept_set(concept_name)
    concept_id = ConceptName.find_by_name(concept_name).concept_id
    
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; item.concept.fullname }
    return options
  end
  
  def healthcenter
    district_id = District.find_by_name("#{session[:district]}").id
    hc_conditions = ["name LIKE (?) AND district = ?", "%#{params[:search_string]}%", district_id]
    hc_array = []
    hc_array << [" "," "]
    health_centers = HealthCenter.find(:all,:conditions => hc_conditions, :order => 'name')
    health_centers = health_centers.map do |h_c|
      hc_array << ["#{h_c.name.humanize}","#{h_c.name.humanize}"]
    end
 
    return hc_array << ["Other","Other"]
  end
  
  def show_for_anc_connect(patient_id)
    HsaVillage.is_patient_village_in_anc_connect(patient_id)
  end
  
private

  def find_patient
    @patient = Patient.find(params[:patient_id] || session[:patient_id] || params[:id]) rescue nil
  end
 
end
