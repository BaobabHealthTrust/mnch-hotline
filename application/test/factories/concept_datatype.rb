Factory.sequence :concept_datatype_name do |n|
  "CONCEPT_DATATYPE_#{n}"
end

Factory.define :concept_datatype, :class => :concept_datatype do |concept_datatype|
  concept_datatype.name    { Factory.next :concept_datatype_name }
  concept_datatype.creator { Factory.creator }  
  concept_datatype.retired { 0 }
end
