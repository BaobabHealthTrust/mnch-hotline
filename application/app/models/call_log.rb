class CallLog < ActiveRecord::Base
  set_table_name "call_log"
  set_primary_key "call_log_id"
  include Openmrs

  def observations
    concept = ConceptName.find_by_name('CALL ID').concept
    Observation.find(:all, :conditions => {
      :concept_id => concept.id,
      :value_text => id,
      :voided     => 0,
    })
  end

  def encounters
    observations.map(&:encounter).uniq
  end

end
