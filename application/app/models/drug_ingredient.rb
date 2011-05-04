require "composite_primary_keys"
class DrugIngredient < ActiveRecord::Base
  set_table_name "drug_ingredient"
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :ingredient, :foreign_key => :ingredient_id, :class_name => 'Concept'
  set_primary_keys :ingredient_id, :concept_id

  def to_fixture_name
    "#{concept.to_fixture_name}_contains_#{ingredient.to_fixture_name}"
  end
end
