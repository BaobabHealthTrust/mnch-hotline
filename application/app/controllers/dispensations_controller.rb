class DispensationsController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    #@prescriptions = @patient.orders.current.prescriptions.all
    type = EncounterType.find_by_name('TREATMENT')
    session_date = session[:datetime].to_date rescue Date.today
    @prescriptions = Order.find(:all,
                     :joins => "INNER JOIN encounter e USING (encounter_id)", 
                     :conditions => ["encounter_type = ? AND e.patient_id = ? AND DATE(encounter_datetime) = ?",
                     type.id,@patient.id,session_date]) 
    @options = @prescriptions.map{|presc| [presc.drug_order.drug.name, presc.drug_order.drug_inventory_id]}
  end
  
  def create
    if (params[:identifier])
      params[:drug_id] = params[:identifier].match(/^\d+/).to_s
      params[:quantity] = params[:identifier].match(/\d+$/).to_s
    end
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    session_date = session[:datetime] || Time.now()
    @drug = Drug.find(params[:drug_id]) rescue nil

    #TODO look for another place to put this block of code
    if @drug.blank? or params[:quantity].blank?
      flash[:error] = "There is no drug with barcode: #{params[:identifier]}"
      redirect_to "/patients/treatment/#{@patient.patient_id}" and return
    end if (params[:identifier])

    @encounter = @patient.current_dispensation_encounter(session_date)
    
    @order = @patient.current_treatment_encounter(session_date).drug_orders.find(:first,:conditions => ['drug_order.drug_inventory_id = ?', 
             params[:drug_id]]).order rescue []
    # Do we have an order for the specified drug?
    if @order.blank?
      flash[:error] = "There is no prescription for #{@drug.name}"
      redirect_to "/patients/treatment/#{@patient.patient_id}" and return
    end
    # Try to dispense the drug    
      
    obs = Observation.new(
      :concept_name => "AMOUNT DISPENSED",
      :order_id => @order.order_id,
      :person_id => @patient.person.person_id,
      :encounter_id => @encounter.id,
      :value_drug => @order.drug_order.drug_inventory_id,
      :value_numeric => params[:quantity],
      :obs_datetime => session[:datetime] || Time.now())
    if obs.save
      @patient.patient_programs.find_last_by_program_id(Program.find_by_name("HIV PROGRAM")).transition(
               :state => "ON ANTIRETROVIRALS",:start_date => session[:datetime] || Time.now()) if @drug.arv? rescue nil
      @order.drug_order.total_drug_supply(@patient, @encounter,session_date.to_date)
      dispension_completed = @patient.set_received_regimen(@encounter, @order) if @order.drug_order.drug.arv?
      #Pharmacy.dispensed_stock_adjustment(@patient.current_treatment_encounter(session_date.to_date))
      if dispension_completed.blank?
        redirect_to "/patients/treatment/#{@patient.patient_id}"
      else
        redirect_to :controller => 'encounters',:action => 'new',:start_date => @order.start_date.to_date,
          :patient_id => @patient.id,:id =>"show",:encounter_type => "appointment" ,:end_date => @order.auto_expire_date.to_date
      end
    else
      flash[:error] = "Could not dispense the drug for the prescription"
      redirect_to "/patients/treatment/#{@patient.patient_id}"
    end
  end  
  
  def quantities 
    drug = Drug.find(params[:formulation])
    # Most common quantity should be for the generic, not the specific
    # But for now, the value_drug shortcut is significant enough that we 
    # Should just use it. Also, we are using the AMOUNT DISPENSED obs
    # and not the drug_order.quantity because the quantity contains number
    # of pills brought to clinic and we should assume that the AMOUNT DISPENSED
    # observations more accurately represent pack sizes
    amounts = []
    Observation.question("AMOUNT DISPENSED").all(
      :conditions => {:value_drug => drug.drug_id},
      :group => 'value_drug, value_numeric',
      :order => 'count(*)',
      :limit => '10').each do |obs|
      amounts << "#{obs.value_numeric.to_f}" unless obs.value_numeric.blank?
    end
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end
end
