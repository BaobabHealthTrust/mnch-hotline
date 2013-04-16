class VillageHeadman < ActiveRecord::Base
  set_table_name "village_headman"
  set_primary_key "village_headman_id"
  include Openmrs


end