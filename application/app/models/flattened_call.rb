require 'forwardable'

# Flattened view of a call, including patient, encounter and observation data.
# Includes multiple ways of access values, via a hash or method syntax:
#   fc = FlattenedCall.new(CallLog.last)
#   fc.call_id
#   fc.pregnancy_status
#   fc['PREGNANCY STATUS']
#   fc.person.age
#
# Can provide a list of encounters instead of a call or can filter out
# irrelevant encounters you don't want observations for
#   fc = FlattenedCall.new(Encounter.where(...))
#        # ... but call and patient data is for first call only
#   fc = FlattenedCall.new(CallLog.last)
#   fc.encounter_types # => ["REGISTRATION", "TIPS AND REMINDERS"]
#   fc.obs_hash # => {...} (includes all encounters)
#   fc.filter!('TIPS AND REMINDERS')
#   fc.encounter_types # => ["TIPS AND REMINDERS"]
#   fc.obs_hash # => {...} (includes observations for only tips and reminders)
#

class FlattenedCall
  extend Forwardable

  def_delegators :call, :call_type
  def_delegator  :call, :call_log_id, :call_id
  def_delegator  :call, :start_time,  :call_start
  def_delegator  :call, :end_time,    :call_end

  def_delegators :patient, :national_id, :gender, :ivr_access_code
  def_delegator  :patient, :date_created, :patient_created

  def_delegator  :person, :birthdate, :dob
  def_delegator  :person, :address,   :village

  def_delegators :person_attrs, :occupation
  def_delegator  :person_attrs, :nearest_health_facility, :nearest_hc
  def_delegator  :person_attrs, :cell_phone_number, :person_cell_phone

  def_delegators :obs_hash, :pregnancy_status, :expected_due_date

  # update outcome encounters
  def_delegators :obs_hash, :outcome, :health_facility_name,
    :reason_for_referral

  # tips and reminders encounters
  def_delegators :obs_hash, :on_tips_and_reminders_program,
    :telephone_number, :phone_type, :type_of_message, :language_preference,
    :type_of_message_content

  # cold symptoms observations
  def_delegators :obs_hash, :fever, :diarrhea, :cough, :convulsions_symptom,
    :not_eating, :vomiting, :red_eye, :fast_breathing, :very_sleepy,
    :unconscious

  # child signs observations
  def_delegators :obs_hash, :fever_of_7_days_or_more,
    :cough_for_21_days_or_more, :blood_in_stool,
    :red_eye_for_4_days_or_more_with_visual_problems,
    :not_eating_or_drinking_anything, :very_sleepy_or_unconscious,
    :potential_chest_indrawing, :diarrhea_for_14_days_or_more,
    :convulsions_sign, :vomiting_everything

  # child info observations
  def_delegators :obs_hash, :sleeping, :growth_milestones, :feeding_problems,
    :skin_infections, :crying, :bowel_movements, :umbilicus_infection,
    :skin_rashes, :accessing_healthcare_services

  # maternal symptoms observations
  def_delegators :obs_hash, :no_fetal_movements_symptom,
    :fits_or_convulsions_symptom, :paleness_of_the_skin_and_tiredness_symptom,
    :water_breaks_symptom, :fever_during_pregnancy_symptom,
    :vaginal_bleeding_during_pregnancy, :postnatal_fever_symptom, :headaches,
    :swollen_hands_or_feet_symptom, :postnatal_bleeding

  # maternal signs observations
  def_delegators :obs_hash, :postnatal_fever_sign, :fits_or_convulsions_sign,
    :heavy_vaginal_bleeding_during_pregnancy,
    :paleness_of_the_skin_and_tiredness_sign, :excessive_postnatal_bleeding,
    :severe_headache, :swollen_hands_or_feet_sign, :no_fetal_movements_sign,
    :fever_during_pregnancy_sign, :water_breaks_sign

  def_delegators :obs_hash, :routines, :discomfort, :nutrition,
    :warning_signs, :healthcare_visits, :baby_s_growth, :milestones,
    :concerns, :prevention, :body_changes, :emotions, :beliefs


  def initialize(call_or_encounters, encounters = nil)
    if call_or_encounters.kind_of?(CallLog)
      @call, @encounters = call_or_encounters, encounters
    else
      @encounters = call_or_encounters.to_a
    end
  end

  def [](key)
    self.send(methodize(key))
  end

  def methodize(value)
    MethodizedHash::methodize(value)
  end

  def filter!(*encounter_types)
    @encounters = encounters.select {|e| encounter_types.include?(e.name) }
    @encounter_types, @observations, @obs_hash = nil
    self
  end

  def encounter_types
    @encounter_types ||= encounters.map(&:name)
  end

  def encounters
    @encounters ||= @call.encounters
  end

  def patient
    @patient ||= encounters.any? ? encounters.first.patient : Patient.new
  end

  def person
    @person ||= patient.person || Person.new
  end

  def person_attrs
    return @person_attrs if @person_attrs
    mapped_attrs = person.person_attributes.map {|a| [a.type.name, a.value]}
    @person_attrs = MethodizedHash[person.attributes.to_a | mapped_attrs]
  end

  def observations
    # only includes observations with an attached concept name
    @observations ||= encounters.map(&:observations).flatten.select(&:concept)
  end

  def obs_hash
    @obs_hash ||= MethodizedHash[observations.map {|o| [o.concept.name, o.answer_string]}]
  end

  def call
    @call ||= obs_hash.call_id ? CallLog.find(obs_hash.call_id) : CallLog.new
  end

end
