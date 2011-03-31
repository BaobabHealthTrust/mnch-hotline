class ConceptAnswer < ActiveRecord::Base
  set_table_name :concept_answer
  set_primary_key :concept_answer_id
  include Openmrs

  belongs_to :answer, :class_name => 'Concept', :foreign_key => 'answer_concept', :conditions => {:retired => 0}
  belongs_to :drug, :class_name => 'Drug', :foreign_key => 'answer_drug', :conditions => {:retired => 0}
  belongs_to :concept, :class_name => 'Concept', :foreign_key => 'concept_id', :conditions => {:retired => 0}

  def name
    self.answer.fullname rescue ''
  end
end
