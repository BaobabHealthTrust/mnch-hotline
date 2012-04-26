/*
  Please remember to replace 
    mnch_old with the name of the old hotline_database ,
    migrated_mnch with the name of the new hotline datasase [the one on which the metadata was run]

*/

#LOCK TABLES `migrated_mnch.concept_name_tag` WRITE;
INSERT INTO migrated_mnch.concept_name_tag(tag, description, creator, date_created, voided, uuid) VALUES
  ('DANGER SIGN', 'Tag for Danger Signs', 1, '2004-01-01T00:00:00', 0, (SELECT UUID())), 
  ('HEALTH INFORMATION', 'Tag for Health Information', 1, '2004-01-01T00:00:00', 0, (SELECT UUID())), 
  ('HEALTH SYMPTOM', 'Tag for Health Symptoms', 1, '2004-01-01T00:00:00', 0, (SELECT UUID()));
#UNLOCK TABLES;

#LOCK TABLES `migrated_mnch.concept_name_tag_map` WRITE;

INSERT INTO migrated_mnch.concept_name_tag_map(concept_name_id, concept_name_tag_id) VALUES
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FEVER OF 7 DAYS OR MORE" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "DIARRHEA FOR 14 DAYS OR MORE" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "BLOOD IN STOOL" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "COUGH FOR 21 DAYS OR MORE" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "CONVULSIONS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "NOT EATING OR DRINKING ANYTHING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "VOMITING EVERYTHING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "VERY SLEEPY OR UNCONSCIOUS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "POTENTIAL CHEST INDRAWING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "HEAVY VAGINAL BLEEDING DURING PREGNANCY" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "EXCESSIVE POSTNATAL BLEEDING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FEVER DURING PREGNANCY SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "POSTNATAL FEVER SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "SEVERE HEADACHE" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FITS OR CONVULSIONS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "SWOLLEN HANDS OR FEET SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "PALENESS OF THE SKIN AND TIREDNESS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "NO FETAL MOVEMENTS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "WATER BREAKS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "SLEEPING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FEEDING PROBLEMS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "CRYING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "BOWEL MOVEMENTS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "SKIN RASHES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "SKIN INFECTIONS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "UMBILICUS INFECTION" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "GROWTH MILESTONES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "ACCESSING HEALTHCARE SERVICES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "HEALTHCARE VISITS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "NUTRITION" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "BODY CHANGES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "DISCOMFORT" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "CONCERNS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "EMOTIONS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "WARNING SIGNS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "ROUTINES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "BELIEFS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "BABY'S GROWTH" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "MILESTONES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "PREVENTION" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FEVER" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "DIARRHEA" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "COUGH" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "CONVULSIONS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "NOT EATING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "VOMITING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "RED EYE" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FAST BREATHING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "VERY SLEEPY" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "UNCONSCIOUS" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "VAGINAL BLEEDING DURING PREGNANCY" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "POSTNATAL BLEEDING" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FEVER DURING PREGNANCY SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "POSTNATAL FEVER SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "HEADACHES" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FITS OR CONVULSIONS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "SWOLLEN HANDS OR FEET SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "PALENESS OF THE SKIN AND TIREDNESS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "NO FETAL MOVEMENTS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "WATER BREAKS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM"));
  
#UNLOCK TABLES;

INSERT INTO migrated_mnch.relationship_type (a_is_to_b, b_is_to_a, description, creator, date_created, uuid) VALUES
  ('Child','Parent','Where the guardian is a parent to the patient',1,(NOW()),(SELECT UUID())),
	('Grand child','Grand parent','Where the guardian is a grand parent to the patient',1,(NOW()),(SELECT UUID())),
	('Niece/Nephew','Aunt/Uncle','Where the guardian is an aunt or uncle to the patient',1,(NOW()),(SELECT UUID())),
	('Patient','Other relatives','Where the guardian is a relative (Other, not specified on the list)',1,(NOW()),(SELECT UUID()));

#This has to be removed;

#DELETE FROM encounter_type where encounter_type_id in (108,109,110);
	
UPDATE migrated_mnch.encounter SET encounter_type = (SELECT encounter_type_id FROM migrated_mnch.encounter_type WHERE name = (SELECT name from mnch_old.encounter_type where encounter_type_id = encounter_type));

#update the obs table;

#delete this concept, as it is a duplicate. To be removed when we get new meta data from concept server;

DELETE FROM migrated_mnch.concept_name_tag_map WHERE concept_name_id = 11403;

DELETE FROM migrated_mnch.concept_word WHERE concept_name_id = 11403;

DELETE FROM migrated_mnch.concept_name WHERE concept_name_id = 11403;

#end of delete

#DROP TABLE IF EXISTS migrated_mnch.concept_link;

#CREATE TABLE migrated_mnch.concept_link (
#  new_concept_id int(11),
#  description text,
#  old_concept_id int(11),
#  concept_name_id int(11)
#);

#INSERT INTO migrated_mnch.concept_link 
#(SELECT cn1.concept_id AS new_concept_id, cn1.name AS description, old.concept_id AS old_concept_id, cn1.concept_name_id AS concept_name_id
#FROM migrated_mnch.concept_name cn1
#	INNER JOIN (
#		SELECT distinct cn.name, cn.concept_id
#		FROM mnch_old.concept_name cn
#			INNER JOIN mnch_old.obs o
#			ON o.concept_id = cn.concept_id
#		where o.concept_id > 7000) old
#	ON old.name = cn1.name
#);

SET FOREIGN_KEY_CHECKS=0;

UPDATE migrated_mnch.obs o
SET o.concept_id = (	SELECT cn2.concept_id
			FROM migrated_mnch.concept_name cn2
			WHERE name = (	SELECT name 
					FROM mnch_old.concept_name 
					WHERE concept_id = o.concept_id LIMIT 1))
WHERE o.concept_id > 7000;

UPDATE migrated_mnch.obs o
SET o.value_coded_name_id = (	SELECT cn2.concept_name_id
				FROM migrated_mnch.concept_name cn2
				WHERE name = (	SELECT name 
						FROM mnch_old.concept_name 
						WHERE concept_name_id = o.value_coded_name_id))
WHERE o.value_coded > 7000 ;

UPDATE migrated_mnch.obs o
SET o.value_coded = (	SELECT cn2.concept_id
			FROM migrated_mnch.concept_name cn2
			WHERE concept_name_id = o.value_coded_name_id)
WHERE o.value_coded > 7000 ;

SET FOREIGN_KEY_CHECKS=1;

#DROP TABLE migrated_mnch.concept_link;

#end of obs table update

INSERT INTO migrated_mnch.person_attribute_type (name, description, creator, uuid) VALUES 
('NEAREST HEALTH FACILITY', "The person's nearest health facility", 1, (SELECT UUID()));

UPDATE migrated_mnch.person_attribute
SET person_attribute_type_id = (SELECT person_attribute_type_id FROM migrated_mnch.person_attribute_type WHERE name = 'NEAREST HEALTH FACILITY')
WHERE person_attribute_type_id = 20;

INSERT INTO migrated_mnch.patient_identifier_type (name, description, creator,uuid) VALUES 
('IVR Access Code', "Unique identifier for a particular patient. To be used for search purposes",1, (SELECT UUID()));

UPDATE migrated_mnch.patient_identifier
SET identifier_type = (SELECT patient_identifier_type_id FROM migrated_mnch.patient_identifier_type WHERE name = 'IVR Access Code')
WHERE identifier_type = 17;
