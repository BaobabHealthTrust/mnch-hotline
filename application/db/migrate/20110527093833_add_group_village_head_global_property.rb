class AddGroupVillageHeadGlobalProperty < ActiveRecord::Migration
  def self.up
    g = GlobalProperty.new()
    g.property        = "demographics.group_village_head"
    g.property_value  = "yes"
    g.save
  end

  def self.down
    g = GlobalProperty.find_by_property("demographics.group_village_head")
    g.delete
  end
end
