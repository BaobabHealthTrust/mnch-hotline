class ProgramsController < ApplicationController
  before_filter :find_patient, :except => [:void, :states]
  
  def new
    session[:return_to] = nil
    session[:return_to] = params[:return_to] unless params[:return_to].blank?
    program_names = PatientProgram.find(:all,:conditions =>["voided = 0 AND patient_id = ? AND location_id = ?",
                                    params[:patient_id],Location.current_health_center.id]).map{|pat_program|
                                    pat_program.program.name if pat_program.date_completed.blank?}
    @enrolled_program_names = program_names.to_json                                
    @patient_program = PatientProgram.new
  end

  def create
    active_programs = PatientProgram.find(:all,:conditions =>["voided = 0 AND patient_id = ? AND location_id = ? AND program_id = ?",
                                    @patient.id,params[:location_id],params[:program_id]])
    invalid_date = false
    initial_date = params[:initial_date].to_date
    active_programs.map{ | program |
      next if program.date_completed.blank? and program.date_enrolled.blank?
      invalid_date = (initial_date >= program.date_enrolled.to_date and initial_date < program.date_completed.to_date)
    }

    if invalid_date
      error = "Already enrolled in that program around that time: #{initial_date}"
      redirect_to :controller => "patients" ,:action => "programs",
        :error => error,:patient_id => @patient.id  and return
    end
    
    @patient_program = @patient.patient_programs.build(
      :program_id => params[:program_id],
      :date_enrolled => params[:initial_date],
      :location_id => params[:location_id])      
    @patient_state = @patient_program.patient_states.build(
      :state => params[:initial_state],
      :start_date => params[:initial_date]) 
    if @patient_program.save && @patient_state.save
      redirect_to session[:return_to] and return unless session[:return_to].blank?
      redirect_to :controller => :patients, :action => :programs, :patient_id => @patient.patient_id
    else 
      flash.now[:error] = @patient_program.errors.full_messages.join(". ")
      render :action => "new"
    end
  end

  def status
    @program = PatientProgram.find(params[:id])
    render :layout => false    
  end
  
  def void
    @program = PatientProgram.find(params[:id])
    @program.void
    head :ok
  end  
  
  def locations
    @locations = Location.most_common_program_locations(params[:q] || '')
    @names = @locations.map{|location| "<li value='#{location.location_id}'>#{location.name}</li>" }
    render :text => @names.join('')
  end
  
  def workflows
    @workflows = ProgramWorkflow.all(:conditions => ['program_id = ?', params[:program]], :include => :concept)
    @names = @workflows.map{|workflow| "<li value='#{workflow.id}'>#{workflow.concept.fullname}</li>" }
    render :text => @names.join('')
  end
  
  def states
    @states = ProgramWorkflowState.all(:conditions => ['program_workflow_id = ?', params[:workflow]], :include => :concept)
    @names = @states.map{|state| "<li value='#{state.id}'>#{state.concept.fullname}</li>" unless state.concept.fullname == params[:current_state]}
    render :text => @names.join('')  
  end

  def update
    if request.method == :post
      patient_program = PatientProgram.find(params[:patient_program_id])
      #we don't want to have more than one open states - so we have to close the current active on before opening/creating a new one
      current_active_state = patient_program.patient_states.last
      current_active_state.end_date = params[:current_date].to_date
      current_active_state.save

      patient_state = patient_program.patient_states.build(
        :state => params[:current_state],
        :start_date => params[:current_date]) 
      if patient_state.save
        if patient_state.program_workflow_state.concept.fullname == 'PATIENT TRANSFERRED OUT' 
          encounter = Encounter.new(params[:encounter])
          encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
          encounter.save
          
          (params[:observations] || [] ).each do |observation|
            #for now i do this
            obs = {}
            obs[:concept_name] = observation[:concept_name] 
            obs[:value_coded_or_text] = observation[:value_coded_or_text] 
            obs[:encounter_id] = encounter.id
            obs[:obs_datetime] = encounter.encounter_datetime || Time.now()
            obs[:person_id] ||= encounter.patient_id  
            Observation.create(obs)
          end
     
          observation = {} 
          observation[:concept_name] = 'TRANSFER OUT TO'
          observation[:encounter_id] = encounter.id
          observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
          observation[:person_id] ||= encounter.patient_id
          observation[:value_text] = Location.find(params[:transfer_out_location_id]).name rescue "UNKNOWN"
          Observation.create(observation)
        end  
       
        updated_state = patient_state.program_workflow_state.concept.fullname 
        if updated_state == 'PATIENT TRANSFERRED OUT' or updated_state == 'PATIENT DIED'
          #could not get the commented block of code to update - so I just kinda wrote a hack :(
          # will improve during code clean up!
          #unless patient_program.update_attributes({:date_completed => Time.now()})
           # flash[:notice] = "OOps! Program completed date was not updated!."
          #end
          date_completed = session[:datetime].to_time rescue Time.now()
          PatientProgram.update_all "date_completed = '#{date_completed.strftime('%Y-%m-%d %H:%M:%S')}'",
                                     "patient_program_id = #{patient_program.patient_program_id}"
        end
        redirect_to :controller => :patients, :action => :programs, :patient_id => params[:patient_id]
      else
        redirect_to :controller => :patients, :action => :programs, :patient_id => params[:patient_id]
      end
    else
      patient_program = PatientProgram.find(params[:id])
      unless patient_program.date_completed.blank?
        redirect_to :controller => :patients, :action => :programs, 
          :patient_id => patient_program.patient.id, :error => "Patient have completed this program" and return
      end
      @patient = patient_program.patient
      @patient_program_id = patient_program.patient_program_id
      program_workflow = ProgramWorkflow.all(:conditions => ['program_id = ?', patient_program.program_id], :include => :concept)
      @program_workflow_id = program_workflow.first.program_workflow_id
      @states = ProgramWorkflowState.all(:conditions => ['program_workflow_id = ?', @program_workflow_id], :include => :concept)
      @names = @states.map{|state| state.concept.fullname }
      @program_date_completed = patient_program.date_completed.to_date rescue nil
      @program_name = patient_program.program.name
      @current_state = patient_program.patient_states.last.program_workflow_state.concept.fullname if patient_program.patient_states.last.end_date.blank?

      closed_states = []
      patient_program.patient_states.each do | state |
        next if state.end_date.blank?
        closed_states << "#{state.start_date.to_date}:#{state.end_date.to_date}"
      end
      @invalid_date_ranges = closed_states.join(',')
    end
  end 

end
