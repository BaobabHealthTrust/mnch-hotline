Factory.sequence :person_name_name do |n|
  "Person#{n}"
end

Factory.define :person_name, :class => :person_name do |person_name|
  person_name.given_name { Factory.next :person_name_name }
  person_name.family_name { Factory.next :person_name_name }
end