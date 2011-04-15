class LocationTag < ActiveRecord::Base
  set_table_name :location_tag
  set_primary_key :location_tag_id
  include Openmrs
  has_many :location_tag_map
  has_many :location, :through => :location_tag_map 
end

