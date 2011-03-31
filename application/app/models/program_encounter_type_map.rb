class ProgramEncounterTypeMap < ActiveRecord::Base
  set_table_name "program_encounter_type_map"
  set_primary_key "program_encounter_type_map_id"
  include Openmrs
  belongs_to :program, :conditions => {:retired => 0}
  belongs_to :encounter_type, :conditions => {:retired => 0}
end
