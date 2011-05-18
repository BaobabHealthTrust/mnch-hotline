class ShowEncounterTypesGlobalProperty < ActiveRecord::Migration
  def self.up
    g = GlobalProperty.new()
    g.property        = "statistics.show_encounter_types"
    g.property_value  = "CHILD HEALTH SYMPTOMS, MATERNAL HEALTH SYMPTOMS, " +
                        "MATERNITY DIAGNOSIS, REGISTRATION, " +
                        "TIPS AND REMINDERS, TREATMENT"
    g.save

    g = GlobalProperty.new()
    g.property        = "interface"
    g.property_value  = "fancy"
    g.save

    g = GlobalProperty.new()
    g.property        = "IVR_ACCESS_CODE_COUNTER"
    g.property_value  = "0"
    g.save

    g = GlobalProperty.new()
    g.property        = "CALL_ID_COUNTER"
    g.property_value  = "0"
    g.save

  end

  def self.down
    g = GlobalProperty.find_by_property("statistics.show_encounter_types")
    g.delete

    g = GlobalProperty.find_by_property("interface")
    g.delete

    g = GlobalProperty.find_by_property("IVR_ACCESS_CODE_COUNTER")
    g.delete

    g = GlobalProperty.find_by_property("CALL_ID_COUNTER")
    g.delete
  end
end
