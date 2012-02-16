
#LOCK TABLES `openmrs_mnch2.concept_name_tag` WRITE;
INSERT INTO openmrs_mnch.concept_name_tag(tag,description,creator,date_created,voided, uuid) VALUES
  ('DANGER SIGN', 'Tag for Danger Signs',1,'2004-01-01T00:00:00',0, (SELECT UUID())), 
  ('HEALTH INFORMATION', 'Tag for Health Information',1,'2004-01-01T00:00:00',0, (SELECT UUID())), 
  ('HEALTH SYMPTOM', 'Tag for Health Symptoms',1,'2004-01-01T00:00:00',0, (SELECT UUID()));
#UNLOCK TABLES;

#LOCK TABLES `openmrs_mnch2.concept_name_tag_map` WRITE;

INSERT INTO openmrs_mnch.concept_name_tag_map(concept_name_id, concept_name_tag_id) VALUES
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FEVER OF 7 DAYS OR MORE" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "DIARRHEA FOR 14 DAYS OR MORE" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "BLOOD IN STOOL" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "COUGH FOR 21 DAYS OR MORE" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "CONVULSIONS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "NOT EATING OR DRINKING ANYTHING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "VOMITING EVERYTHING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "RED EYE FOR 4 DAYS OR MORE WITH VISUAL PROBLEMS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "VERY SLEEPY OR UNCONSCIOUS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "POTENTIAL CHEST INDRAWING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "HEAVY VAGINAL BLEEDING DURING PREGNANCY" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "EXCESSIVE POSTNATAL BLEEDING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FEVER DURING PREGNANCY SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "POSTNATAL FEVER SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "SEVERE HEADACHE" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FITS OR CONVULSIONS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "SWOLLEN HANDS OR FEET SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "PALENESS OF THE SKIN AND TIREDNESS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "NO FETAL MOVEMENTS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "WATER BREAKS SIGN" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "SLEEPING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FEEDING PROBLEMS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "CRYING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "BOWEL MOVEMENTS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "SKIN RASHES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "SKIN INFECTIONS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "UMBILICUS INFECTION" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "GROWTH MILESTONES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "ACCESSING HEALTHCARE SERVICES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "HEALTHCARE VISITS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "NUTRITION" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "BODY CHANGES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "DISCOMFORT" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "CONCERNS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "EMOTIONS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "WARNING SIGNS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "ROUTINES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "BELIEFS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "BABY'S GROWTH" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "MILESTONES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "PREVENTION" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH INFORMATION")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FEVER" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "DIARRHEA" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "COUGH" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "CONVULSIONS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "NOT EATING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "VOMITING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "RED EYE" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FAST BREATHING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "VERY SLEEPY" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "UNCONSCIOUS" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "VAGINAL BLEEDING DURING PREGNANCY" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "POSTNATAL BLEEDING" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FEVER DURING PREGNANCY SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "POSTNATAL FEVER SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "HEADACHES" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "FITS OR CONVULSIONS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "SWOLLEN HANDS OR FEET SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "PALENESS OF THE SKIN AND TIREDNESS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")),
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "NO FETAL MOVEMENTS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM")), 
  ((SELECT concept_name_id  FROM openmrs_mnch.concept_name WHERE name = "WATER BREAKS SYMPTOM" LIMIT 1),(SELECT concept_name_tag_id FROM openmrs_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM"));
  
#UNLOCK TABLES;

INSERT INTO openmrs_mnch.relationship_type (a_is_to_b, b_is_to_a, description, creator, date_created, uuid) VALUES
  ('Child','Parent','Where the guardian is a parent to the patient',1,(NOW()),(SELECT UUID())),
	('Grand child','Grand parent','Where the guardian is a grand parent to the patient',1,(NOW()),(SELECT UUID())),
	('Niece/Nephew','Aunt/Uncle','Where the guardian is an aunt or uncle to the patient',1,(NOW()),(SELECT UUID())),
	('Patient','Other relatives','Where the guardian is a relative (Other, not specified on the list)',1,(NOW()),(SELECT UUID()));

#This has to be removed;

#DELETE FROM encounter_type where encounter_type_id in (108,109,110);
	
UPDATE openmrs_mnch.encounter SET encounter_type = (SELECT encounter_type_id FROM openmrs_mnch.encounter_type WHERE name = (SELECT name from openmrs_mnch1.encounter_type where encounter_type_id = encounter_type));

#update the obs table;

UPDATE openmrs_mnch.obs o
SET o.concept_id = (SELECT DISTINCT cn2.concept_id FROM openmrs_mnch.concept_name cn2 WHERE cn2.name = (SELECT cn1.name FROM openmrs_mnch1.concept_name cn1 WHERE cn1.concept_id = o.concept_id AND cn1.voided = 0 LIMIT 1) AND cn2.voided = 0 LIMIT 1),
o.value_coded = CASE o.value_coded
		WHEN NULL THEN NULL
		ELSE
			(SELECT DISTINCT cn22.concept_id FROM openmrs_mnch.concept_name cn22 WHERE cn22.name = (SELECT cn11.name FROM openmrs_mnch1.concept_name cn11 WHERE
			cn11.concept_id = o.value_coded AND cn11.voided = 0 LIMIT 1) AND cn22.voided = 0 LIMIT 1)
		END,
o.value_coded_name_id = CASE o.value_coded_name_id
		WHEN NULL THEN NULL
		ELSE
			(SELECT DISTINCT cn222.concept_name_id FROM openmrs_mnch.concept_name cn222 WHERE cn222.name = (SELECT cn111.name FROM openmrs_mnch1.concept_name cn111 WHERE
		 	cn111.concept_id = o.value_coded AND cn111.voided = 0 LIMIT 1) AND cn222.voided = 0 LIMIT 1)
		END
WHERE o.concept_id > 7000;

INSERT INTO openmrs_mnch.person_attribute_type (name, description, creator, uuid) VALUES 
('NEAREST HEALTH FACILITY', "The person's nearest health facility", 1, (SELECT UUID()));

UPDATE openmrs_mnch.person_attribute
SET person_attribute_type_id = (SELECT person_attribute_type_id FROM openmrs_mnch.person_attribute_type WHERE name = 'NEAREST HEALTH FACILITY')
WHERE person_attribute_type_id = 20;

INSERT INTO openmrs_mnch.patient_identifier_type (name, description, creator,uuid) VALUES 
('IVR Access Code', "Unique identifier for a particular patient. To be used for search purposes",1, (SELECT UUID()));

UPDATE openmrs_mnch.patient_identifier
SET identifier_type = (SELECT patient_identifier_type_id FROM openmrs_mnch.patient_identifier_type WHERE name = 'IVR Access Code')
WHERE identifier_type = 17;
