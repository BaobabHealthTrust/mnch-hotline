
-- ------------------------------------------------------
-- Server version	5.1.54-1ubuntu4-log
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Retrieving all last anc visit
CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `last_anc_visits` AS
    SELECT
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `last_visit_date`
    FROM
        (`encounter` `e`
        JOIN `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            AND (`o`.`concept_id` = 9457)
            AND (`o`.`voided` = 0))))
    WHERE
        ((`e`.`encounter_type` = 151)
            AND (`e`.`voided` = 0));

-- retrieving anc connect maximum dates
CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `anc_connect_max_edd_dates` AS
    SELECT
        `pp`.`patient_id`,
        (SELECT
                max(`ob`.`obs_id`)
            FROM
                `obs` `ob`
            WHERE
                `ob`.`person_id` = `pp`.`patient_id`
                    AND `ob`.`concept_id` = 6188
                    AND `ob`.`voided` = 0) AS `obs_id`
    FROM
        `patient_program` `pp`
    WHERE
        `pp`.`program_id` = 19 AND `voided` = 0;

-- Retrieving registered hsa_names

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `hsa_names` AS
    SELECT DISTINCT
        `hsa`.`hsa_id` AS `hsa_id`,
        `pn`.`given_name` AS `given_name`,
        `pn`.`family_name` AS `family_name`
    FROM
        (`hsa_villages` `hsa`
        JOIN `person_name` `pn` ON ((`pn`.`person_id` = `hsa`.`hsa_id`)));

-- Retrieving registered list_hsa_names

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `list_hsa_names` AS
    SELECT DISTINCT
        `hsa`.`hsa_id` AS `hsa_id`,
        `hsa`.`given_name` AS `given_name`,
        `hsa`.`family_name` AS `family_name`,
        concat(`hsa`.`family_name`, ' ', `hsa`.`given_name`) AS `hsa_full_name`
    FROM
        `hsa_names` `hsa`;

-- Retrieving max cell number for clients

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `max_cell_number` AS
    SELECT
        `pp`.`patient_id`,
        (SELECT
                max(`pa`.`person_attribute_id`)
            FROM
                `person_attribute` `pa`
            WHERE
                `pa`.`person_id` = `pp`.`patient_id`
                    AND `pa`.`person_attribute_type_id` = 12
                    AND `pa`.`voided` = 0) AS `pa_id`
    FROM
        `patient_program` `pp`
    WHERE
        `pp`.`program_id` = 19 AND `voided` = 0;

-- Retrieving next anc visits for clients

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `next_anc_visits` AS
    SELECT
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `next_visit_date`
    FROM
        (`encounter` `e`
        JOIN `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            AND (`o`.`concept_id` = 9459)
            AND (`o`.`voided` = 0))))
    WHERE
        ((`e`.`encounter_type` = 151)
            AND (`e`.`voided` = 0));

-- Retrieving Locations where Delivery took place

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `delivery_locations` AS
    SELECT
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `delivery_location`
    FROM
        (`encounter` `e`
        JOIN `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            AND (`o`.`concept_id` = 9455)
            AND (`o`.`voided` = 0))))
    WHERE
        ((`e`.`encounter_type` = 90)
            AND (`e`.`voided` = 0));

-- Retrieving Delivery Dates

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `delivery_dates` AS
    SELECT
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `delivery_date`
    FROM
        (`encounter` `e`
        JOIN `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            AND (`o`.`concept_id` = 8342)
            AND (`o`.`voided` = 0))))
    WHERE
        ((`e`.`encounter_type` = 90)
            AND (`e`.`voided` = 0));

-- Retrieving next visit date list

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `anc_connect_next_visit_date_list` AS
    SELECT
        `pp`.`patient_id`,
        (SELECT
                max(`ob`.`obs_id`)
            FROM
                `obs` `ob`
            WHERE
                `ob`.`person_id` = `pp`.`patient_id`
                    AND `ob`.`concept_id` = 9459
                    AND `ob`.`voided` = 0) AS `obs_id`
    FROM
        `patient_program` `pp`
    WHERE
        `pp`.`program_id` = 19 AND `voided` = 0;

