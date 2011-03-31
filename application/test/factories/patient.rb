Factory.define :patient, :class => :patient do |patient|
  patient.person {|patient| patient.association(:person)}
end

#  has_one :person
#  has_many :patient_identifiers
#  has_many :patient_programs
#  has_many :relationships
#  has_many :orders
#  has_many :encounters

