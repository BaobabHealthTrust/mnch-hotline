class GenerateMnchTasksList < ActiveRecord::Migration
  def self.up
    encounter_types = ["REGISTRATION","PREGNANCY STATUS",
                        "MATERNAL HEALTH SYMPTOMS", "CHILD HEALTH SYMPTOMS",
                        "UPDATE OUTCOME", "TIPS AND REMINDERS", nil]

    urls = ["/encounters/new/registration?patient_id={patient}",
            "/encounters/new/pregnancy_status?patient_id={patient}",
            "/encounters/new/female_symptoms?patient_id={patient}",
            "/encounters/new/child_symptoms?patient_id={patient}", 
            "/encounters/new/outcome?patient_id={patient}",
            "/encounters/new/tips_and_reminders?patient_id={patient}",
            "/patients/show/{patient}"]

    locations = ["*","MNCH Hotline Station", "MNCH Hotline Station",
                  "MNCH Hotline Station", "MNCH Hotline Station",
                  "MNCH Hotline Station","*"]

    has_obs_scopes  = ["*", "TODAY", "TODAY", "TODAY",
                        "TODAY", "TODAY", "*"]

    skips_if_has    = ["0", "0", "0", "0", "0", "0", "0"]

    sort_weights    = ["1", "2", "3", "4", "5", "6", "1000"]
    
    genders         = [nil, "F", "F", "*", nil, nil, nil]

    descriptions    = ["Registration for every location",
                        "Get pregnancy status if the patient is female adult",
                        "Get female health symptoms for all female adult patients",
                        "Get child health symptoms if the patient is a child (either gender)",
                        "Record an outcome if symptoms have been collected",
                        "Record tips and reminders preferences",
                        "Everything is finished, go to the patient dashboard"]

    encounter_types.each_with_index do |encounter_type, index|
      task                = Task.new()
      task.url            = urls[index]
      task.description    = descriptions[index]
      task.encounter_type = encounter_type
      task.location       = locations[index]
      task.has_obs_scope  = has_obs_scopes[index]
      task.gender         = genders[index]
      task.skip_if_has    = skips_if_has[index]
      task.sort_weight    = sort_weights[index]
      task.creator        = 1
      task.save
    end
  
  end

  def self.down
    all_tasks = Task.all(:conditions => ["location =?", "MNCH Hotline Station"], :order => 'sort_weight ASC')
    all_tasks.each{|task| task.delete}
  end
end