-- Retrieving max expected due date

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `anc_connect_max_edd` AS
    SELECT
        `pp`.`patient_id`, `o`.`value_text` as `max_edd`
    FROM
        `anc_connect_max_edd_dates` `pp`
            LEFT JOIN
        `obs` `o` ON `pp`.`obs_id` = `o`.`obs_id`;

-- retrieving next visit dates

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `anc_connect_next_visit_date` AS
    SELECT
        `pp`.`patient_id`, `o`.`value_text` as `next_visit_date`
    FROM
        `anc_connect_next_visit_date_list` `pp`
            LEFT JOIN
        `obs` `o` ON `pp`.`obs_id` = `o`.`obs_id`;

-- Retriving current client cell number

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `patient_cell_number` AS
    SELECT
        `mcn`.`patient_id`, `pa`.`value` as `cell_phone_number`
    FROM
        `max_cell_number` `mcn`
            LEFT JOIN
        `person_attribute` `pa` ON `mcn`.`pa_id` = `pa`.`person_attribute_id`;

-- Retriving ANC Connect Clients

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `anc_connect_program_clients` AS
    SELECT
        `pa`.`person_id`,
        `pa`.`city_village`,
        `pa`.`county_district`,
        `pa`.`address2` AS `home_village`,
        `hsa`.`hsa_id`,
        `hsa`.`district_id` AS district,
        `pp`.`date_enrolled`,
		`pp`.`patient_id`,
        `pn`.`given_name`,
        `pn`.`family_name`,
        `pn`.`family_name_prefix`,
        `p`.`birthdate`,
        `pi`.`identifier` AS `anc_connect_id`,
		FLOOR((280 - DATEDIFF(DATE(`max_edd`.`max_edd`), CURDATE())) / 7) AS `gestation_age`,
        DATEDIFF(CURDATE(), `pp`.`date_enrolled`) AS `number_of_days_after_reg`,
        `hc`.`name` AS health_center,
        `max_edd`.`max_edd` AS edd,
        `next_visit_date`.`next_visit_date`,
        `pcn`.`cell_phone_number`
    FROM
        `person_address` `pa`
            LEFT JOIN
        `traditional_authority` `ta` ON `pa`.`county_district` = `ta`.`name`
            LEFT JOIN
        `village` `vg` ON `ta`.`traditional_authority_id` = `vg`.`traditional_authority_id`
            AND `pa`.`city_village` = `vg`.`name`
            LEFT JOIN
        `hsa_villages` `hsa` ON `hsa`.`village_id` = `vg`.`village_id`
            AND `ta`.`district_id` = `hsa`.`district_id`
            LEFT JOIN
        `health_center` `hc` ON `hsa`.`health_center_id` = `hc`.`health_center_id`
            AND `ta`.`district_id` = `hsa`.`district_id`
            LEFT JOIN
        `patient_program` `pp` ON `pa`.`person_id` = `pp`.`patient_id`
            AND `pp`.`voided` = 0
            LEFT JOIN
        `person_name` `pn` ON `pa`.`person_id` = `pn`.`person_id`
            AND `pn`.`voided` = 0
            LEFT JOIN
        `person` `p` ON `p`.`person_id` = `pa`.`person_id`
            AND `p`.`voided` = 0
            LEFT JOIN
        `patient_identifier` `pi` ON `pi`.`patient_id` = `pa`.`person_id`
            AND `pi`.`voided` = 0
            AND `pi`.`identifier_type` = 25
            LEFT JOIN
        `anc_connect_max_edd` `max_edd` ON `pa`.`person_id` = `max_edd`.`patient_id`
            LEFT JOIN
        `anc_connect_next_visit_date` `next_visit_date` ON `pa`.`person_id` = `next_visit_date`.`patient_id`
            LEFT JOIN
        `patient_cell_number` `pcn` ON `pa`.`person_id` = `pcn`.`patient_id`
    WHERE
        `pa`.`person_id` IN (SELECT
                `patient_id`
            FROM
                `patient_program`
            WHERE
                `program_id` = 19 AND `voided` = 0)
    GROUP BY `pa`.`person_id`;

