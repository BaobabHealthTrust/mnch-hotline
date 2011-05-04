class CreateClinicList < ActiveRecord::Migration
  def self.up
    g = GlobalProperty.new()
    g.property        = "health_facility.clinic_list"
    g.property_value  = "ANTENATAL, ART, HTC, MATERNITY, " +
                        "NUTRITION, OPD, POSTNATAL, UNDER 5"
    g.save
  end

  def self.down
    g = GlobalProperty.find_by_property("health_facility.clinic_list")
    g.delete
  end
end
