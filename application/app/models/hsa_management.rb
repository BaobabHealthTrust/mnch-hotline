class HsaManagement < ActiveRecord::Base
  has_many :users, :foreign_key => :user_id
  has_many :villages, :foreign_key => :village_id   
  has_many :healthcenters, :foreign_key => :heath_center_id
  has_many :districts, :foreign_key => :district_id

  def self.is_patient_village_in_anc_connect(patient_id,district = nil)
     status = false
        patient_location = PersonAddress.find_by_person_id(patient_id) rescue nil
        patient_district  = District.find_by_name(district)  rescue nil
	ta = TraditionalAuthority.find_by_name_and_district_id(patient_location.county_district, patient_district.district_id) rescue nil

        if patient_location.present?
          village = Village.find_by_name_and_traditional_authority_id(patient_location.city_village, ta.traditional_authority_id) rescue nil   
          if village.present?
            hsa_village = HsaVillage.find_by_village_id_and_district_id(village.village_id, patient_district.district_id) rescue nil
            status = true if hsa_village.present?
          end  
        end 
        return status
      end
end