-- Retrieving ANC VISITS

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `anc_visits` AS
    select
        `lvd`.`encounter_id` AS `encounter_id`,
        `lvd`.`patient_id` AS `patient_id`,
        `lvd`.`encounter_datetime` AS `encounter_datetime`,
        `lvd`.`obs_id` AS `last_visit_date_obs_id`,
        `lvd`.`last_visit_date` AS `last_visit_date`,
        `nvd`.`next_visit_date` AS `next_visit_date`,
        `nvd`.`obs_id` AS `next_visit_date_obs_id`,
        `p_clients`.`hsa_id` AS `hsa_id`,
        `p_clients`.`district` AS `district`
    from
        ((`last_anc_visits` `lvd`
        join `next_anc_visits` `nvd` ON ((`lvd`.`encounter_id` = `nvd`.`encounter_id`)))
        left join `anc_connect_program_clients` `p_clients` ON ((`lvd`.`patient_id` = `p_clients`.`person_id`)))
    order by `lvd`.`patient_id` , `lvd`.`obs_id`;

-- Retrieving Baby Deliveries

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY INVOKER
VIEW `baby_deliveries` AS
    select
        `d_dates`.`encounter_id` AS `encounter_id`,
        `d_dates`.`patient_id` AS `patient_id`,
        `d_dates`.`encounter_datetime` AS `encounter_datetime`,
        `d_dates`.`obs_id` AS `delivery_date_obs_id`,
        `d_dates`.`delivery_date` AS `delivery_date`,
        `d_location`.`delivery_location` AS `delivery_location`,
        `d_location`.`obs_id` AS `delivery_location_obs_id`,
        `p_clients`.`hsa_id` AS `hsa_id`,
        `p_clients`.`district` AS `district`
    from
        ((`delivery_dates` `d_dates`
        join `delivery_locations` `d_location` ON ((`d_dates`.`encounter_id` = `d_location`.`encounter_id`)))
        left join `anc_connect_program_clients` `p_clients` ON ((`d_dates`.`patient_id` = `p_clients`.`person_id`)));

-- Added these to fix the system slowness

DROP FUNCTION IF EXISTS `client_needs_followup`;

DELIMITER $$
CREATE FUNCTION `client_needs_followup`(my_patient_id INT, district_id INT, start_date DATETIME) RETURNS int(1)
BEGIN
	DECLARE gestation_age, registration_age INT;
	DECLARE next_visit_date DATETIME;
	DECLARE return_value INT;

	SET return_value = 0;

	SET gestation_age = (SELECT client_gestation_age(my_patient_id));
	SET next_visit_date = (SELECT client_next_anc_visit(my_patient_id));
	SET registration_age = (SELECT client_gestation_age(my_patient_id));

	IF (gestation_age < 42) AND (gestation_age > 0) AND (next_visit_date <= start_date) THEN
		SET return_value = 1;
	END IF;

	IF (return_value = 0) THEN
		IF (next_visit_date IS NULL) AND (gestation_age >= 21) THEN
			SET return_value = 1;
		END IF;
	END IF;

	RETURN return_value;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `client_last_anc_visit`;

