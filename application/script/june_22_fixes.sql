USE openmrs_mnch_migrated;

-- insert some missing concepts in the concept name tag map

INSERT INTO migrated_mnch.concept_name_tag_map(concept_name_id, concept_name_tag_id) VALUES
    ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "FLAKY SKIN" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "DANGER SIGN")),
    ((SELECT concept_name_id  FROM migrated_mnch.concept_name WHERE name = "WEIGHT CHANGE" LIMIT 1),(SELECT concept_name_tag_id FROM migrated_mnch.concept_name_tag WHERE tag = "HEALTH SYMPTOM"));

-- add creator in the call log table

ALTER TABLE call_log 
    ADD creator INT(11) NOT NULL DEFAULT 0;

-- update the call_log table with the right values for the creator

DROP TABLE IF EXISTS call_log_update;

CREATE TABLE call_log_update (
    call_id int(11),
    creator_id int(11)
);

INSERT INTO call_log_update
(SELECT distinct cl.call_log_id, o.creator
    FROM call_log cl LEFT JOIN obs o ON cl.call_log_id = o.value_text -- and o.concept_id = 8304;
    WHERE o.concept_id  = 8304);

UPDATE call_log
SET creator = (SELECT creator_id FROM call_log_update WHERE call_id = call_log_id)
WHERE call_log_id IN (SELECT call_id from call_log_update);

UPDATE call_log
SET creator = 1
WHERE creator = 0;



                