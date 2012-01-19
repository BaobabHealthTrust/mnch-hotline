require 'csv'
require 'delegate'

F_DATE = '%Y-%m-%d'
F_TIME = '%H:%M:%S'
F_DATETIME = '%Y-%m-%d %H:%M:%S'
REPORTS_DIR = File.join(Rails.root, 'tmp', 'reports')


namespace :report do
  desc "call log CSV reports"
  task :call_log_csv, [:start,:end] => :environment do |t,args|
    range_start, range_end = [:start,:end].map do |d|
      case args[d]
      when 'nil' then nil
      when /^(\d{4}-\d{2}-\d{2}(?: \d{2}:\d{2}:\d{2})?)$/ then $1
      when /^(\d{4}-\d{2})$/ then "#{$1}-01"
      else
        raise "invalid #{d}_date: #{args[d]} (format: YYYY-MM[-DD[ HH:MM:SS]] or nil)"
      end
    end

    cond = []
    cond << ['start_time >= ?', DateTime.parse(range_start)] if range_start
    cond << ['end_time < ?', DateTime.parse(range_end)] if range_end
    conditions = [cond.map(&:first).join(' AND '), *cond.map(&:last)]

    Dir.mkdir(REPORTS_DIR) unless File.directory?(REPORTS_DIR)
    Dir.chdir(REPORTS_DIR)

    reports = [
      CallLogCSV.new('call_log-%Y-%m-%d.csv'),
      RegistrationCSV.new('registrations-%Y-%m-%d.csv'),
      UpdateOutcomesCSV.new('update_outcomes-%Y-%m-%d.csv'),
      ChildHealthSymptomsCSV.new('child_health_symptoms-%Y-%m-%d.csv'),
      MaternalHealthSymptomsCSV.new('maternal_health_symptoms-%Y-%m-%d.csv'),
      TipsAndRemindersCSV.new('tips_and_reminders-%Y-%m-%d.csv'),
      OtherCallsCSV.new('other_calls-%Y-%m-%d.csv'),
    ]

    CallLog.find(:all, :conditions => conditions).each do |call|
      fc = FlattenedCall.new(call)
      reports.each {|r| r.write(fc) }
    end
  end
end


class FormattedCSV < SimpleDelegator
  def initialize(filename)
    @csv = CSV.open(DateTime.now.strftime(filename), 'wb')
    @col_defs = column_definitions # cache
    @record_delegator = self

    @csv << columns # header row
  end

  def [](key)
    fun = @col_defs[key]
    case
    when fun.nil? then self.send(methodize(key))
    when fun.arity < 1 then fun.call()
    else fun.call(self.send(methodize(key)))
    end
  end

  def include_if?(record)
    # predicate returning whether record should be included in CSV
    true
  end

  def columns
    []
  end

  def column_definitions
    {}
  end

  def write(record)
    return unless include_if?(record)
    @record_delegator.__setobj__(record)
    @csv << columns.map {|c| @record_delegator[c] }
  end
end


class EncounterCSV < FormattedCSV
  def include_if?(record)
    # only include if one or more encounters
    record.encounters.any?
  end

  def columns
    [ 'CALL ID', 'NATIONAL ID', 'GENDER', 'DOB', 'VILLAGE', 'NEAREST HC',
      'PREGNANCY STATUS', 'EXPECTED DUE DATE', 'CALL DATE'
    ]
  end

  def column_definitions
    { 'DOB'       => lambda {|v| v.try(:strftime, F_DATE) },
      'CALL DATE' => lambda { call_start.try(:strftime, F_DATE) },
    }
  end
end


class CallLogCSV < EncounterCSV
  def columns
    super | [ 'CALL TYPE', 'CALL DAY', 'START TIME', 'END TIME',
      'DURATION SEC', 'DURATION M:S'
    ]
  end

  def column_definitions
    super.merge({ 'CALL DAY'   => lambda { call_start.try(:strftime, '%A') },
      'START TIME' => lambda { call_start.try(:strftime, F_TIME) },
      'END TIME'   => lambda { call_end.try(:strftime, F_TIME) },
    })
  end

  def duration_sec
    (call_end - call_start).to_i if call_start && call_end
  end

  def duration_m_s
    seconds = duration_sec or return
    "#{seconds/60}:#{seconds%60}"
  end
end


class RegistrationCSV < EncounterCSV
  def columns
    super | ['IVR ACCESS CODE', 'DATE CREATED', 'CELL PHONE', 'OCCUPATION']
  end

  def column_definitions
    super.merge({
      'DATE CREATED' => lambda { patient_created.try(:strftime, F_DATETIME) },
      'CELL PHONE'   => lambda { person_cell_phone },
    })
  end
end


class UpdateOutcomesCSV < EncounterCSV
  def include_if?(record)
    record.encounter_types.include?('UPDATE OUTCOME')
  end

  def columns
    super | ['OUTCOME', 'HEALTH FACILITY NAME', 'REASON FOR REFERRAL']
  end
