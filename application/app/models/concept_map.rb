class ConceptMap < ActiveRecord::Base
  set_table_name :concept_map
  set_primary_key :concept_map_id
  include Openmrs
  belongs_to :concept, :conditions => {:retired => 0}
  belongs_to :concept_source, :class_name => 'ConceptSource', :foreign_key => :source, :conditions => {:voided => 0}
end

