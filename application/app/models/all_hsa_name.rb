class AllHsaName < ActiveRecord::Base
  set_table_name :all_hsa_names
  set_primary_key :hsa_id
  
  belongs_to :person_name, :foreign_key => :person_id, :conditions => {:voided => 0}
  belongs_to :user, :foreign_key => :user_id, :conditions => {:voided => 0}
end
