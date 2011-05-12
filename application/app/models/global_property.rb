class GlobalProperty < ActiveRecord::Base
  set_table_name "global_property"
  set_primary_key "id"
  include Openmrs

  def to_s
    return "#{property}: #{property_value}"
  end

  def self.next_ivr_access_code
    site_location = Location.current_location.site_id.rjust(3,'0')

    globalproperty = GlobalProperty.find_by_property("IVR_ACCESS_CODE_COUNTER")
    current_number = globalproperty.property_value.to_i + 1
    globalproperty.update_attribute('property_value', current_number)
    globalproperty.save

    return site_location.to_s + current_number.to_s.rjust(5,'0')
  end

  def self.next_call_id
    globalproperty = GlobalProperty.find_by_property("CALL_ID_COUNTER")
    current_number = globalproperty.property_value.to_i + 1
    globalproperty.update_attribute('property_value', current_number)
    globalproperty.save

    return  current_number.to_s.rjust(8,'0')
  end
  
end