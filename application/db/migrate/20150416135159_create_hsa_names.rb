class CreateHsaNames < ActiveRecord::Migration
  def self.up
    create_table :all_hsa_names do |t|
      t.integer :hsa_id, :null => false
      t.string :given_name , :null => false
      t.string :family_name, :null => false
 
    end
  end

  def self.down
    drop_table :all_hsa_names
  end
end
