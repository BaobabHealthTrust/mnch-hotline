require "composite_primary_keys"
class PatIdentifier < OpenMRS
  set_table_name "patient_identifier"
  belongs_to :type, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :location, :foreign_key => :location_id
  set_primary_keys :patient_id, :identifier, :identifier_type

  def name
    PatIdentifierType.find(:first,:conditions => ["patient_identifier_type_id = ?",self.identifier_type]).name rescue nil
  end

end
