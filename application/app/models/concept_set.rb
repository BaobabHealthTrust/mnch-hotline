class ConceptSet < ActiveRecord::Base
  set_table_name :concept_set
  set_primary_key :concept_set_id
  include Openmrs
  belongs_to :set, :class_name => 'Concept', :conditions => {:retired => 0}
  belongs_to :concept, :conditions => {:retired => 0}
end
