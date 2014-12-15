
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

-- retrieving the max patient's EDD
CREATE OR REPLACE ALGORITHM=UNDEFINED  SQL SECURITY INVOKER
  VIEW `max_edd` AS
  SELECT `obs`.`obs_id`, `obs`.`person_id`, `obs`.`value_text` FROM `obs` `obs` 
  WHERE  `obs`.`obs_id` = (SELECT max(`ob`.`obs_id`) 
                           FROM `obs` `ob`
                           WHERE `ob`.`person_id` = `obs`.`person_id`
			                     AND `ob`.`concept_id` = 6188
                           AND `ob`.`voided` = 0);

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
    `o`.`concept_id`,
    `o`.`value_text` as `edd`,
    floor((280 - DATEDIFF(DATE(`o`.`value_text`), CURDATE())) / 7) as `gestation_age`,
    DATEDIFF(CURDATE(),`pp`.`date_enrolled`) as `number_of_days_after_reg`,
    `pp`.`date_enrolled`,
    `nvd`.`value_text` as `next_visit_date`,
    `cl`.`district`
   FROM
    `encounter` `e`
        INNER JOIN
    `person_name` `pn` ON `e`.`patient_id` = `pn`.`person_id`
        INNER JOIN
    `person_address` `pa` ON `e`.`patient_id` = `pa`.`person_id`
        INNER JOIN
    `person` `p` ON `p`.`person_id` = `e`.`patient_id`
        INNER JOIN
    `patient_program` `pp` ON `pp`.`patient_id` = `e`.`patient_id`
        INNER JOIN
    `obs` `o` ON `o`.`encounter_id` = `e`.`encounter_id`
        INNER JOIN
    `obs` `obs_call` ON `o`.`encounter_id` = `obs_call`.`encounter_id`
        AND `obs_call`.`concept_id` = 8304
        INNER JOIN
    `call_log` `cl` ON `obs_call`.`value_text` = `cl`.`call_log_id`
        LEFT JOIN
    `max_next_visit_date` `nvd` ON `nvd`.`person_id` = `e`.`patient_id`
        INNER JOIN `max_edd` `edd` ON `edd`.`person_id` = `e`.`patient_id`;

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
