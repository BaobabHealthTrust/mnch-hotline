class RegimensController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @programs = @patient.patient_programs.all
    @current_regimens_for_programs = current_regimens_for_programs
    @current_regimen_names_for_programs = current_regimen_names_for_programs
  end
  
  def create
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    session_date = session[:datetime] || Time.now()
    encounter = @patient.current_treatment_encounter(session_date)
    start_date = session[:datetime] || Time.now
    auto_expire_date = session[:datetime] + params[:duration].to_i.days rescue Time.now + params[:duration].to_i.days
    orders = RegimenDrugOrder.all(:conditions => {:regimen_id => params[:regimen]})
    ActiveRecord::Base.transaction do
      # Need to write an obs for the regimen they are on, note that this is ARV
      # Specific at the moment and will likely need to have some kind of lookup
      # or be made generic
      obs = Observation.create(
        :concept_name => "WHAT TYPE OF ANTIRETROVIRAL REGIMEN",
        :person_id => @patient.person.person_id,
        :encounter_id => encounter.encounter_id,
        :value_coded => params[:regimen_concept_id],
        :obs_datetime => start_date)    
      orders.each do |order|
        drug = Drug.find(order.drug_inventory_id)
        regimen_name = (order.regimen.concept.concept_names.tagged("short").first || order.regimen.concept.name).name
        DrugOrder.write_order(
          encounter, 
          @patient, 
          obs, 
          drug, 
          start_date, 
          auto_expire_date, 
          order.dose, 
          order.frequency, 
          order.prn, 
          "#{drug.name}: #{order.instructions} (#{regimen_name})",
          order.equivalent_daily_dose)    
      end
    end  
    # Send them back to treatment for now, eventually may want to go to workflow
    redirect_to "/patients/treatment?patient_id=#{@patient.id}"
  end    
  
  def suggested
    @patient_program = PatientProgram.find(params[:id])
    @options = []
    render :layout => false and return unless @patient_program
    @regimens = @patient_program.regimens(@patient_program.patient.current_weight).uniq
    @regimens = @regimens.map{|r| Concept.find(r) }
    @options = @regimens.map{|r| [r.concept_id, (r.concept_names.tagged("short").first || r.name).name] } + @options
    render :layout => false    
  end
  
  def dosing
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @criteria = Regimen.criteria(@patient.current_weight).all(:conditions => {:concept_id => params[:id]}, :include => :regimen_drug_orders)
    @options = @criteria.map do |r| 
      [r.regimen_id, r.regimen_drug_orders.map(&:to_s).join('; ')]
    end
    render :layout => false    
  end
  
  # Look up likely durations for the regimen
  def durations
    @regimen = Regimen.find_by_concept_id(params[:id], :include => :regimen_drug_orders)
    @drug_id = @regimen.regimen_drug_orders.first.drug_inventory_id rescue nil
    render :text => "No matching durations found for regimen" and return unless @drug_id

    # Grab the 10 most popular durations for this drug
    amounts = []
    orders = DrugOrder.find(:all, 
      :select => 'DATEDIFF(orders.auto_expire_date, orders.start_date) as duration_days',
      :joins => 'LEFT JOIN orders ON orders.order_id = drug_order.order_id AND orders.voided = 0',
      :limit => 10, 
      :group => 'drug_inventory_id, DATEDIFF(orders.auto_expire_date, orders.start_date)', 
      :order => 'count(*)', 
      :conditions => {:drug_inventory_id => @drug_id})      
    orders.each {|order|
      amounts << "#{order.duration_days.to_f}" unless order.duration_days.blank?
    }  
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end
  
  private
  
  def current_regimens_for_programs
    @programs.inject({}) do |result, program| 
      result[program.patient_program_id] = program.current_regimen; result 
    end
  end

  def current_regimen_names_for_programs
    @programs.inject({}) do |result, program| 
    
      result[program.patient_program_id] = program.current_regimen ? Concept.find_by_concept_id(program.current_regimen).concept_names.tagged(["short"]).map(&:name) : nil; result 
    end
  end
end
