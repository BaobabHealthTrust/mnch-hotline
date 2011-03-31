class Obs < OpenMRS
  set_table_name "obs"
  set_primary_key "obs_id"
  has_many :complex_obs, :foreign_key => :obs_id
  has_many :notes, :foreign_key => :obs_id
  has_many :concept_proposals, :foreign_key => :obs_id
  belongs_to :drug, :foreign_key => :value_drug
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :order, :foreign_key => :order_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :encounter, :foreign_key => :encounter_id
  belongs_to :location, :foreign_key => :location_id
  belongs_to :answer_concept, :class_name => "Concept", :foreign_key => :value_coded
end
