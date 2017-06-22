ALTER TABLE i2b2demodata.observation_fact DROP CONSTRAINT observation_fact_pkey;
DROP INDEX ob_fact_pk;
DROP INDEX observation_fact_pkey;
DROP INDEX IDX_OB_FACT_2;

UPDATE i2b2demodata.observation_fact SET start_date = TO_DATE('01-01-01', 'yy-mm-dd') WHERE start_date is null;
UPDATE i2b2demodata.observation_fact SET encounter_num = -1 WHERE encounter_num is null;
UPDATE i2b2demodata.observation_fact SET instance_num = 1 WHERE instance_num is null;

ALTER TABLE i2b2demodata.observation_fact ADD trial_visit_num numeric(38,0);
