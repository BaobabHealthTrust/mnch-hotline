class Drug < ActiveRecord::Base
  set_table_name :drug
  set_primary_key :drug_id
  include Openmrs
  belongs_to :concept, :conditions => {:retired => 0}
  belongs_to :form, :foreign_key => 'dosage_form', :class_name => 'Concept', :conditions => {:retired => 0}
  
  def arv?
    Drug.arv_drugs.map(&:concept_id).include?(self.concept_id)
  end

  def self.arv_drugs
    arv_concept       = ConceptName.find_by_name("ANTIRETROVIRAL DRUGS").concept_id
    arv_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', arv_concept])
    arv_drug_concepts
  end
end
