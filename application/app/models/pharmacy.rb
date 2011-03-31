class Pharmacy < ActiveRecord::Base
  set_table_name "pharmacy_obs"
  set_primary_key "pharmacy_module_id"
  include Openmrs

  named_scope :active, :conditions => ['voided = 0']
=begin
  def after_save
    super
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if self.pharmacy_encounter_type == encounter_type
     Pharmacy.reset(self.drug_id)
    end
  end
=end

  def self.voided_stock_adjustment(order)
    drug_id = order.drug_order.drug_inventory_id rescue nil
    quantity = order.drug_order.quantity rescue nil
    next if drug_id.blank? or quantity.blank?
    Pharmacy.new_delivery(d.drug_inventory_id,d.quantity,Date.today)
  end

  def self.dispensed_stock_adjustment(encounter)
    encounter.orders.each do |order|
      drug_id = order.drug_order.drug_inventory_id ; quantity = order.drug_order.quantity
      self.drug_dispensed_stock_adjustment(drug_id,quantity,encounter.encounter_datetime.to_date)
    end
  end 

  def self.drug_dispensed_stock_adjustment(drug_id,quantity,encounter_date,reason = nil)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    number_of_pills = Pharmacy.current_stock(drug_id) 

    current_stock =  Pharmacy.new()
    current_stock.pharmacy_encounter_type = encounter_type
    current_stock.drug_id = drug_id
    current_stock.encounter_date = Date.today
    current_number_of_pills = (number_of_pills - quantity)
    current_stock.value_numeric = current_number_of_pills
    current_stock.save

    unless reason.blank?
      current_stock =  Pharmacy.new()
      current_stock.pharmacy_encounter_type = PharmacyEncounterType.find_by_name("Edited stock").id
      current_stock.drug_id = drug_id
      current_stock.encounter_date = encounter_date
      current_stock.value_numeric = quantity
      current_stock.value_text = reason
      current_stock.save
    end
    self.reset(drug_id,current_number_of_pills)
  end

  def self.reset(drug_id=nil,current_number_of_pills=0)

    stock_encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    new_deliveries = PharmacyEncounterType.find_by_name("New deliveries").id

    if drug_id.blank?
      drug_stock = Pharmacy.active.find(:all,
        :conditions => ["pharmacy_encounter_type=?",new_deliveries],
        :group => "drug_id",:order => "date_created ASC,encounter_date ASC")
    else
      drug_stock = Pharmacy.active.find(:all,
        :conditions => ["pharmacy_encounter_type=? AND drug_id=?",new_deliveries,drug_id],
        :group => "drug_id",:order => "date_created ASC,encounter_date ASC")
    end

    drug_stock.each{|stock|
      first_date_range = Report.cohort_range(stock.encounter_date) rescue nil
      total_dispensed = Pharmacy.dispensed_drugs_since(stock.drug_id,stock.encounter_date,first_date_range.last)
      total_deliverd = Pharmacy.total_delivered(stock.drug_id,stock.encounter_date,first_date_range.last)

      current_stock =  Pharmacy.new()
      current_stock.pharmacy_encounter_type = stock_encounter_type
      current_stock.drug_id = stock.drug_id
      current_stock.encounter_date = first_date_range.last
      current_stock.value_numeric = current_number_of_pills
      #(total_delivered - total_despensed)
      #contains edited. current_stock.value_numeric=tins_currently_in_stock-quantity
      current_stock.save

      dates = self.date_ranges(stock.encounter_date) 
      dates.each{|date|
        given_range = Report.cohort_range(date) rescue nil
        start_date = given_range.first ; end_date = given_range.last
        end_date = Date.today if end_date == Report.cohort_range(Date.today).last
        total_dispensed = Pharmacy.dispensed_drugs_since(stock.drug_id,first_date_range.first,end_date)
        total_delivered = Pharmacy.total_delivered(stock.drug_id,first_date_range.first,end_date)	

        current_stock =  Pharmacy.new()
        current_stock.pharmacy_encounter_type = stock_encounter_type
        current_stock.drug_id = stock.drug_id
        current_stock.encounter_date = end_date
        current_stock.value_numeric = current_number_of_pills
        #contains edited. current_stock.value_numeric=tins_currently_in_stock-quantity
        current_stock.save
      } unless dates.blank?
    }
    true
  end
     
  def self.date_ranges(date)    
    current_range =[]
    current_range << Report.cohort_range(date).last
    end_date = Report.cohort_range(Date.today).last
    while current_range.last < end_date
      current_range << Report.cohort_range(current_range.last + 1.day).last
    end  
    current_range[1..-1] rescue nil
  end

  def Pharmacy.dispensed_drugs_since(drug_id,date,end_date = Date.today)
    treatment_id = EncounterType.find_by_name("TREATMENT").id
    dispensed_drugs = DrugOrder.find(:all,
                      :joins => "INNER JOIN orders o ON o.order_id=drug_order.order_id
                                 INNER JOIN encounter e ON e.encounter_id = o.encounter_id",
                      :select => "SUM(drug_order.quantity) as total_dispensed",
                      :conditions =>["e.voided = 0 AND o.voided = 0 AND encounter_datetime >= ?
                      AND encounter_datetime <=? AND encounter_type = ? AND drug_inventory_id = ?",
                      date.to_date.strftime('%Y-%m-%d 00:00:00'),end_date.to_date.strftime('%Y-%m-%d 23:59:59'),treatment_id,drug_id])

    dispensed_drugs.last["total_dispensed"].to_f rescue 0
   end

  def Pharmacy.dispensed_drugs_to_date(drug_id)
    treatment_id = EncounterType.find_by_name("TREATMENT").id
    dispensed_drugs = DrugOrder.find(:all,
                      :joins => "INNER JOIN orders o ON o.order_id=drug_order.order_id
                                 INNER JOIN encounter e ON e.encounter_id = o.encounter_id",
                      :select => "SUM(drug_order.quantity) as total_dispensed",
                      :conditions =>["e.voided = 0 AND o.voided = 0 AND encounter_datetime <= ?
                      AND encounter_type = ? AND drug_inventory_id = ?",
                      end_date.to_date.strftime('%Y-%m-%d 23:59:59'),treatment_id,drug_id])

    dispensed_drugs.last["total_dispensed"].to_f rescue 0
   end

  def Pharmacy.prescribed_drugs_since(drug_id,start_date,end_date = Date.today)
    treatment_id = EncounterType.find_by_name("TREATMENT").id
    prescribed_drugs = Order.find(:all,
                      :joins => "INNER JOIN drug_order o ON o.order_id = o.order_id
                                 INNER JOIN encounter e ON e.encounter_id = orders.encounter_id",
                      :conditions =>["e.voided = 0 AND orders.voided = 0 AND encounter_datetime >= ?
                      AND encounter_datetime <=? AND encounter_type = ? AND drug_inventory_id = ?",
                      start_date.strftime('%Y-%m-%d 00:00:00'),end_date.strftime('%Y-%m-%d 23:59:59'),treatment_id,drug_id])

    prescribed_drugs
  end

  def self.current_stock(drug_id)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    Pharmacy.active.find(:first,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
     :order => "encounter_date DESC,date_created DESC").value_numeric rescue 0
  end

  def self.current_stock_as_from(drug_id,start_date=Date.today,end_date=Date.today)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id

    return Pharmacy.active.find(:first,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=?
     AND encounter_date <=?",drug_id,encounter_type,end_date],
     :order => "encounter_date DESC,date_created DESC").value_numeric rescue 0

