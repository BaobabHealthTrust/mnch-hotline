class ClinicController < ApplicationController
  def index

    if params[:status]== 'endcall'
      session[:call_end_timestamp] = Time.now.strftime('%H:%M')
      log_call(0)
    end

    render :template => 'clinic/homemain', :layout => 'clinic'
  end

  def overview
    @types  = Encounter.show_encounter_types
    @me     = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW()) AND encounter.creator = ?', User.current_user.user_id])
    @today  = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = DATE(NOW())'])
    @year   = Encounter.statistics(@types, :conditions => ['YEAR(encounter_datetime) = YEAR(NOW())'])
    @ever   = Encounter.statistics(@types)
    render :template => 'clinic/overview', :layout => false
  end
  def administration
    render  :template => 'clinic/administration', :layout => false
  end

  def reports
    @reports = [["Cohort","/cohort_tool/cohort_menu"],["Supervision","/clinic/supervision"], ["Data Cleaning Tools", "/report/data_cleaning"], ["Stock report","/drug/date_select"]]
    render :template => 'clinic/reports', :layout => 'clinic' 
  end

  def supervision
    @supervision_tools = [["Data that was Updated", "summary_of_records_that_were_updated"],
                          ["Drug Adherence Level",    "adherence_histogram_for_all_patients_in_the_quarter"],
                          ["Visits by Day",           "visits_by_day"],
                          ["Non-eligible Patients in Cohort", "non_eligible_patients_in_cohort"]]

   @landing_dashboard = 'clinic_supervision'

    render :template => 'clinic/supervision', :layout => 'clinic' 
  end

  def properties
    render :template => 'clinic/properties', :layout => 'clinic' 
  end

  def printing
    render :template => 'clinic/printing', :layout => 'clinic' 
  end

  def users
    render :template => 'clinic/users', :layout => 'clinic' 
  end

  def administration
    @reports = [['/clinic/users','User Management'],['/clinic/schedules','Clinic Schedules']]
    @landing_dashboard = 'clinic_administration'
    render :template => 'clinic/administration', :layout => 'clinic' 
  end

 # def schedulehome
 #   render :template => 'clinic/schedulehome', :layout => 'clinic'
 # end
  def schedules
    
    @health_facility  = params[:health_facility] || session[:health_facility]
    @source_url       = params[:source_url] || ""
    @patient_id       = params[:patient_id]

    unless @health_facility
      @health_facilities = [""] + ClinicSchedule.health_facilities_list
      render :template => "/clinic/select", :layout => "application"
    else
      if @source_url == "patient_dashboard"
        @destination = "/patients/show/#{@patient_id}"
      elsif @source_url =="clinic_dashboard"
        @destination = "/clinic"
      else
        @destination = "/clinic"
      end
      void_clinic_schedule  if (params[:void] && params[:void] == 'true')
      ClinicSchedule.create(params) if (params[:new] && params[:new] == 'true')
    end
  end

  def showschedules
      @health_facility  = params[:health_facility] || session[:health_facility]
      @source_url       = params[:source_url] || ""
      @patient_id       = params[:patient_id]
      
       #added to ensure that the page is redirected to the right source
      if @source_url == "patient_dashboard"
        @destination = "/patients/show/#{@patient_id}"
      elsif @source_url =="clinic_dashboard"
        @destination = "/clinic"
      else
        @destination = "/clinic"
      end
      @clinic_list  = ClinicSchedule.clinic_list
      clinic_schedules  = ClinicSchedule.clinic_schedules_by_health_facility(@health_facility) rescue []

      @week_days        = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY",
                            "FRIDAY", "SATURDAY", "SUNDAY"]
      @clinic_days      = ClinicSchedule.week_days(@week_days)


      @schedules = ClinicSchedule.format_clinic_schedules(clinic_schedules, @clinic_list) rescue []

      render :layout => false
    end

    def call
      @task = params[:task]
     
      if @task == 'new'
        session[:call_id] = GlobalProperty.next_call_id
        session[:call_start_timestamp] = Time.now.strftime('%H:%M')
        session[:call_end_timestamp] = ''
      end
      
      render :template => 'clinic/home', :layout => 'clinic'
    end

    def irrelevantcall
      render :template => 'clinic/irrelevantcall', :layout => 'application'
    end

    def irrelevant_call_action
       if params[:confirmation] == 'YES'
         session[:call_end_timestamp] = Time.now.strftime('%H:%M')
         log_call(2)
         redirect_to "/clinic"
       else
         redirect_to "/clinic/call"
       end
      
    end
    
    def emergency_call_action
      if params[:confirmation] == 'YES'
        session[:call_end_timestamp] = Time.now.strftime('%H:%M')
        log_call(1)
        redirect_to "/clinic"
      else
        redirect_to "/clinic/call"
      end
    end

    def emergencycall
      render :template => 'clinic/emergencycall', :layout => 'application'
    end

    def log_call(call_log_type)
      calllog = CallLog.new
      calllog.call_log_id = session[:call_id]
      calllog.start_time = session[:call_start_timestamp]
      calllog.end_time = session[:call_end_timestamp]
      calllog.call_type = call_log_type

      calllog.save

      reset_session_variables
    end

    def reset_session_variables
        session[:call_id] = ''
        session[:call_start_timestamp] = ''
        session[:call_end_timestamp] = ''
    end
end
