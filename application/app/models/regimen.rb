class Regimen < ActiveRecord::Base
  set_table_name "regimen"
  set_primary_key "regimen_id"
  include Openmrs
  belongs_to :concept, :conditions => {:retired => 0}
  belongs_to :program, :conditions => {:retired => 0}
  has_many :regimen_drug_orders # no default scope
  named_scope :program, lambda {|program_id| {:conditions => {:program_id => program_id}}}
  named_scope :criteria, lambda {|weight| {:conditions => ['min_weight <= ? AND max_weight >= ?', weight, weight]} unless weight.blank?}
end