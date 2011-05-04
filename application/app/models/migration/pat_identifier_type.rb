class PatIdentifierType < OpenMRS
  set_table_name "patient_identifier_type"
  has_many :pat_identifiers, :foreign_key => :identifier_type
  belongs_to :users, :foreign_key => :user_id
#patient_identifier_type_id
  set_primary_key "patient_identifier_type_id"

  @@patient_identifier_hash_by_name = Hash.new
  self.find(:all).each{|patient_identifier|
    @@patient_identifier_hash_by_name[patient_identifier.name.downcase] = patient_identifier
  }

# Use the cache hash to get these fast
  def self.find_by_name(patient_identifier_name)
    return @@patient_identifier_hash_by_name[patient_identifier_name.downcase] || super
  end

end

