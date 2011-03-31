Factory.sequence :concept_class_name do |n|
  "CONCEPT_CLASS_#{n}"
end

Factory.define :concept_class, :class => :concept_class do |concept_class|
  concept_class.name    { Factory.next :concept_class_name }
  concept_class.creator { Factory.creator }  
  concept_class.retired { 0 }
end