DELIMITER $$
CREATE FUNCTION `client_last_anc_visit`(my_patient_id INT) RETURNS DATE
BEGIN
	DECLARE last_visit_date DATE;

	SET last_visit_date = (SELECT
        DATE(`o`.`value_text`)
    FROM
        `encounter` `e`
        JOIN `obs` `o` ON `o`.`encounter_id` = `e`.`encounter_id`
            AND `o`.`concept_id` = 9457
            AND `o`.`voided` = 0
			AND `o`.`person_id` = my_patient_id
    WHERE
        `e`.`encounter_type` = 151
		AND `e`.`voided` = 0
		AND `e`.`patient_id` = my_patient_id
		AND `e`.`encounter_id` = (SELECT max(`encounter_id`)
					FROM `encounter`
					WHERE
						`encounter_type` = 151
					AND `voided` = 0
					AND `patient_id` = my_patient_id ));

	RETURN last_visit_date;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS `client_next_anc_visit`;

DELIMITER $$
CREATE FUNCTION `client_next_anc_visit`(my_patient_id INT) RETURNS DATETIME
BEGIN
	DECLARE next_visit_date DATETIME;
	SET next_visit_date = (SELECT
        DATE(`o`.`value_text`)
    FROM
        `encounter` `e`
        JOIN `obs` `o` ON `o`.`encounter_id` = `e`.`encounter_id`
            AND `o`.`concept_id` = 9459
            AND `o`.`voided` = 0
			AND `o`.`person_id` = my_patient_id
    WHERE
        `e`.`encounter_type` = 151
		AND `e`.`voided` = 0
		AND `e`.`patient_id` = my_patient_id
		AND `e`.`encounter_id` = (SELECT max(`encounter_id`)
					FROM `encounter`
					WHERE
						`encounter_type` = 151
					AND `voided` = 0
					AND `patient_id` = my_patient_id ));

	RETURN next_visit_date;
END$$
DELIMITER ;
DROP FUNCTION IF EXISTS `client_edd`;

DELIMITER $$
CREATE FUNCTION `client_edd`(my_patient_id INT) RETURNS DATE
BEGIN
	DECLARE edd DATE;
	SET edd = (SELECT `value_text`
				FROM `obs`
				WHERE `obs_id` = (SELECT
										max(`obs_id`)
									FROM
										`obs`
									WHERE
										`person_id` = my_patient_id
										AND `concept_id` = 6188
										AND `voided` = 0)
					AND `person_id` = my_patient_id
				);
	RETURN edd;
END$$
DELIMITER ;
DROP FUNCTION IF EXISTS `client_gestation_age`;

DELIMITER $$
CREATE FUNCTION `client_gestation_age`(my_patient_id INT) RETURNS INT
BEGIN
	DECLARE gestation_age INT;

	SET gestation_age = (SELECT FLOOR((280 - DATEDIFF(DATE(client_edd(my_patient_id)), CURDATE())) / 7));
	RETURN gestation_age;
END$$

DELIMITER ;
DROP FUNCTION IF EXISTS `client_age_of_registration`;

DELIMITER $$
CREATE FUNCTION `client_age_of_registration`(my_patient_id INT) RETURNS INT
BEGIN
	DECLARE age_of_reg INT;

	SET age_of_reg = (SELECT DATEDIFF(CURDATE(), `date_enrolled`)
						FROM `patient_program`
						WHERE
							`patient_id` = my_patient_id
							AND `voided` = 0
							AND `program_id` = 19
					);
	RETURN age_of_reg;
END$$
DELIMITER ;
DROP FUNCTION IF EXISTS `client_next_visit_date`;

DELIMITER $$
CREATE FUNCTION `client_next_visit_date`(my_patient_id INT) RETURNS DATE
BEGIN
	DECLARE nvd DATE;
	SET nvd = (SELECT `value_text`
				FROM `obs`
				WHERE `obs_id` = (SELECT
										max(`obs_id`)
									FROM
										`obs`
									WHERE
										`person_id` = my_patient_id
										AND `concept_id` = 9459
										AND `voided` = 0)
					AND `person_id` = my_patient_id
				);
	RETURN nvd;
END$$
DELIMITER ;

--
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
