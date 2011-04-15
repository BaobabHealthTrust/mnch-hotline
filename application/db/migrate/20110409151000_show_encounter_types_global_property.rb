class ShowEncounterTypesGlobalProperty < ActiveRecord::Migration
  def self.up
    g = GlobalProperty.new()
    g.property        = "statistics.show_encounter_types"
    g.property_value  = "CHILD HEALTH SYMPTOMS, MATERNAL HEALTH SYMPTOMS, " +
                        "MATERNITY DIAGNOSIS, REGISTRATION, " +
                        "TIPS AND REMINDERS, TREATMENT"
    g.save
  end

  def self.down
    g = GlobalProperty.find_by_property("statistics.show_encounter_types")
    g.delete
  end
end
