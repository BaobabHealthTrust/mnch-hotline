class Program < ActiveRecord::Base
  set_table_name "program"
  set_primary_key "program_id"
  include Openmrs
  belongs_to :concept, :conditions => {:retired => 0}
  has_many :patient_programs, :conditions => {:voided => 0}
  has_many :program_workflows, :conditions => {:retired => 0}
  has_many :program_workflow_states, :through => :program_workflows
end
