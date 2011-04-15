class LocationTagMap < ActiveRecord::Base
  set_table_name  :location_tag_map
  set_primary_key :location_tag_map_id
  include Openmrs
  belongs_to :tag, :foreign_key => :location_tag_id, :class_name => 'LocationTag', :conditions => {:voided => 0}
  belongs_to :location_tag, :conditions => {:voided => 0}
  belongs_to :location, :conditions => {:retired => 0}
end

