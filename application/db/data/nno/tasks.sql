-- MySQL dump 10.13  Distrib 5.1.49, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: bart
-- ------------------------------------------------------
-- Server version	5.1.49-1ubuntu8.1

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

--
-- Table structure for table `task`
--

DROP TABLE IF EXISTS `task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task` (
  `task_id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `encounter_type` varchar(255) DEFAULT NULL,
  `description` text,
  `location` varchar(255) DEFAULT NULL,
  `gender` varchar(50) DEFAULT NULL,
  `has_obs_concept_id` int(11) DEFAULT NULL,
  `has_obs_value_coded` int(11) DEFAULT NULL,
  `has_obs_value_drug` int(11) DEFAULT NULL,
  `has_obs_value_datetime` datetime DEFAULT NULL,
  `has_obs_value_numeric` double DEFAULT NULL,
  `has_obs_value_text` text,
  `has_obs_scope` text,
  `has_program_id` int(11) DEFAULT NULL,
  `has_program_workflow_state_id` int(11) DEFAULT NULL,
  `has_identifier_type_id` int(11) DEFAULT NULL,
  `has_relationship_type_id` int(11) DEFAULT NULL,
  `has_order_type_id` int(11) DEFAULT NULL,
  `has_encounter_type_today` varchar(255) DEFAULT NULL,
  `skip_if_has` smallint(6) DEFAULT '0',
  `sort_weight` double DEFAULT NULL,
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `voided` smallint(6) DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `changed_by` int(11) DEFAULT NULL,
  `date_changed` datetime DEFAULT NULL,
  `uuid` char(38) DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  KEY `task_creator` (`creator`),
  KEY `user_who_voided_task` (`voided_by`),
  KEY `user_who_changed_task` (`changed_by`),
  CONSTRAINT `task_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_changed_task` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_voided_task` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task`
--

LOCK TABLES `task` WRITE;
/*!40000 ALTER TABLE `task` DISABLE KEYS */;
INSERT INTO `task` (url, description, encounter_type, location, has_obs_scope, skip_if_has, sort_weight, gender,creator, date_created) VALUES 
("/encounters/new/registration?patient_id={patient}", "Registration for every location", "REGISTRATION", "*", "*", "0", "1", "nil", 1, NOW()),
("/encounters/new/female_symptoms?patient_id={patient}", "Get female health symptoms for all female adult patients", "MATERNAL HEALTH SYMPTOMS", "MNCH Hotline Station", "TODAY", "0", "2", "F", 1, NOW()),
("/encounters/new/pregnancy_status?patient_id={patient}", "Get pregnancy status if the patient is female adult", "PREGNANCY STATUS", "MNCH Hotline Station", "TODAY", "0", "3", "F", 1, NOW()),
("/encounters/new/child_symptoms?patient_id={patient}", "Get child health symptoms if the patient is a child (either gender)", "CHILD HEALTH SYMPTOMS", "MNCH Hotline Station", "TODAY", "0", "4", "*", 1, NOW()),
("/encounters/new/outcome?patient_id={patient}", "Record an outcome if symptoms have been collected", "UPDATE OUTCOME", "MNCH Hotline Station", "TODAY", "0", "5", "nil", 1, NOW()),
("/encounters/new/tips_and_reminders?patient_id={patient}", "Record tips and reminders preferences", "TIPS AND REMINDERS", "MNCH Hotline Station", "TODAY", "0", "6", "nil", 1, NOW()),
("/patients/show/{patient}", "Everything is finished, go to the patient dashboard", "nil", "*", "*", "0", "1000", "nil", 1, NOW());

/*!40000 ALTER TABLE `task` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-03-22 12:41:58
