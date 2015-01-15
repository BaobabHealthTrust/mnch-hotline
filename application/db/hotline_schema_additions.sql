
-- Host: localhost    Database: bart2
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


CREATE OR REPLACE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY INVOKER
VIEW `last_anc_visits` AS
    select 
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `last_visit_date`
    from
        (`encounter` `e`
        join `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            and (`o`.`concept_id` = 9457)
            and (`o`.`voided` = 0))))
    where
        ((`e`.`encounter_type` = 151)
            and (`e`.`voided` = 0));

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

CREATE OR REPLACE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY INVOKER
VIEW `next_anc_visits` AS
    select 
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `next_visit_date`
    from
        (`encounter` `e`
        join `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            and (`o`.`concept_id` = 9459)
            and (`o`.`voided` = 0))))
    where
        ((`e`.`encounter_type` = 151)
            and (`e`.`voided` = 0));

CREATE OR REPLACE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY INVOKER
VIEW `delivery_locations` AS
    select 
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `delivery_location`
    from
        (`encounter` `e`
        join `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            and (`o`.`concept_id` = 9455)
            and (`o`.`voided` = 0))))
    where
        ((`e`.`encounter_type` = 90)
            and (`e`.`voided` = 0));


CREATE OR REPLACE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY INVOKER
VIEW `delivery_dates` AS
    select 
        `e`.`encounter_id` AS `encounter_id`,
        `e`.`patient_id` AS `patient_id`,
        `e`.`encounter_datetime` AS `encounter_datetime`,
        `o`.`obs_id` AS `obs_id`,
        `o`.`value_text` AS `delivery_date`
    from
        (`encounter` `e`
        join `obs` `o` ON (((`o`.`encounter_id` = `e`.`encounter_id`)
            and (`o`.`concept_id` = 8342)
            and (`o`.`voided` = 0))))
    where
        ((`e`.`encounter_type` = 90)
            and (`e`.`voided` = 0));

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

CREATE OR REPLACE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY INVOKER
VIEW `anc_connect_program_clients` AS
    select 
        `pa`.`person_id`,
        `pa`.`city_village`,
        `pa`.`county_district`,
        `pa`.`address2` AS `home_village`,
        `hsa`.`hsa_id`,
        `hsa`.`district_id` AS district,
        `pp`.`date_enrolled`,
        `pn`.`given_name`,
        `pn`.`family_name`,
        `pn`.`family_name_prefix`,
        `p`.`birthdate`,
        `pi`.`identifier` AS `anc_connect_id`,
        DATEDIFF(CURDATE(), `pp`.`date_enrolled`) AS `number_of_days_after_reg`,
        `hc`.`name` AS health_center,
        `max_edd`.`max_edd` AS edd,
        `next_visit_date`.`next_visit_date`,
        `pcn`.`cell_phone_number`
    FROM
        `person_address` `pa`
            left join
        `traditional_authority` `ta` ON `pa`.`county_district` = `ta`.`name`
            left join
        `village` `vg` ON `ta`.`traditional_authority_id` = `vg`.`traditional_authority_id`
            AND `pa`.`city_village` = `vg`.`name`
            left join
        `hsa_villages` `hsa` ON `hsa`.`village_id` = `vg`.`village_id`
            and `ta`.`district_id` = `hsa`.`district_id`
            LEFT JOIN
        `health_center` `hc` ON `hsa`.`health_center_id` = `hc`.`health_center_id`
            and `ta`.`district_id` = `hsa`.`district_id`
            left join
        `patient_program` `pp` ON `pa`.`person_id` = `pp`.`patient_id`
            and `pp`.`voided` = 0
            left join
        `person_name` `pn` ON `pa`.`person_id` = `pn`.`person_id`
            and `pn`.`voided` = 0
            left join
        `person` `p` ON `p`.`person_id` = `pa`.`person_id`
            and `p`.`voided` = 0
            left join
        `patient_identifier` `pi` ON `pi`.`patient_id` = `pa`.`person_id`
            and `pi`.`voided` = 0
            and `pi`.`identifier_type` = 25
            left join
        `anc_connect_max_edd` `max_edd` ON `pa`.`person_id` = `max_edd`.`patient_id`
            left join
        `anc_connect_next_visit_date` `next_visit_date` ON `pa`.`person_id` = `next_visit_date`.`patient_id`
            left join
        `patient_cell_number` `pcn` ON `pa`.`person_id` = `pcn`.`patient_id`
    where
        `pa`.`person_id` IN (select 
                `patient_id`
            from
                `patient_program`
            where
                `program_id` = 19 and `voided` = 0)
    group by `pa`.`person_id`;


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


    
--
-- Dumping routines for database 'bart2'
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