=begin
    total_dispensed_to_date = Pharmacy.dispensed_drugs_since(drug_id,first_date)
    current_stock = self.current_stock(drug_id)

    pills = Pharmacy.dispensed_drugs_since(drug_id,start_date,end_date)
    total_dispensed = Pharmacy.total_delivered(drug_id,start_date,end_date)
=end

    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    first_date = self.active.find(:first,:conditions =>["drug_id =?",drug_id],:order => "encounter_date").encounter_date

    total_stock_to_given_date = Pharmacy.active.find(:all,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=? AND encounter_date >=?
     AND encounter_date <=?",drug_id,encounter_type,first_date,end_date],
     :order => "encounter_date DESC,date_created DESC").map{|stock|stock.value_numeric}

    total_stock_to_given_date  = total_stock_to_given_date.sum
    total_dispensed_to_given_date = Pharmacy.dispensed_drugs_since(drug_id,first_date,end_date)

    return total_stock_to_given_date - total_dispensed_to_given_date
  end


  def self.new_delivery(drug_id,pills,date = Date.today,encounter_type = nil,expiry_date = nil)
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id if encounter_type.blank?
    delivery =  self.new()
    delivery.pharmacy_encounter_type = encounter_type
    delivery.drug_id = drug_id
    delivery.encounter_date = date
    delivery.expiry_date = expiry_date unless expiry_date.blank?
    delivery.value_numeric = pills.to_f
    delivery.save

    if expiry_date
      if expiry_date.to_date < Date.today
        delivery.voided = 1
        return delivery.save
      end  
    end

   #calculate the current stock (can be done better)
   #find the total_dispensed from and after the given date,
   #total_stock before and after the given date
   new_delivery_encounter =  PharmacyEncounterType.find_by_name('New deliveries')
   tins_in_stock =  PharmacyEncounterType.find_by_name('Tins currently in stock')

   total_dispensed_from_given_date = self.dispensed_drugs_since(drug_id,date)
   first_date = self.active.find(:first,:order => "encounter_date").encounter_date
   self.first_delivery_date(drug_id)

   #active.find(:first,:order => "encounter_date").encounter_date
   total_dispensed = Pharmacy.dispensed_drugs_since(drug_id,first_date)
   total_dispensed_to_given_date = (total_dispensed - total_dispensed_from_given_date)

   #calculate stock_before given date
   stock_before_given_date  = nil
     total_stock_before_given_date = self.active.find(:all,
       :conditions =>["pharmacy_encounter_type = ? AND encounter_date < ? AND drug_id = ?",
       new_delivery_encounter.id,date,drug_id]) rescue 0

   if total_stock_before_given_date
     stock_before_given_date = total_stock_before_given_date.map{|stock|stock.value_numeric}  || [0]
       if  stock_before_given_date.empty?
         num=[0]
         stock_before_given_date = num
       end
   end

   encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
   unless stock_before_given_date.blank?
     delivery =  self.new()
     delivery.pharmacy_encounter_type = encounter_type
     delivery.drug_id = drug_id
     delivery.encounter_date = date - 1.day
     delivery.value_numeric = (stock_before_given_date.sum -  total_dispensed_to_given_date)
     delivery.save
   end rescue nil

   #calculate stock_after given date
   stock_after_given_date =
     self.active.find(:all,:conditions =>["pharmacy_encounter_type = ?
       AND Date(encounter_date) >= ? AND drug_id = ?",
       new_delivery_encounter.id,date,drug_id]).map{|stock|stock.value_numeric} || [0]

   if  stock_after_given_date.empty?
     num=[0]
     stock_after_given_date = num
   end

   #calculate stock_edited before the given date
   stock_edited = PharmacyEncounterType.find_by_name("Edited Stock").id

   stock_edited_before_date = self.active.find(:all,
     :conditions =>["pharmacy_encounter_type = ? AND Date(encounter_date) < ? AND drug_id = ?",
     stock_edited,date,drug_id]).map{|stock|stock.value_numeric} || [0]

   if stock_edited_before_date.empty?
     num=[0]
       stock_edited_before_date = num
   end

    #calculate stock_edited after the given date
    stock_edited_after_date = self.active.find(:all,:conditions =>["pharmacy_encounter_type = ?
      AND Date(encounter_date) >= ? AND drug_id = ?",stock_edited,date,drug_id]).map{|stock|stock.value_numeric} || [0]

    if stock_edited_after_date.empty?
      num=[0]
      stock_edited_after_date = num
    end

    delivery =  self.new()
    delivery.pharmacy_encounter_type = encounter_type
    delivery.drug_id = drug_id
    delivery.encounter_date = Date.today

    #Calculate the total_current_stock
    total_stock_before_given_date =
      (stock_before_given_date.sum) - (total_dispensed_to_given_date + stock_edited_before_date.sum)
    total_stock_after_given_date =
      (stock_after_given_date.sum) - (total_dispensed_from_given_date + stock_edited_after_date.sum)
    total_current_stock =
      total_stock_before_given_date + total_stock_after_given_date
    delivery.value_numeric = total_current_stock
    delivery.save
  end

  def Pharmacy.total_delivered(drug_id,start_date=nil,end_date=nil)
    total = 0
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if start_date.blank? and end_date.blank?
      Pharmacy.active.find(:all,
       :conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
       :order => "encounter_date DESC,date_created DESC").map{|d|total+=d.value_numeric}
    else   
      Pharmacy.active.find(:all,
       :conditions => ["drug_id=? AND pharmacy_encounter_type=? 
       AND encounter_date >=? AND encounter_date <=?",drug_id,encounter_type,start_date,end_date],
       :order => "encounter_date DESC,date_created DESC").map{|d|total+=d.value_numeric}
    end 
    total
  end

  def self.first_delivery_date(drug_id)
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    Pharmacy.active.find(:first,:conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
    :order => "encounter_date ASC,date_created ASC").encounter_date rescue nil
  end

  def self.remove_stock(encounter_id)
    encounter = Pharmacy.active.find(encounter_id)
    pills_to_removed =  encounter.value_numeric
    first_date = self.active.find(:first,:order => "encounter_date").encounter_date
    total_dispensed_to_date = Pharmacy.dispensed_drugs_since(encounter.drug_id,first_date)
    current_stock = self.current_stock(encounter.drug_id)

    remaining_stock = (current_stock - pills_to_removed) 
    if remaining_stock >= total_dispensed_to_date
      encounter.voided = 1
      encounter.save
      delivery =  self.new()
      delivery.pharmacy_encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
      delivery.drug_id = encounter.drug_id
      delivery.encounter_date = Date.today
      delivery.value_numeric = remaining_stock
      return delivery.save
    end
  end

end
