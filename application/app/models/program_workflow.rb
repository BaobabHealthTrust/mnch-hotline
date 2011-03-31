class ProgramWorkflow < ActiveRecord::Base
  set_table_name "program_workflow"
  set_primary_key "program_workflow_id"
  include Openmrs
  belongs_to :program, :conditions => {:retired => 0}
  belongs_to :concept, :conditions => {:retired => 0}
  has_many :program_workflow_states, :conditions => {:retired => 0}
end
