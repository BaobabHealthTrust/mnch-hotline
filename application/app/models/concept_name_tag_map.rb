class ConceptNameTagMap < ActiveRecord::Base
  set_table_name :concept_name_tag_map
  set_primary_key :concept_name_tag_map_id
  include Openmrs
  belongs_to :tag, :foreign_key => :concept_name_tag_id, :class_name => 'ConceptNameTag', :conditions => {:voided => 0}
  belongs_to :concept_name_tag, :conditions => {:voided => 0}
  belongs_to :concept_name, :conditions => {:retired => 0}
end

