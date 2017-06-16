-- Samples and time series migration 
-- See https://wiki.transmartfoundation.org/display/transmartwiki/Samples+and+Time+series+data
insert into i2b2demodata.modifier_dimension(
	modifier_path,
	modifier_cd,
	name_char
) select '\\Samples\\Sample Codes\\', 'TRANSMART:SMPL', 'Sample Codes'
from dual
where not exists(select * from i2b2demodata.modifier_dimension where modifier_cd = 'TRANSMART:SMPL');

 --delete from i2b2demodata.observation_fact where modifier_cd = 'TRANSMART:SMPL';

insert into I2B2DEMODATA.OBSERVATION_FACT(
   ENCOUNTER_NUM,
   PATIENT_NUM,
   CONCEPT_CD,
   PROVIDER_ID,
   START_DATE,
   MODIFIER_CD,
   INSTANCE_NUM,
   TRIAL_VISIT_NUM,
   VALTYPE_CD,
   TVAL_CHAR,
   LOCATION_CD,
   SOURCESYSTEM_CD
)
select
  o.encounter_num as ENCOUNTER_NUM,
  o.patient_num as PATIENT_NUM,
  o.concept_cd as CONCEPT_CD,
  o.provider_id as PROVIDER_ID,
  o.start_date as START_DATE,
  'TRANSMART:SMPL' as MODIFIER_CD,
  o.instance_num INSTANCE_NUM,
  o.trial_visit_num as TRIAL_VISIT_NUM,
  'T' as VALTYPE_CD,
  o.sample_cd as TVAL_CHAR,
  o.location_cd as LOCATION_CD,
  o.sourcesystem_cd as SOURCESYSTEM_CD
from i2b2demodata.observation_fact o
where sample_cd is not null
  and not exists(select * from i2b2demodata.observation_fact o2 where o2.patient_num = o.patient_num and o2.concept_cd = o.concept_cd and o2.modifier_cd = 'TRANSMART:SMPL');

-- Time series
CREATE GLOBAL TEMPORARY TABLE concept_specific_trials
ON COMMIT PRESERVE ROWS 
AS SELECT
  distinct
  s.study_num as STUDY_NUM,
  extractValue(XMLType(i.c_metadataxml), '//SeriesMeta/DisplayName/text()') as REL_TIME_LABEL,
  extractValue(XMLType(i.c_metadataxml), '//SeriesMeta/Value/text()') as REL_TIME_NUM,
  extractValue(XMLType(i.c_metadataxml), '//SeriesMeta/Unit/text()') as REL_TIME_UNIT_CD,
  c.concept_cd as CONCEPT_CD
FROM I2B2METADATA.I2B2 i
INNER JOIN I2B2DEMODATA.STUDY s ON s.study_id = i.sourcesystem_cd
INNER JOIN I2B2DEMODATA.CONCEPT_DIMENSION c on c.CONCEPT_PATH = i.C_FULLNAME
WHERE i.C_METADATAXML IS NOT NULL
  and i.C_METADATAXML LIKE '%SeriesMeta%';

INSERT INTO I2B2DEMODATA.TRIAL_VISIT_DIMENSION(
  STUDY_NUM,
  REL_TIME_UNIT_CD,
  REL_TIME_NUM,
  REL_TIME_LABEL
) SELECT 
  cst.STUDY_NUM,
  cst.REL_TIME_UNIT_CD,
  cst.REL_TIME_NUM,
  cst.REL_TIME_LABEL
FROM concept_specific_trials cst
WHERE not exists(select * from i2b2demodata.trial_visit_dimension tv where tv.STUDY_NUM = cst.STUDY_NUM and tv.REL_TIME_UNIT_CD = cst.REL_TIME_UNIT_CD and tv.REL_TIME_NUM = cst.REL_TIME_NUM and tv.REL_TIME_LABEL = cst.REL_TIME_LABEL);

UPDATE I2B2DEMODATA.OBSERVATION_FACT SET TRIAL_VISIT_NUM = (
  select TRIAL_VISIT_NUM from I2B2DEMODATA.TRIAL_VISIT_DIMENSION tv
  inner join concept_specific_trials cst on cst.study_num = tv.study_num
  and cst.REL_TIME_NUM = tv.REL_TIME_NUM
  and cst.REL_TIME_LABEL = tv.REL_TIME_LABEL
  and cst.REL_TIME_UNIT_CD = tv.REL_TIME_UNIT_CD)
WHERE concept_cd in (select concept_cd from concept_specific_trials);
-- check on all data updates

DROP TABLE concept_specific_trials;