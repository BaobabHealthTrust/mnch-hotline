Factory.sequence :concept_name_name do |n|
  "CONCEPT_NAME_#{n}"
end

Factory.define :concept_name, :class => :concept_name do |concept_name|
  concept_name.name    { Factory.next :concept_name_name }
  concept_name.creator { Factory.creator }  
  concept_name.locale  { "en" }
end
