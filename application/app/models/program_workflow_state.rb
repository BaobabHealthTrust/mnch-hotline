class ProgramWorkflowState < ActiveRecord::Base
  set_table_name "program_workflow_state"
  set_primary_key "program_workflow_state_id"
  include Openmrs
  belongs_to :program_workflow, :conditions => {:retired => 0}
  belongs_to :concept, :conditions => {:retired => 0}
end
