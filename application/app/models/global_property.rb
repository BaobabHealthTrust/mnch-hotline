class GlobalProperty < ActiveRecord::Base
  set_table_name "global_property"
  set_primary_key "id"
  include Openmrs

  def to_s
    return "#{property}: #{property_value}"
  end

  def self.next_ivr_access_code
    site_location = Location.current_health_center.location_id

    globalproperty = GlobalProperty.find_by_property("ivr_access_code.counter")
    current_number = globalproperty.property_value.to_i + 1
    globalproperty.update_attribute('property_value', current_number)
    globalproperty.save

    return site_location.to_s + current_number.to_s.rjust(5,'0')
  end

  def self.next_call_id
    globalproperty = GlobalProperty.find_by_property("call_id.counter")
    current_number = globalproperty.property_value.to_i + 1
    globalproperty.update_attribute('property_value', current_number)
    globalproperty.save

    return  current_number.to_s.rjust(8,'0')
  end
  
  def self.get_property(property_to_search)
    property = GlobalProperty.find_by_property("#{property_to_search}")
    property_value = (property == nil) ? nil : property.property_value
    
    return  property_value
  end
  
end