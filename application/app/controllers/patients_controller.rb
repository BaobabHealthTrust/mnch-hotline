class PatientsController < ApplicationController
  before_filter :find_patient, :except => [:void]

  def show
    #get the pregnancy status for the particular female patient and display
    #either expected due date or delivery date. as for the others, leave it blank
    @tips_and_reminders_enrolled_in = type_of_reminder_enrolled_in(@patient)

    pregnancy_status = @patient.pregnancy_status rescue []
    if pregnancy_status.length != 0
      @status = pregnancy_status[0]
      @date   = pregnancy_status[1]
    else
      @status = ""
      @date   = ""
    end
    #raise require_follow_up.map(&:patient_id).to_yaml
    @patient_needs_follow_up = FollowUp.get_follow_ups(session[:district]).map(&:patient_id).include? @patient.id
    #raise FollowUp.get_follow_ups.to_yaml
    session[:mnch_protocol_required] = false
   #added this to ensure that we are able to void the encounters
    void_encounter if (params[:void] && params[:void] == 'true')
    render :layout => 'clinic'
  end

  def visit_summary
    session[:mastercard_ids] = []
    session_date = session[:datetime].to_date rescue Date.today
    @encounters_list = @patient.encounters.find_by_date(session_date).reverse
    @encounters = []
    @encounters_list.map do |encounter|
      @encounters.push encounter if encounter.observations.map{|obs| obs.answer_string}.include? session[:call_id].to_s
    end

    @encounter_names = @encounters.map{|encounter| encounter.name}.uniq rescue []

    @editing_url = {"PREGNANCY STATUS"          => '/encounters/new/pregnancy_status?patient_id=',
                    "CHILD HEALTH SYMPTOMS"     => '/encounters/new/child_symptoms?patient_id=',
                    "MATERNAL HEALTH SYMPTOMS"  => '/encounters/new/female_symptoms?patient_id=',
                    "UPDATE OUTCOME"            => '/encounters/new/outcome?patient_id=',
                    "TIPS AND REMINDERS"        => '/encounters/new/tips_and_reminders?patient_id='
                  }

    @prescriptions = @patient.orders.unfinished.prescriptions.all
    # This code is pretty hacky at the moment
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @encounters = restriction.filter_encounters(@encounters)
      @prescriptions = restriction.filter_orders(@prescriptions)
      @programs = restriction.filter_programs(@programs)
    end
    render :layout => false
  end

  def treatment
    #@prescriptions = @patient.orders.current.prescriptions.all
    type = EncounterType.find_by_name('TREATMENT')
    session_date = session[:datetime].to_date rescue Date.today
    @prescriptions = Order.find(:all,
                     :joins => "INNER JOIN encounter e USING (encounter_id)",
                     :conditions => ["encounter_type = ? AND e.patient_id = ? AND DATE(encounter_datetime) = ?",
                     type.id,@patient.id,session_date])
    @historical = @patient.orders.historical.prescriptions.all
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @prescriptions = restriction.filter_orders(@prescriptions)
      @historical = restriction.filter_orders(@historical)
    end
    render :template => 'dashboards/treatment', :layout => 'dashboard' 
  end

  def guardians
    if @patient.blank?
    	redirect_to :'clinic'
    	return
    else
		  @relationships = @patient.relationships rescue []
		  @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
		  @restricted.each do |restriction|
		    @relationships = restriction.filter_relationships(@relationships)
		  end
    	render :template => 'dashboards/relationships', :layout => 'dashboard' 
  	end
  end

  def relationships
    if @patient.blank?
    	redirect_to :'clinic'
    	return
    else
      next_form = next_task(@patient)
      redirect_to next_form and return if next_form.match(/Reception/i)
		  @relationships = @patient.relationships rescue []
		  @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
		  @restricted.each do |restriction|
		    @relationships = restriction.filter_relationships(@relationships)
		  end
    	render :template => 'dashboards/relationships', :layout => 'dashboard' 
  	end
  end

  def problems
    render :template => 'dashboards/problems', :layout => 'dashboard' 
  end

  def personal
    render :template => 'dashboards/personal', :layout => 'dashboard' 
  end

  def history
    render :template => 'dashboards/history', :layout => 'dashboard' 
  end

  def programs
    @programs = @patient.patient_programs.all
    @restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })
    @restricted.each do |restriction|
      @programs = restriction.filter_programs(@programs)
    end
    flash.now[:error] = params[:error] unless params[:error].blank?
    render :template => 'dashboards/programs', :layout => 'dashboard' 
  end

  def graph
    render :template => "graphs/#{params[:data]}", :layout => false 
  end

  def void 
    @encounter = Encounter.find(params[:encounter_id])
    @encounter.void
    show and return
  end
  
  def print_registration
    print_and_redirect("/patients/national_id_label/?patient_id=#{@patient.id}", next_task(@patient))  
  end
  
  def print_visit
    print_and_redirect("/patients/visit_label/?patient_id=#{@patient.id}", next_task(@patient))  
  end
  
  def print_mastercard_record
    print_and_redirect("/patients/mastercard_record_label/?patient_id=#{@patient.id}&date=#{params[:date]}", "/patients/visit?date=#{params[:date]}&patient_id=#{params[:patient_id]}")  
  end
  
  def national_id_label
    print_string = @patient.national_id_label rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a national id label for that patient")
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end
  
  def visit_label
    print_string = @patient.visit_label rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a visit label for that patient")
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def mastercard_record_label
    print_string = @patient.visit_label(params[:date].to_date) 
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def mastercard
    #the parameter are used to re-construct the url when the mastercard is called from a Data cleaning report
    @quarter = params[:quarter]
    @arv_start_number = params[:arv_start_number]
    @arv_end_number = params[:arv_end_number]
    @show_mastercard_counter = false
    
    if params[:patient_id].blank?

       @show_mastercard_counter = true

       if !params[:current].blank?
          session[:mastercard_counter] = params[:current].to_i - 1
       end
          @prev_button_class = "yellow"
          @next_button_class = "yellow"
       if params[:current].to_i ==  1
            @prev_button_class = "gray"
       elsif params[:current].to_i ==  session[:mastercard_ids].length
            @next_button_class = "gray"
       else

       end
       @patient_id = session[:mastercard_ids][session[:mastercard_counter]]
       @data_demo = Mastercard.demographics(Patient.find(@patient_id))
       @visits = Mastercard.visits(Patient.find(@patient_id))

    elsif session[:mastercard_ids].length.to_i != 0
      @patient_id = params[:patient_id]
      @data_demo = Mastercard.demographics(Patient.find(@patient_id))
      @visits = Mastercard.visits(Patient.find(@patient_id))
    else
      @patient_id = params[:patient_id]
      @data_demo = Mastercard.demographics(Patient.find(@patient_id))
      @visits = Mastercard.visits(Patient.find(@patient_id))
    end
    render :layout => "menu"
  end
  
  def visit
    @patient_id = params[:patient_id] 
    @date = params[:date].to_date
    @patient = Patient.find(@patient_id)
    @visits = Mastercard.visits(@patient,@date)
    render :layout => "summary"
  end

  def next_available_arv_number
    next_available_arv_number = PatientIdentifier.next_available_arv_number
    render :text => next_available_arv_number.gsub(Location.current_arv_code,'').strip rescue nil
  end
  
  def assigned_arv_number
    assigned_arv_number = PatientIdentifier.find(:all,:conditions => ["voided = 0 AND identifier_type = ?",
    PatientIdentifierType.find_by_name("ARV Number").id]).collect{|i|
      i.identifier.gsub(Location.current_arv_code,'').strip.to_i
    } rescue nil
    render :text => assigned_arv_number.sort.to_json rescue nil 
  end

  def mastercard_modify
    if request.method == :get
      @patient_id = params[:id]
      case params[:field]
        when 'arv_number'
          @edit_page = "arv_number"
        when "name"
      end
    else
      @patient_id = params[:patient_id]
      case params[:field]
        when 'arv_number'
          type = params['identifiers'][0][:identifier_type]
          patient = Patient.find(params[:patient_id])
          patient_identifiers = PatientIdentifier.find(:all,
                                :conditions => ["voided = 0 AND identifier_type = ? AND patient_id = ?",type.to_i,patient.id])

          patient_identifiers.map{|identifier|  
            identifier.voided = 1
            identifier.void_reason = "given another number"
            identifier.date_voided  = Time.now()
            identifier.voided_by = User.current_user.id  
            identifier.save
          }
              
          identifier = params['identifiers'][0][:identifier].strip
          if identifier.match(/(.*)[A-Z]/i).blank?
            params['identifiers'][0][:identifier] = "#{Location.current_arv_code} #{identifier}"
          end
          patient.patient_identifiers.create(params[:identifiers])
          redirect_to :action => "mastercard",:patient_id => patient.id and return
        when "name"
      end
    end
  end

  def summary
    @encounter_type = params[:skipped]
    @patient_id = params[:patient_id]
    render :layout => "menu"
  end

  def export_to_csv
    @users = User.find(:all)

    csv_string = FasterCSV.generate do |csv|
      # header row
      csv << ["id", "first_name", "last_name"]

      # data rows
      @users.each do |user|
        csv << [user.id, user.username, user.salt]
      end
    end

    # send it to the browsah
    send_data csv_string,
            :type => 'text/csv; charset=iso-8859-1; header=present',
            :disposition => "attachment; filename=users.csv"
  end

  def previous_symptoms
    @previous_symptoms  = Encounter.get_previous_symptoms(params[:patient_id])
    @encounter_dates = @previous_symptoms.map{|encounter| encounter.encounter_datetime.strftime("%d-%b-%Y")}.uniq.reverse.first(5) rescue []
    
    render :layout => false
  end

  def recent_calls
    @recent_encounters_list = Encounter.get_previous_encounters(params[:patient_id])
    @recent_calls = Encounter.get_recent_calls(params[:patient_id]).uniq.sort.reverse.first(5)
    @call_times =[]
    @recent_calls.each{|call|
      
      if call.to_s == session[:call_id].to_s
          @call_times << "Start: " + session[:call_start_timestamp].strftime("%d-%b-%Y:%H:%M").to_s + " End: Still Active"
      else
        selected_call = CallLog.find_by_call_log_id(call.to_i)
        if selected_call != nil
          @call_times << "Start: " + selected_call.start_time.strftime("%d-%b-%Y:%H:%M").to_s + " End: " + selected_call.end_time.strftime("%d-%b-%Y:%H:%M").to_s
        else
          @call_times << "Time not Logged"
        end
      end
      
    }
    render :layout => false
  end

  def previous_tips_and_reminders
    @previous_tips_and_reminders = Encounter.get_previous_tips_and_reminders(params[:patient_id])
    @encounter_dates = @previous_tips_and_reminders.map{|encounter| encounter.encounter_datetime.strftime("%d-%b-%Y")}.uniq.reverse.first(5) rescue []

    render :layout => false
  end

  def get_symptoms_concept_ids(concept_list)
    concept_id_list = Array.new

    concept_list.each{|concept|
      concept_id_list << Concept.find_by_name(concept).concept_id
    }

    return concept_id_list
  end

  def demographics
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    render :template => 'patients/demographics', :layout => 'menu'
  end

  def edit_demographics
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @field = params[:field]
    render :partial => "edit_demographics", :field =>@field, :layout => true and return
  end

  def update_demographics
    Person.update_demographics(params)
    redirect_to :action => 'demographics', :patient_id => params['person_id'] and return
  end

private
  
  
end
