class Observation < ActiveRecord::Base
  set_table_name :obs
  set_primary_key :obs_id
  include Openmrs
  belongs_to :encounter, :conditions => {:voided => 0}
  belongs_to :order, :conditions => {:voided => 0}
  belongs_to :concept, :conditions => {:retired => 0}
  belongs_to :concept_name, :class_name => "ConceptName", :foreign_key => "concept_name", :conditions => {:voided => 0}
  belongs_to :answer_concept, :class_name => "Concept", :foreign_key => "value_coded", :conditions => {:retired => 0}
  belongs_to :answer_concept_name, :class_name => "ConceptName", :foreign_key => "value_coded_name_id", :conditions => {:voided => 0}
  has_many :concept_names, :through => :concept

  named_scope :recent, lambda {|number| {:order => 'obs_datetime DESC,date_created DESC', :limit => number}}
  named_scope :question, lambda {|concept|
    concept_id = concept.to_i
    concept_id = ConceptName.first(:conditions => {:name => concept}).concept_id rescue 0 if concept_id == 0
    {:conditions => {:concept_id => concept_id}}
  }

  def validate
    if (value_numeric != '0.0' && value_numeric != '0' && !value_numeric.blank?)
      value_numeric = value_numeric.to_f
      #TODO
      #value_numeric = nil if value_numeric == 0.0
    end
    errors.add_to_base("Value cannot be blank") if value_numeric.blank? &&
      value_boolean.blank? &&
      value_coded.blank? &&
      value_drug.blank? &&
      value_datetime.blank? &&
      value_numeric.blank? &&
      value_modifier.blank? &&
      value_text.blank?
  end

  def patient_id=(patient_id)
    self.person_id=patient_id
  end
  
  def concept_name=(concept_name)
    self.concept_id = ConceptName.find_by_name(concept_name).concept_id
    rescue
      raise "\"#{concept_name}\" does not exist in the concept_name table"
  end

  def value_coded_or_text=(value_coded_or_text)
    return if value_coded_or_text.blank?
    
    value_coded_name = ConceptName.find_by_name(value_coded_or_text)
    if value_coded_name.nil?
      # TODO: this should not be done this way with a brittle hard ref to concept name
      self.concept_name = "DIAGNOSIS, NON-CODED" if self.concept && self.concept.name && self.concept.fullname == "DIAGNOSIS"
      self.value_text = value_coded_or_text
    else
      self.value_coded_name_id = value_coded_name.concept_name_id
      self.value_coded = value_coded_name.concept_id
      self.value_coded
    end
  end

  def self.find_most_common(concept_question, answer_string, limit = 10)
    self.find(:all, 
      :select => "COUNT(*) as count, concept_name.name as value", 
      :joins => "INNER JOIN concept_name ON concept_name.concept_name_id = value_coded_name_id AND concept_name.voided = 0", 
      :conditions => ["obs.concept_id = ? AND (concept_name.name LIKE ? OR concept_name.name IS NULL)", concept_question, "%#{answer_string}%"],
      :group => :value_coded_name_id, 
      :order => "COUNT(*) DESC",
      :limit => limit).map{|o| o.value }
  end

  def self.find_most_common_location(concept_question, answer_string, limit = 10)
    self.find(:all, 
      :select => "COUNT(*) as count, location.name as value", 
      :joins => "INNER JOIN locations ON location.location_id = value_location AND location.retired = 0", 
      :conditions => ["obs.concept_id = ? AND location.name LIKE ?", concept_question, "%#{answer_string}%"],
      :group => :value_location, 
      :order => "COUNT(*) DESC",
      :limit => limit).map{|o| o.value }
  end

  def self.find_most_common_value(concept_question, answer_string, value_column = :value_text, limit = 10)
    answer_string = "%#{answer_string}%" if value_column == :value_text
    self.find(:all, 
      :select => "COUNT(*) as count, #{value_column} as value", 
      :conditions => ["obs.concept_id = ? AND #{value_column} LIKE ?", concept_question, answer_string],
      :group => value_column, 
      :order => "COUNT(*) DESC",
      :limit => limit).map{|o| o.value }
  end

  def to_s(tags=[])
    formatted_name = self.concept_name.tagged(tags).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.tagged(tags).first.name rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    "#{formatted_name}: #{self.answer_string(tags)}"
  end

  def answer_string(tags=[])
    coded_answer_name = self.answer_concept.concept_names.tagged(tags).first.name rescue nil
    coded_answer_name ||= self.answer_concept.concept_names.first.name rescue nil
    coded_name = "#{coded_answer_name}#{self.value_text}#{self.value_numeric}#{self.value_datetime.strftime("%d/%b/%Y") rescue nil}#{self.value_boolean && (self.value_boolean == true ? 'Yes' : 'No' rescue nil)}#{' ['+order.to_s+']' if order_id && tags.include?('order')}"
    #the following code is a hack
    #we need to find a better way because value_coded can also be a location - not only a concept
    return coded_name unless coded_name.blank?
    ConceptName.find_by_concept_id(self.value_coded).name rescue ''
  end

  def self.patients_with_multiple_start_reasons(start_date , end_date)
    art_eligibility_id      = ConceptName.find_by_name('REASON FOR ART ELIGIBILITY').concept_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id

    patients = self.find_by_sql(["SELECT person_id, concept_id, date_created, value_coded_name_id FROM obs
                                           WHERE (SELECT COUNT(*) FROM obs observation
                                                  WHERE observation.concept_id = ?
                                                    AND observation.person_id = obs.person_id) >= 1
                                                    AND date_created >= ? AND date_created <= ?
                                                    AND obs.concept_id = ?", art_eligibility_id, start_date , end_date, art_eligibility_id])
    patients_data = []

    patients.each do |reason|
      arv_number   = PatientIdentifier.identifier(reason[:person_id], arv_number_id).identifier           rescue []
      national_id  = PatientIdentifier.identifier(reason[:person_id], national_identifier_id).identifier  rescue []
      start_reason = ConceptName.find(reason[:value_coded_name_id]).name

      patients_data << [reason[:person_id].to_s, arv_number, national_id,
                 reason[:date_created].strftime("%Y-%m-%d %H:%M:%S") , start_reason]
    end

    patients_data
  end

  def name_to_s(tags=[])
    formatted_name = self.concept_name.tagged(tags).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.tagged(tags).first.name rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    "#{formatted_name}"
  end

  def to_s_with_bold_name(tags=[])
    formatted_name = self.concept_name.tagged(tags).name rescue nil
    formatted_name ||= self.concept_name.name rescue nil
    formatted_name ||= self.concept.concept_names.tagged(tags).first.name rescue nil
    formatted_name ||= self.concept.concept_names.first.name rescue 'Unknown concept name'
    if formatted_name.nil?
      obs_concept = ConceptName.find_by_sql("SELECT name from concept_name WHERE concept_id = #{self.concept_id} limit 1").map(&:name) rescue nil
      formatted_name = (obs_concept.first == "Who is present as guardian?" ? "Guardian Present" : obs_concept.first) rescue nil
    end
    "<B>#{(formatted_name.nil? ? " " : formatted_name.capitalize)}</B>: #{self.answer_string(tags).capitalize}"
  end
end
