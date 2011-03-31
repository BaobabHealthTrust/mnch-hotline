class Concept < ActiveRecord::Base
  set_table_name :concept
  set_primary_key :concept_id
  include Openmrs

  belongs_to :concept_class, :conditions => {:retired => 0}
  belongs_to :concept_datatype, :conditions => {:retired => 0}
  has_one :concept_numeric, :foreign_key => :concept_id, :dependent => :destroy
  #has_one :name, :class_name => 'ConceptName'
  has_many :answer_concept_names, :class_name => 'ConceptName', :conditions => {:voided => 0}
  has_many :concept_names, :conditions => {:voided => 0}
  has_many :concept_maps # no default scope
  has_many :concept_sets  # no default scope
  has_many :concept_answers do # no default scope
    def limit(search_string)
      return self if search_string.blank?
      map{|concept_answer|
        concept_answer if concept_answer.name.match(search_string)
      }.compact
    end
  end
  has_many :drugs, :conditions => {:retired => 0}
  has_many :concept_members, :class_name => 'ConceptSet', :foreign_key => :concept_set

  def self.find_by_name(concept_name)
    Concept.find(:first, :joins => 'INNER JOIN concept_name on concept_name.concept_id = concept.concept_id', :conditions => ["concept.retired = 0 AND concept_name.voided = 0 AND concept_name.name =?", "#{concept_name}"])
  end

  def shortname
=begin
    ConceptName.find(:first, :conditions => ["concept_id = ? AND concept_name_id IN (?)", 
        self.concept_id, ConceptNameTagMap.find(:all, :conditions => ["concept_name_tag_id = ?", 2]).collect{|id| 
          id.concept_name_id
        }]).name rescue ""
=end
    ConceptName.find(:first,
      :joins => "INNER JOIN concept c ON concept_name.concept_id = c.concept_id
                INNER JOIN concept_name_tag_map cnt ON cnt.concept_name_id = concept_name.concept_name_id",
      :conditions => ["c.concept_id = ? AND cnt.concept_name_tag_id = ?",self.concept_id,2]).name rescue ''
  end

  def fullname
    name = ConceptName.find(:first,
      :joins => "INNER JOIN concept c ON concept_name.concept_id = c.concept_id
                INNER JOIN concept_name_tag_map cnt ON cnt.concept_name_id = concept_name.concept_name_id",
      :conditions => ["c.concept_id = ? AND cnt.concept_name_tag_id = ?",self.concept_id,4]).name rescue nil
    return name unless name.blank?
    return self.concept_names.first.name rescue nil
  end
end
