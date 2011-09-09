class ClinicController < ApplicationController
  def index

    if params[:status]== 'endcall'
      session[:call_end_timestamp] = DateTime.now
      log_call(0)
    end
    @tt_active_tab = params[:active_tab]
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
    @reports = [["Patient Analysis","/report/type?q=patient_analysis"],["Tips","/report/type?q=tips"], ["Call Analysis", "/report/type?q=call_analysis"]]
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
    render :template => 'clinic/showuserfunctions', :layout => 'clinic'
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
        session.delete(:health_facility)
        patient       = Patient.find(@patient_id)
        @destination  = next_task(patient) and return # let the system resolve the next task to do and return sucessfully
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
        session[:call_id] = GlobalProperty.next_call_id rescue nil
        session[:call_start_timestamp] = DateTime.now
        session[:call_end_timestamp] = ''
      end
      
      render :template => 'clinic/home', :layout => 'clinic'
    end

    def irrelevantcall
      render :template => 'clinic/irrelevantcall', :layout => 'application'
    end

    def irrelevant_call_action
       if params[:confirmation] == 'YES'
         session[:call_end_timestamp] = DateTime.now
         log_call(2)
         redirect_to "/clinic"
       else
         redirect_to "/clinic/call"
       end
      
    end
    
    def emergency_call_action
      if params[:confirmation] == 'YES'
        session[:call_end_timestamp] = DateTime.now
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
      calllog.call_log_id = session[:call_id].to_i
      calllog.start_time = session[:call_start_timestamp]
      calllog.end_time = session[:call_end_timestamp]
      calllog.call_type = call_log_type.to_i

      calllog.save

      reset_session_variables
    end

    def reset_session_variables
        session[:call_id] = ''
        session[:call_start_timestamp] = ''
        session[:call_end_timestamp] = ''
    end

    def clinichome
       @tt_active_tab = params[:active_tab]
       render :template => 'clinic/clinicadministration', :layout => 'clinic'
    end

    def clinicadministration
      render  :template => 'clinic/clinicadministration', :layout => 'clinic'
    end
    #just added to add health_facilities
    def create
        clinic_name = params[:location_name]
        if Location.find_by_name(clinic_name[:clinic_name]) == nil then
            location = Location.new
            location.name = clinic_name[:clinic_name]
            location.creator  = User.current_user.id.to_s
            location.date_created  = Time.current.strftime("%Y-%m-%d %H:%M:%S")
            location.save rescue (result = false)

            location_tag_map = LocationTagMap.new
            location_tag_map.location_id = location.id
            location_tag_map.location_tag_id = LocationTag.find_by_tag("mnch_health_facilities").id
            result = location_tag_map.save rescue (result = false)

            if result = true then
               flash[:notice] = "Clinic : #{clinic_name[:clinic_name]} added successfully"
            else
               flash[:notice] = "Clinic : #{clinic_name[:clinic_name]} addition failed"
            end
        else
            location_tag_map = LocationTagMap.new
            location_tag_map.location_id = Location.find_by_name(clinic_name[:clinic_name]).id
            location_tag_map.location_tag_id = LocationTag.find_by_tag("mnch_health_facilities").id
            result = location_tag_map.save rescue (result = false)

            if result = true then
               flash[:notice] = "Clinic : #{clinic_name[:clinic_name]} added successfully"
            else
               flash[:notice] = "Clinic : #{clinic_name[:clinic_name]} addition failed"
            end
        end

    end
    
    def new
        @act = params[:act]
        render :layout => "application"
    end

    def search
            field_name = "name"
            search_string = params[:search_string]

            if params[:act].to_s == "delete" then
                sql = "SELECT *
                       FROM location
                       WHERE location_id IN (SELECT location_id
	                                  FROM location_tag_map
	                                  WHERE location_tag_id = (SELECT location_tag_id
				                                   FROM location_tag
				                                   WHERE tag = 'mnch_health_facilities'))
                       ORDER BY name ASC"
            elsif params[:act].to_s == "create" then
               #sql = "SELECT * FROM location WHERE name LIKE '%#{search_string}%' ORDER BY name ASC"
                sql = "SELECT *
                       FROM location
                       WHERE location_id NOT IN (SELECT location_id
	                                  FROM location_tag_map
	                                  WHERE location_tag_id = (SELECT location_tag_id
				                                   FROM location_tag
				                                   WHERE tag = 'mnch_health_facilities'))  AND name LIKE '%#{search_string}%'
                       ORDER BY name ASC"
            end

            @names = Location.find_by_sql(sql).collect{|name| name.send(field_name)}
            render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"

    end

    def delete
        clinic_name = params[:location_name]
        location_id = Location.find_by_name(clinic_name[:clinic_name]).id rescue -1
        location_tag_id = LocationTag.find_by_tag("mnch_health_facilities").id rescue -1

        result = ActiveRecord::Base.connection.execute("DELETE FROM location_tag_map WHERE location_id = #{location_id} AND location_tag_id = #{location_tag_id}") rescue 2

        if result != 2 then
           flash[:notice] = "location #{clinic_name[:clinic_name]} delete successfully"
        else
           flash[:notice] = "location #{clinic_name[:clinic_name]} deletion failed"
        end
    end
end
