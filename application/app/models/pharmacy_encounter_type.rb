class PharmacyEncounterType < ActiveRecord::Base
  set_table_name "pharmacy_encounter_type"
  set_primary_key "pharmacy_encounter_type_id"
  include Openmrs
end
