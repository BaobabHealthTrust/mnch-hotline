class CreateNearestHealthFacilityAttribute < ActiveRecord::Migration
  def self.up
  attribute =  PersonAttributeType.new()
  attribute.description     = "The person's nearest health facility"
  attribute.edit_privilege  = nil
  attribute.foreign_key     = nil
  attribute.format          = nil
  attribute.name            = "NEAREST HEALTH FACILITY"
  attribute.retired         = 0
  attribute.retired_by      = nil
  attribute.retire_reason   = nil
  attribute.searchable      = 0
  attribute.save
  end

  def self.down
  attribute = PersonAttributeType.find_by_name("NEAREST HEALTH FACILITY")
  attribute.delete
  end
end
