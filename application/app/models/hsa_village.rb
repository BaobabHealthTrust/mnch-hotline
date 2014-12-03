class HsaVillage < ActiveRecord::Base
  has_many :users, :foreign_key => :user_id
  has_many :villages, :foreign_key => :village_id   
  has_many :healthcenters, :foreign_key => :heath_center_id
  has_many :districts, :foreign_key => :district_id

  def self.is_patient_village_in_anc_connect(patient_id)
     status = false
        patient_location = PersonAddress.find_by_person_id(patient_id).city_village rescue nil
        
        if patient_location.present?
          village = Village.find_by_name(patient_location) rescue nil   
          if village.present?
            hsa_village = HsaVillage.find_by_village_id(village.id) rescue nil
            status = true if hsa_village.present?
          end  
        end 
        return status
      end
end
