class CreateClinicSchedule < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE `clinic_schedule` (`clinic_schedule_id` int(11) NOT NULL AUTO_INCREMENT, `voided` tinyint(1) NOT NULL DEFAULT '0', `location_id` int(11) NOT NULL DEFAULT '0', `clinic_name_id` int(11) NOT NULL DEFAULT '0', `clinic_day_id` int(11) NOT NULL DEFAULT '0', `created_by` int(11) NOT NULL DEFAULT '0', `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00', `changed_by` int(11) DEFAULT NULL, `date_changed` datetime DEFAULT NULL, `voided_by` int(11) DEFAULT NULL, `date_voided` datetime DEFAULT NULL, `void_reason` varchar(255) DEFAULT NULL, PRIMARY KEY (`clinic_schedule_id`), KEY `locations` (`location_id`), KEY `clinic_days` (`clinic_day_id`), KEY `clinic_names` (`clinic_name_id`), KEY `clinic_schedule_creators` (`created_by`), KEY `clinic_schedule_mutators` (`changed_by`), KEY `clinic_schedule_destructors` (`voided_by`), CONSTRAINT `locations` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`), CONSTRAINT `clinic_days` FOREIGN KEY (`clinic_day_id`) REFERENCES `concept` (`concept_id`), CONSTRAINT `clinic_names` FOREIGN KEY (`clinic_name_id`) REFERENCES `concept` (`concept_id`), CONSTRAINT `clinic_schedule_creators` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`), CONSTRAINT `clinic_schedule_mutators` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`), CONSTRAINT `clinic_schedule_destructors` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end

  def self.down
    drop_table:clinic_schedule
  end
end
