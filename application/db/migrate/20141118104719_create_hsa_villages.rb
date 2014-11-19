class CreateHsaVillages < ActiveRecord::Migration
  def self.up
    create_table :hsa_villages do |t|
      t.integer :hsa_id, :null => false
      t.integer :district_id , :null => false
      t.integer :health_center_id, :null => false
      t.integer :village_id, :null => false
     
      t.timestamps
    end
  end

  def self.down
    drop_table :hsa_villages
  end
end
