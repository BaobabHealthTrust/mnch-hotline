class RegimenDrugOrder < ActiveRecord::Base
  set_table_name "regimen_drug_order"
  set_primary_key "regimen_drug_order_id"
  include Openmrs
  belongs_to :regimen, :conditions => {:retired => 0}
  belongs_to :drug, :foreign_key => :drug_inventory_id, :conditions => {:retired => 0}
    
  def to_s 
    s = "#{drug.name}: #{self.dose} #{self.units} #{frequency}"
    s << " (prn)" if prn == 1
    s
  end  
end