DELIMITER $$

DROP PROCEDURE IF EXISTS `update_table_columns`$$

CREATE PROCEDURE`update_table_columns`()

        BEGIN
        	IF NOT EXISTS((SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
				AND COLUMN_NAME='district' AND TABLE_NAME='call_log')) THEN
			ALTER TABLE `call_log` ADD COLUMN `district` INT(11) NOT NULL  DEFAULT 0 ;
		END IF;
		IF NOT EXISTS((SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
				AND COLUMN_NAME='call_mode' AND TABLE_NAME='call_log')) THEN
			ALTER TABLE `call_log` ADD COLUMN `call_mode` INT(11) NOT NULL DEFAULT 0 ;
		END IF;
		
	END$$

DELIMITER ;

CALL update_table_columns;

-- update district for old calls to 30 which is balaka as they were from blk
UPDATE call_log SET district = 30;

-- Add Global Properties
INSERT IGNORE INTO global_property (property, property_value, `description`, uuid) VALUES ('current_districts', 'Chikwawa,Balaka,Mwanza', 'Districts from which callers are from in Hotline system', (SELECT UUID()));

INSERT IGNORE INTO global_property (property, property_value, `description`, uuid) VALUES ('call_mode', 'New,Repeat', 'Call Type whether New or Repeat', (SELECT UUID()));

-- DROP update_table_columns PROCEDURE

DROP PROCEDURE IF EXISTS `update_table_columns`;

-- Create a Village Headman table

CREATE TABLE `village_headman` (
  `village_headman_id` int(11) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `traditional_authority_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`village_headman_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Create a Health Center table

CREATE TABLE `health_center` (
  `health_center_id` int(11) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `district` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`village_headman_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*

Dumped the following tables from openmrs 1.7
 - District
 - Traditional Authority
 - Village
 - Region

Other tables to be created are:
 - Health Centres (mapped to district)
 - village headman (mapped to TAs)

TODO

- write a script to add all the village headmen
- create interface for entering health centers in the administration mode
*/