end


class ChildHealthSymptomsCSV < EncounterCSV
  # FIXME: refactor out the following concept names into Encounter model.
  # currently only available from within Encounter#health_symptoms_values.
  CHILD_SYMPTOMS = [
    'FEVER', 'DIARRHEA', 'COUGH', 'CONVULSIONS SYMPTOM', 'NOT EATING',
    'VOMITING', 'RED EYE', 'FAST BREATHING', 'VERY SLEEPY', 'UNCONSCIOUS'
  ]
  CHILD_SIGNS =  [
    'FEVER OF 7 DAYS OR MORE', 'DIARRHEA FOR 14 DAYS OR MORE',
    'BLOOD IN STOOL', 'COUGH FOR 21 DAYS OR MORE', 'CONVULSIONS SIGN',
    'NOT EATING OR DRINKING ANYTHING', 'VOMITING EVERYTHING',
    'RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS',
    'VERY SLEEPY OR UNCONSCIOUS', 'POTENTIAL CHEST INDRAWING'
  ]
  CHILD_INFO = [
    'SLEEPING', 'FEEDING PROBLEMS', 'CRYING', 'BOWEL MOVEMENTS',
    'SKIN RASHES', 'SKIN INFECTIONS', 'UMBILICUS INFECTION',
    'GROWTH MILESTONES', 'ACCESSING HEALTHCARE SERVICES'
  ]

  def include_if?(record)
    record.encounter_types.include?('CHILD HEALTH SYMPTOMS')
  end

  def columns
    super | CHILD_SYMPTOMS | CHILD_SIGNS | CHILD_INFO
  end
end


class MaternalHealthSymptomsCSV < EncounterCSV
  # FIXME: refactor out the following concept names into Encounter model.
  # currently only available from within Encounter#health_symptoms_values.
  MATERNAL_SYMPTOMS = [
    'VAGINAL BLEEDING DURING PREGNANCY', 'POSTNATAL BLEEDING',
    'FEVER DURING PREGNANCY SYMPTOM', 'POSTNATAL FEVER SYMPTOM', 'HEADACHES',
    'FITS OR CONVULSIONS SYMPTOM', 'SWOLLEN HANDS OR FEET SYMPTOM',
    'PALENESS OF THE SKIN AND TIREDNESS SYMPTOM',
    'NO FETAL MOVEMENTS SYMPTOM', 'WATER BREAKS SYMPTOM'
  ]
  MATERNAL_SIGNS = [
    'HEAVY VAGINAL BLEEDING DURING PREGNANCY', 'EXCESSIVE POSTNATAL BLEEDING',
    'FEVER DURING PREGNANCY SIGN', 'POSTNATAL FEVER SIGN', 'SEVERE HEADACHE',
    'FITS OR CONVULSIONS SIGN', 'SWOLLEN HANDS OR FEET SIGN',
    'PALENESS OF THE SKIN AND TIREDNESS SIGN', 'NO FETAL MOVEMENTS SIGN',
    'WATER BREAKS SIGN'
  ]
  MATERNAL_INFO = [
    'HEALTHCARE VISITS', 'NUTRITION', 'BODY CHANGES', 'DISCOMFORT',
    'CONCERNS', 'EMOTIONS', 'WARNING SIGNS', 'ROUTINES', 'BELIEFS',
    'BABY\'S GROWTH', 'MILESTONES', 'PREVENTION'
  ]

  def include_if?(record)
    record.encounter_types.include?('MATERNAL HEALTH SYMPTOMS')
  end

  def columns
    super | MATERNAL_SYMPTOMS | MATERNAL_SIGNS | MATERNAL_INFO
  end
end


class TipsAndRemindersCSV < EncounterCSV
  def include_if?(record)
    record.encounter_types.include?('TIPS AND REMINDERS')
  end

  def columns
    super | [
      'ON TIPS AND REMINDERS PROGRAM', 'TELEPHONE NUMBER', 'PHONE TYPE',
      'TYPE OF MESSAGE', 'LANGUAGE PREFERENCE', 'TYPE OF MESSAGE CONTENT',
    ]
  end
end


class OtherCallsCSV < FormattedCSV
  def include_if?(record)
    # completed calls with a non-normal call type
    record.call_start && record.call_end && record.call_type != 0
  end

  def columns
    ['CALL TYPE', 'START DATE', 'START TIME', 'END DATE', 'END TIME']
  end

  def column_definitions
    { 'START DATE' => lambda { call_start.try(:strftime, F_DATE) },
      'START TIME' => lambda { call_start.try(:strftime, F_TIME) },
      'END DATE'   => lambda { call_end.try(:strftime, F_DATE) },
      'END TIME'   => lambda { call_end.try(:strftime, F_TIME) },
    }
  end
end

