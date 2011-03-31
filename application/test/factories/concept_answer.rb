Factory.define :concept_answer, :class => :concept_answer do |concept_answer|
  concept_answer.answer {|concept_answer| concept_answer.association(:concept)}
  concept_answer.concept {|concept_answer| concept = concept_answer.association(:concept); puts concept.id}
  concept_answer.creator { Factory.creator }
end
