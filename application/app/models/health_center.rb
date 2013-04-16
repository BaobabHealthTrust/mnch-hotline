class HealthCenter < ActiveRecord::Base
  set_table_name "health_center"
  set_primary_key "health_center_id"
  include Openmrs


end