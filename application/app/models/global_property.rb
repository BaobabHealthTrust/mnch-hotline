class GlobalProperty < ActiveRecord::Base
  set_table_name "global_property"
  set_primary_key "id"
  include Openmrs

  def to_s
    return "#{property}: #{property_value}"
  end  
end