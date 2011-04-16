class CreateDrugIngredients < ActiveRecord::Migration
  def self.up
    create_table :drug_ingredients do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :drug_ingredients
  end
end
