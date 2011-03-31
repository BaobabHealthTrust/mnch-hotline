class DrugController < ApplicationController
  def management
    @activities = [["New stock","delivery"],["Edit stock","edit_stock"], ["Print Barcode","print_barcode"]]
    
#TODO
#need to redo the SQL query
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    new_deliveries = Pharmacy.active.find(:all,
      :conditions =>["pharmacy_encounter_type=?",encounter_type],
      :order => "encounter_date DESC,date_created DESC")

    current_stock = {}
    new_deliveries.each{|delivery|
      current_stock[delivery.drug_id] = delivery if current_stock[delivery.drug_id].blank?
      break if current_stock.length == 5
    }

    @stock = {}
    current_stock.each{|delivery_id , delivery|
      start_date = Pharmacy.active.find(:first,:conditions =>["drug_id =?",
                   delivery.drug_id],:order => "encounter_date").encounter_date.to_date rescue nil
      next if start_date.blank?

      drug = Drug.find(delivery.drug_id)
      drug_name = drug.name
      @stock[drug_name] = {"current_stock" => 0,"dispensed" => 0,"prescribed" => 0, "consumption_per" => ""}
      @stock[drug_name]["current_stock"] = Pharmacy.current_stock_as_from(drug.id,start_date)
      @stock[drug_name]["dispensed"] = Pharmacy.dispensed_drugs_since(drug.id,start_date)
      @stock[drug_name]["consumption_per"] = sprintf('%.2f',((@stock[drug_name]["dispensed"].to_f / @stock[drug_name]["current_stock"].to_f) * 100.to_f)).   to_s + " %" rescue "0 %"
    }

    #render :template => 'drug/management', :layout => 'clinic'
    render :layout => "menu"
  end

  def name
    @names = Drug.find(:all,:conditions =>["name LIKE ?","%" + params[:search_string] + "%"]).collect{|drug| drug.name}
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def delivery
    @drugs = Drug.find(:all).map{|d|d.name}.compact.sort rescue []
  end

  def create_stock
    obs = params[:observations]
    delivery_date = obs[0]['value_datetime']
    expiry_date = obs[1]['value_datetime']
    drug_id = Drug.find_by_name(params[:drug_name]).id
    number_of_tins = params[:number_of_tins].to_f
    number_of_pills_per_tin = params[:number_of_pills_per_tin].to_f
    number_of_pills = (number_of_tins * number_of_pills_per_tin)
    Pharmacy.new_delivery(drug_id,number_of_pills,delivery_date,nil,expiry_date)
    #add a notice
    flash[:notice] = "#{params[:drug_name]} successfully entered"
    redirect_to :action => "management" ; return 
    render :text => "#{expiry_date} .. #{delivery_date} ... #{params[:number_of_tins]} ... #{params[:number_of_pills_per_tin]}"; return
  end

  def edit_stock
    if request.method == :post
      obs = params[:observations]
      edit_reason = obs[0]['value_coded_or_text']
      encounter_datetime = obs[1]['value_datetime']
      drug_id = Drug.find_by_name(params[:drug_name]).id
      pills = (params[:number_of_pills_per_tin].to_i * params[:number_of_tins].to_i)
      date = encounter_datetime || Date.today 
      Pharmacy.drug_dispensed_stock_adjustment(drug_id,pills,date,edit_reason)
      flash[:notice] = "#{params[:drug_name]} successfully edited"
      redirect_to :action => "management" and return
    end
  end

  def stock_report
    obs = params[:observations]
    @start_date = obs[0]['value_datetime'].to_date
    @end_date = obs[1]['value_datetime'].to_date

#TODO
#need to redo the SQL query
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    new_deliveries = Pharmacy.active.find(:all,
      :conditions =>["pharmacy_encounter_type=?",encounter_type],
      :order => "encounter_date DESC,date_created DESC")

    current_stock = {}
    new_deliveries.each{|delivery|
      current_stock[delivery.drug_id] = delivery if current_stock[delivery.drug_id].blank?
    }

    @stock = {}
    current_stock.each{|delivery_id , delivery|
      first_date = Pharmacy.active.find(:first,:conditions =>["drug_id =?",
                   delivery.drug_id],:order => "encounter_date").encounter_date.to_date rescue nil
      next if first_date.blank?
      next if first_date > @start_date

      drug = Drug.find(delivery.drug_id)
      drug_name = drug.name
      @stock[drug_name] = {"current_stock" => 0,"dispensed" => 0,"prescribed" => 0, "consumption_per" => ""}
      @stock[drug_name]["current_stock"] = Pharmacy.current_stock_as_from(drug.id,@start_date,@end_date)
      @stock[drug_name]["dispensed"] = Pharmacy.dispensed_drugs_since(drug.id,@start_date,@end_date)
      #@stock[drug_name]["prescribed"] = Pharmacy.prescribed_drugs_since(drug.id,@start_date,@end_date)
      @stock[drug_name]["consumption_per"] = sprintf('%.2f',((@stock[drug_name]["dispensed"].to_f / @stock[drug_name]["current_stock"].to_f) * 100.to_f)).   to_s + " %" rescue "0 %"
    }
    render :layout => "menu" 
  end

  def date_select
#    render :text => "aaaaa" and return
  end
end
