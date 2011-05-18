class ClinicSchedule < ActiveRecord::Base
  set_table_name  :clinic_schedule
  set_primary_key :clinic_schedule_id
  include Openmrs

  belongs_to  :location,    :class_name => :location, :foreign_key => :location_id,     :conditions => {:voided => 0}
  belongs_to  :clinic_day,  :class_name => :concept,  :foreign_key => :clinic_day_id,   :conditions => {:voided => 0}
  belongs_to  :clinic_name, :class_name => :concept,  :foreign_key => :clinic_name_id,  :conditions => {:voided => 0}

  def self.create(params)
    schedule        = ClinicSchedule.new()
    clinic_day      = params['clinic_day']
    health_facility = params['health_facility']
    clinic_name     = params['clinic_name']

#  + " " + "CLINIC"

    schedule.location_id     = Location.find_by_name(health_facility).id
    schedule.clinic_day_id   = Concept.find_by_name(clinic_day).concept_id
    schedule.clinic_name_id   = Concept.find_by_name(clinic_name).concept_id
    schedule.created_by       = User.current_user

    schedule.save
  end

  def self.health_facilities
    mnch_location_tag_id = LocationTag.find_by_tag("mnch_health_facilities").id
    Location.find(:all,
        :joins => "INNER JOIN location_tag_map ltm ON ltm.location_id = location.location_id",
        :conditions =>["location_tag_id = ?", mnch_location_tag_id])
  end

  def self.health_facilities_list
    facilities = ClinicSchedule.health_facilities.map(&:name).inject([]) do |facility_list, facilities|
      facility_list.push(facilities.upcase)
    end
    facilities
  end

  def self.week_days(days = nil)
    week_days_list = {}

    days = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"] if days.nil?

    days.each { |day| week_days_list[day.downcase.to_sym] = Concept.find_by_name(day).concept_id rescue nil }

    return week_days_list
  end

  def self.clinic_schedules_by_health_facility(health_facility)
    location_id     = Location.find_by_name(health_facility).id
    ClinicSchedule.find(:all,
      :joins => "INNER JOIN location ON clinic_schedule.location_id = location.location_id \
                 INNER JOIN concept_name clinic_name ON clinic_schedule.clinic_name_id = clinic_name.concept_id \
                 INNER JOIN concept_name clinic_day ON clinic_schedule.clinic_day_id  = clinic_day.concept_id",
      :conditions => ["location.location_id = ?", location_id],
      :group => "clinic_schedule.clinic_schedule_id")
  end

  def self.format_clinic_schedules(clinic_schedules, clinic_list)
      schedules = {}
    clinic_list.map do |clinic|
      clinic_name    = clinic #+ " " + "CLINIC"
      clinic_name_id = Concept.find_by_name(clinic_name).concept_id rescue nil

      clinic_schedules.each do |clinic_schedule|
        if clinic_schedule.clinic_name_id == clinic_name_id
          clinic_day_id = clinic_schedule.clinic_day_id
          if schedules[clinic].nil?
            schedules[clinic]                 = {clinic_day_id => "", "day" => []}
            schedules[clinic][clinic_day_id]  = [clinic_schedule.clinic_schedule_id]
            schedules[clinic]["day"]          = [clinic_schedule.clinic_day_id]
          else
            schedules[clinic][clinic_day_id]  = [clinic_schedule.clinic_schedule_id]
            schedules[clinic]["day"].push(clinic_schedule.clinic_day_id)
          end
        end
      end
    end
    schedules
  end

  def self.clinic_list
    clinic_list = GlobalProperty.find_by_property("health_facility.clinic_list").property_value rescue nil
    clinic_list = clinic_list.split(", ").sort unless clinic_list.nil?
  end
end

