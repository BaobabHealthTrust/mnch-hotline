class PersonAttribute < ActiveRecord::Base
  set_table_name "person_attribute"
  set_primary_key "person_attribute_id"
  include Openmrs

  belongs_to :type, :class_name => "PersonAttributeType", :foreign_key => :person_attribute_type_id, :conditions => {:retired => 0}
  belongs_to :person, :foreign_key => :person_id, :conditions => {:voided => 0}

  def self.phone_numbers(person_id)
    home_phone_id       = PersonAttributeType.find_by_name('HOME PHONE NUMBER').person_attribute_type_id
    cell_phone_id       = PersonAttributeType.find_by_name('CELL PHONE NUMBER').person_attribute_type_id
    office_phone_id     = PersonAttributeType.find_by_name('OFFICE PHONE NUMBER').person_attribute_type_id

    phone_number_query  = "SELECT person_attribute_type.name AS attribute_type, person_attribute.value
                            FROM  person_attribute, person_attribute_type
                            WHERE person_attribute_type.person_attribute_type_id = person_attribute.person_attribute_type_id
                            AND   person_attribute.person_attribute_type_id IN (#{home_phone_id}, #{cell_phone_id},#{office_phone_id})
                            AND   person_id = #{person_id}"

    phone_number_objects = PersonAttribute.find_by_sql(phone_number_query)

    # create a hash of 'symbols' and 'values' like:
    #   {cell_phone_number => '0123456789', home_phone_number => '0987654321'}
    person_phone_numbers = phone_number_objects.reduce({}) do |result, number|
      attribute_type          = number.attribute_type.downcase.gsub(" ", "_").to_sym
      result[attribute_type]  = number.value
      result
    end

    person_phone_numbers
  end

  # Looks for the most commonly used elements in the given table 'column' and sorts the results based on the first part of the string
  def self.find_most_common(column, search_text, attribute_type = nil)
    field_name        = column
    search_string     = search_text
    attribute_type_id = PersonAttributeType.find_by_name(attribute_type).person_attribute_type_id rescue nil

    unless (attribute_type.blank? || attribute_type_id.blank?)
      attribute_details = "person_attribute_type_id = #{attribute_type_id} AND "
    else
      attribute_details = ""
    end

    most_common_attribute_type =  self.find(:all,
                                            :select     => "DISTINCT #{field_name} AS #{field_name}, person_attribute_id AS id",
                                            :conditions => ["#{attribute_details} voided = 0 AND #{field_name} LIKE ?","%#{search_string}%"],
                                            :group      => "#{field_name}",
                                            :order      => "INSTR(#{field_name},\"#{search_string}\") ASC, COUNT(#{field_name}) DESC, #{field_name} ASC ",
                                            :limit      => 10)

    return most_common_attribute_type
  end
end
