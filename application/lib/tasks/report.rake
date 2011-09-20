require 'csv'


F_DATE = '%Y-%m-%d'
F_DATETIME = '%Y-%m-%d %H:%M:%S'
REPORTS_DIR = File.join(Rails.root, 'tmp', 'reports')

COMMON_COLUMNS = [
  ['CALL ID',     lambda { |c,p,e,oh| c.id } ],
  ['NATIONAL ID', lambda { |c,p,e,oh| p.national_id } ],
  ['GENDER',      lambda { |c,p,e,oh| p.gender } ],
  ['DOB',         lambda { |c,p,e,oh| p.person.birthdate.try(:strftime, F_DATE) } ],
  ['VILLAGE',     lambda { |c,p,e,oh| p.person.address } ],
  ['NEAREST HC',  lambda { |c,p,e,oh| p.person.get_attribute('NEAREST HEALTH FACILITY') } ],
  'PREGNANCY STATUS',
  'EXPECTED DUE DATE',
]

CSV_DEFINITIONS = [
  # {
  #   :encounters => [], # encounters types used to generate output. if a
  #                      # call provides any of these types then process it.
  #                      # :all will generate output on all encounters.
  #   :filename   => '', # filename to write to, passes through strftime()
  #   :columns    => [], # list of columns to include in CSV.  column will
  #                      # be pulled from observations if column is string,
  #                      # otherwise it is assumed to be an array containing
  #                      # a header name and a lamba:
  #                      # [ 'header', lambda(call, patient, encounters, observation_hash) {}]
  # }
  {
    :encounters  => :all,
    :filename    => 'call_log-%Y-%m-%d.csv',
    :columns     => COMMON_COLUMNS | [
      [ 'START TIME', lambda { |c,p,e,oh| c.start_time.try(:strftime, F_DATETIME) } ],
      [ 'END TIME',   lambda { |c,p,e,oh| c.end_time.try(:strftime, F_DATETIME) } ],
      [ 'CALL TYPE',  lambda { |c,p,e,oh| c.call_type } ],
    ],
  },
  {
    :encounters  => :all,
    :filename    => 'registrations-%Y-%m-%d.csv',
    :columns     => COMMON_COLUMNS | [
      ['IVR ACCESS CODE', lambda { |c,p,e,oh| p.ivr_access_code } ],
      ['DATE CREATED', lambda { |c,p,e,oh| p.date_created.strftime(F_DATETIME) } ],
      ['DATE CHANGED', lambda { |c,p,e,oh| p.date_changed.strftime(F_DATETIME) } ],
      ['CHANGED BY', lambda { |c,p,e,oh| User.find(p.changed_by).username } ],
      ['CELL PHONE', lambda { |c,p,e,oh| p.person.get_attribute('CELL PHONE NUMBER') } ],
      ['OCCUPATION', lambda { |c,p,e,oh| p.person.get_attribute('OCCUPATION') } ],
    ],
  },
  {
    :encounters  => ['UPDATE OUTCOME'],
    :filename    => 'update_outcomes-%Y-%m-%d.csv',
    :columns     => COMMON_COLUMNS | [
      'OUTCOME',
      'HEALTH FACILITY NAME',
      'REASON FOR REFERRAL',
    ],
  },
  {
    :encounters  => ['CHILD HEALTH SYMPTOMS'],
    :filename    => 'child_health_symptoms-%Y-%m-%d.csv',
    :columns     => COMMON_COLUMNS | [
      'DIARRHEA',
      'COUGH',
      'FAST BREATHING',
      'FEVER',
      'VOMITING',
      'CONVULSIONS SIGN',
      'CONVULSIONS SYMPTOM',
      'NOT EATING',
      'BOWEL MOVEMENTS',
      'GROWTH MILESTONES',
      'FEVER OF 7 DAYS OR MORE',
      'BLOOD IN STOOL',
      'NOT EATING OR DRINKING ANYTHING',
    ],
  },
  {
    :encounters  => ['MATERNAL HEALTH SYMPTOMS'],
    :filename    => 'maternal_health_symptoms-%Y-%m-%d.csv',
    :columns     => COMMON_COLUMNS | [
      'POSTNATAL BLEEDING',
      'FEVER DURING PREGNANCY SIGN',
      'FEVER DURING PREGNANCY SYMPTOM',
      'POSTNATAL FEVER SYMPTOM',
      'HEADACHES',
      'FITS OR CONVULSIONS SYMPTOM',
      'SWOLLEN HANDS OR FEET SYMPTOM',
      'HEALTHCARE VISITS',
      'NUTRITION',
      'BODY CHANGES',
      'DISCOMFORT',
      'CONCERNS',
      'WARNING SIGNS',
      'HEAVY VAGINAL BLEEDING DURING PREGNANCY',
      'EXCESSIVE POSTNATAL BLEEDING',
      'SEVERE HEADACHE',
    ],
  },
  {
    :encounters  => ['TIPS AND REMINDERS'],
    :filename    => 'tips_and_reminders-%Y-%m-%d.csv',
    :columns     => COMMON_COLUMNS | [
      'TELEPHONE NUMBER',
      'ON TIPS AND REMINDERS PROGRAM',
      'LANGUAGE PREFERENCE',
      'TYPE OF MESSAGE',
      'TYPE OF MESSAGE CONTENT',
    ],
  },
]

