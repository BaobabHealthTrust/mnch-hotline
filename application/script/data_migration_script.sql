/*
  Please remember to replace 
    mnch_old with the name of the old hotline_database ,
    migrated_mnch with the name of the new hotline datasase [the one on which the metadata was run]
*/

INSERT INTO migrated_mnch.relationship_type (a_is_to_b, b_is_to_a, description, creator, date_created, uuid) VALUES
  ('Child','Parent','Where the guardian is a parent to the patient',1,(NOW()),(SELECT UUID())),
	('Grand child','Grand parent','Where the guardian is a grand parent to the patient',1,(NOW()),(SELECT UUID())),
	('Niece/Nephew','Aunt/Uncle','Where the guardian is an aunt or uncle to the patient',1,(NOW()),(SELECT UUID())),
	('Patient','Other relatives','Where the guardian is a relative (Other, not specified on the list)',1,(NOW()),(SELECT UUID()));

UPDATE migrated_mnch.encounter SET encounter_type = (SELECT encounter_type_id FROM migrated_mnch.encounter_type WHERE name = (SELECT name from mnch_old.encounter_type where encounter_type_id = encounter_type));

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


UPDATE migrated_mnch.person_attribute
SET person_attribute_type_id = (SELECT person_attribute_type_id FROM migrated_mnch.person_attribute_type WHERE name = 'NEAREST HEALTH FACILITY')
WHERE person_attribute_type_id = 20;

UPDATE migrated_mnch.patient_identifier
SET identifier_type = (SELECT patient_identifier_type_id FROM migrated_mnch.patient_identifier_type WHERE name = 'IVR Access Code')
WHERE identifier_type = 17;

-- fixes for june 22 - testing

-- add creator in the call log table

ALTER TABLE migrated_mnch.call_log 
    ADD creator INT(11) NOT NULL DEFAULT 0;

-- update the call_log table with the right values for the creator

DROP TABLE IF EXISTS migrated_mnch.call_log_update;

CREATE TABLE migrated_mnch.call_log_update (
    call_id int(11),
    creator_id int(11)
);

INSERT INTO migrated_mnch.call_log_update
(SELECT distinct cl.call_log_id, o.creator
    FROM migrated_mnch.call_log cl LEFT JOIN migrated_mnch.obs o ON cl.call_log_id = o.value_text -- and o.concept_id = 8304;
    WHERE o.concept_id  = 8304);

UPDATE migrated_mnch.call_log
SET creator = (SELECT creator_id FROM migrated_mnch.call_log_update WHERE call_id = call_log_id)
WHERE call_log_id IN (SELECT call_id from migrated_mnch.call_log_update);

UPDATE migrated_mnch.call_log
SET creator = 1
WHERE creator = 0;
