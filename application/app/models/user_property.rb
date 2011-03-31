class UserProperty < ActiveRecord::Base
  set_table_name "user_property"
  set_primary_keys :user_id, :property
  include Openmrs
  belongs_to :user, :foreign_key => :user_id, :conditions => {:voided => 0}
end