class EncounterCSV
  attr_accessor :encounters, :filename, :column

  def initialize(options={})
    @encounters = options[:encounters]
    @filename = DateTime.now.strftime(options[:filename])

    @columns = options[:columns].map do |column|
      case column
      when Array  then { :header => column[0], :method => column[1] }
      when String then { :header => column,    :method => nil }
      else column
      end
    end

    Dir.mkdir(REPORTS_DIR) unless File.directory?(REPORTS_DIR)
    @csv = CSV.open(File.join(REPORTS_DIR, @filename), 'wb')
    @csv << @columns.map {|c| c[:header]}
  end

  def write(call, encounters)
    return unless matching_encounters?(encounters)
    pruned = prune_encounters(encounters)

    patient = encounters.first.try(:patient) or return
    observations = pruned.map(&:observations).flatten.compact.select(&:concept)
    obs_hash = Hash[observations.map {|o| [o.concept.name, o.answer_string] }]

    values = @columns.map do |column|
      column[:method] ?
        column[:method].call(call, patient, pruned, obs_hash) :
        obs_hash[column[:header]]
    end

    @csv << values
  end

  def matching_encounters?(encounters)
    # any encounters found that are supported by this CSV formatter?
    return true if @encounters == :all
    encounters.select { |e| @encounters.include?(e.type.name) }.any?
  end

  def prune_encounters(encounters)
    # remove any duplicate encounters, giving preference to newest one
    used = []
    encounters.reverse.select do |encounter|
      type = encounter.type.name
      used.include?(type) ? false : (used << type && true)
    end.reverse
  end
end


namespace :report do
  desc "call log CSV reports"
  task :call_log_csv => :environment do
    writers = CSV_DEFINITIONS.map { |d| EncounterCSV.new(d) }

    CallLog.all.each do |call|
      encounters = call.encounters
      writers.each { |w| w.write(call, encounters) }
    end
  end

  desc "call log TXT report"
  task :call_log_txt => :environment do
    CallLog.all.each do |call|
      puts '-' * 78
      puts "Call ID: #{call.id} (type: #{call.call_type})"
      puts "Start Time: #{call.start_time}"
      puts "End Time: #{call.end_time}"
      puts 

      encounters = call.encounters
      if encounters.none?
        puts "NO ENCOUNTERS!"
        puts
        next
      end

      patient = encounters.first.patient
      person = patient.person

      puts "Patient Information:"
      puts "--------------------"
      puts "Patient ID: #{patient.id}"
      puts "Person: ID: #{person.id}"
      puts "Gender: #{person.gender}"
      puts "Birthdate: #{person.birthdate}"
      puts

      encounters.each do |encounter|
        puts (t = "Encounter #{encounter.id}:") + "\n" + ("-" * t.length)
        puts "Encounter Type: #{encounter.type.name}"
        puts "Encounter Date: #{encounter.encounter_datetime}"

        puts "Observations:"
        encounter.observations.each do |observation|
          puts " - #{observation.to_s}"
        end
        puts

      end
      puts
    end
  end
end
