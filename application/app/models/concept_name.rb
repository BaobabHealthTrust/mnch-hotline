class ConceptName < ActiveRecord::Base
  set_table_name :concept_name
  set_primary_key :concept_name_id
  include Openmrs
  has_many :concept_name_tag_maps # no default scope
  has_many :tags, :through => :concept_name_tag_maps, :class_name => 'ConceptNameTag'
  belongs_to :concept, :conditions => {:retired => 0}
  named_scope :tagged, lambda{|tags| tags.blank? ? {} : {:include => :tags, :conditions => ['concept_name_tag.tag IN (?)', Array(tags)]}}
end

