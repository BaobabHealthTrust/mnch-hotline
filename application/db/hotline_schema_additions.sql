
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

-- retrieving the max patient's next visit date
CREATE OR REPLACE ALGORITHM=UNDEFINED  SQL SECURITY INVOKER
  VIEW `max_next_visit_date` AS
  SELECT `obs`.`obs_id`, `obs`.`person_id`, `obs`.`value_text` FROM `obs` `obs` 
  WHERE  `obs`.`obs_id` = (SELECT max(`ob`.`obs_id`) 
                           FROM `obs` `ob`
                           WHERE `ob`.`person_id` = `obs`.`person_id`
			                     AND `ob`.`concept_id` = 9459
                           AND `ob`.`voided` = 0);

-- retrieving district using hsa
CREATE OR REPLACE ALGORITHM=UNDEFINED  SQL SECURITY INVOKER
  VIEW `hsa_district` AS
  SELECT `e`.`encounter_id`, `e`.`patient_id`, `hsa`.`hsa_id`, `hsa`.`district_id`, `hsa`.`village_id`, `vg`.`name` 
    FROM `encounter` `e`
      INNER JOIN `hsa_villages` `hsa` ON `hsa`.`hsa_id` = `e`.`provider_id` AND `e`.`voided` = 0
      INNER JOIN `village` `vg` ON `vg`.`village_id` = `hsa`.`village_id`
    WHERE  `e`.`encounter_type` = 111;                           

-- retrieving the max patient's EDD
CREATE OR REPLACE ALGORITHM=UNDEFINED  SQL SECURITY INVOKER
  VIEW `max_edd` AS
  SELECT `obs`.`obs_id`, `obs`.`person_id`, `obs`.`value_text` FROM `obs` `obs` 
  WHERE  `obs`.`obs_id` = (SELECT max(`ob`.`obs_id`) 
                           FROM `obs` `ob`
                           WHERE `ob`.`person_id` = `obs`.`person_id`
			                     AND `ob`.`concept_id` = 6188
                           AND `ob`.`voided` = 0)
  GROUP BY `obs`.`person_id`;                           

-- retrieving all clients on ANC Connect program
CREATE OR REPLACE ALGORITHM=UNDEFINED  SQL SECURITY INVOKER
  VIEW `anc_connect_program_clients` AS
  SELECT 
    `e`.`patient_id`,
    `pn`.`given_name`,
    `pn`.`family_name`,
    `pn`.`family_name_prefix`,
    `pa`.`city_village`,
    `pa`.`county_district`,
    `pa`.`address2` AS `home_village`,
    `p`.`birthdate`,
    `pat`.`value` AS `cell_phone_number`,
    `pi`.`identifier` AS `anc_connect_id`,
    `e`.`encounter_id`,
    `o`.`concept_id`,
    `edd`.`value_text` AS `edd`,
    floor((280 - DATEDIFF(DATE(`edd`.`value_text`), CURDATE())) / 7) as `gestation_age`,
    DATEDIFF(CURDATE(),`pp`.`date_enrolled`) as `number_of_days_after_reg`,
    `pp`.`date_enrolled`,
    `nvd`.`value_text` as `next_visit_date`,
    IFNULL(`cl`.`district`,`hsa`.`district_id`) AS `district`,
    `hsa`.`hsa_id`, 
    `hsa`.`district_id` AS textIT_district`
    
   FROM
    `encounter` `e`
        INNER JOIN
    `person_name` `pn` ON `e`.`patient_id` = `pn`.`person_id`
        INNER JOIN
    `person_address` `pa` ON `e`.`patient_id` = `pa`.`person_id`
        INNER JOIN
    `person` `p` ON `p`.`person_id` = `e`.`patient_id`
        INNER JOIN
    `patient_program` `pp` ON `pp`.`patient_id` = `e`.`patient_id` and `pp`.`voided` = 0
        INNER JOIN
    `obs` `o` ON `o`.`encounter_id` = `e`.`encounter_id` and `e`.`voided` = 0
        LEFT JOIN
    `obs` `obs_call` ON `o`.`encounter_id` = `obs_call`.`encounter_id`
        AND `obs_call`.`concept_id` = 8304 and `obs_call`.`voided` = 0
        LEFT JOIN
    `call_log` `cl` ON `obs_call`.`value_text` = `cl`.`call_log_id`
    INNER JOIN `max_edd` `edd` ON `edd`.`person_id` = `e`.`patient_id`
        LEFT JOIN
    `max_next_visit_date` `nvd` ON `nvd`.`person_id` = `e`.`patient_id`
       LEFT JOIN `hsa_district` `hsa` ON `hsa`.`hsa_id` = `e`.`provider_id` AND `pa`.`city_village` = `hsa`.`name`
     LEFT JOIN `person_attribute`  `pat` ON `pat`.`person_id` = `e`.`patient_id` AND `pat`.`person_attribute_type_id` = 12 AND `pat`.`voided` = 0
     LEFT JOIN `patient_identifier` `pi` ON `pi`.`patient_id` = `e`.`patient_id` AND `pi`.`identifier_type` = 25 AND `pi`.`voided` = 0
       
  WHERE `o`.`concept_id` = 6188;
    
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
