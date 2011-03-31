Factory.define :concept_set, :class => :concept_set do |concept_set|
  concept_set.concept_set   {|concept_set| concept_set.association(:concept)}
  concept_set.concept       {|concept_set| concept_set.association(:concept)}
  concept_set.creator       { Factory.creator }
  concept_set.sort_weight   { 1.0 }
end
