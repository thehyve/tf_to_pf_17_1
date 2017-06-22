-- design explaination ?

-- Fill dimension dictionary
insert into i2b2metadata.dimension_description(name) 
select 'study'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'study');

insert into i2b2metadata.dimension_description(name)
select 'concept'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'concept');

insert into i2b2metadata.dimension_description(name)
select 'patient'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'patient');

insert into i2b2metadata.dimension_description(name)
select 'visit'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'visit');

insert into i2b2metadata.dimension_description(name)
select 'start time'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'start time');

insert into i2b2metadata.dimension_description(name)
select 'end time'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'end time');

insert into i2b2metadata.dimension_description(name)
select 'location'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'location');

insert into i2b2metadata.dimension_description(name)
select 'trial visit'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'trial visit');

insert into i2b2metadata.dimension_description(name)
select 'provider'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'provider');

insert into i2b2metadata.dimension_description(name)
select 'biomarker'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'biomarker');

insert into i2b2metadata.dimension_description(name)
select 'assay'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'assay');

insert into i2b2metadata.dimension_description(name)
select 'projection'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'projection');

insert into i2b2metadata.dimension_description(density, modifier_code, value_type, name, packable, size_cd)
select 'DENSE', 'TRANSMART:SMPL', 'T', 'sample_type', 'NOT_PACKABLE', 'SMALL'
from dual
where not exists(select * from i2b2metadata.dimension_description where name = 'sample_type');

-- Insert bio experiments for missing studies
insert into biomart.bio_experiment(
  title,
  accession
)
select 
  'Metadata not available' as title,
  tn.trial as accession
from i2b2metadata.i2b2_trial_nodes tn
  where not exists(select * from biomart.bio_experiment be where be.accession = tn.trial);
-- subquery return 0 rows  

-- Insert missing studies
insert into i2b2demodata.study(
  bio_experiment_id,
  study_id,
  secure_obj_token
)
select 
  be.bio_experiment_id,
  tn.trial,
  CASE sc.secure_obj_token
    WHEN NULL THEN 'PUBLIC'
    WHEN 'EXP:PUBLIC' THEN 'PUBLIC'
    ELSE sc.secure_obj_token
  END as secure_obj_token
from i2b2metadata.i2b2_trial_nodes tn
  inner join biomart.bio_experiment be on be.accession = tn.trial
  left join i2b2metadata.i2b2_secure sc on sc.c_fullname = tn.c_fullname
  where not exists(select * from i2b2demodata.study s2 where s2.study_id = tn.trial);

-- Map all studies to the always present dimensions.
insert into i2b2metadata.study_dimension_descriptions(
  dimension_description_id,
  study_id
)
select 
  dd.id as dimension_description_id,
  s.study_num as study_id
from i2b2demodata.study s
inner join i2b2metadata.dimension_description dd on dd.name in ('study', 'concept', 'patient', 'trial visit')
where not exists(select * from i2b2metadata.study_dimension_descriptions sdd where sdd.dimension_description_id = dd.id and sdd.study_id = s.study_num);

-- Map studies that have HD data to HD specific dimensions
insert into i2b2metadata.study_dimension_descriptions(
  dimension_description_id,
  study_id
)
select 
  dd.id as dimension_description_id,
  s.study_num as study_id
from i2b2demodata.study s
inner join i2b2metadata.dimension_description dd on dd.name in ('biomarker', 'assay', 'projection')
where exists(select * from deapp.de_subject_sample_mapping ssm where ssm.trial_name = s.study_id) 
  and not exists(select * from i2b2metadata.study_dimension_descriptions sdd where sdd.dimension_description_id = dd.id and sdd.study_id = s.study_num);

-- Add default visits for studies that don't have one
insert into i2b2demodata.trial_visit_dimension(
  study_num,
  rel_time_label
)
select
  s.study_num,
  'General' as rel_time_label
from i2b2demodata.study s
where not exists(select * from i2b2demodata.trial_visit_dimension tvd where tvd.study_num = s.study_num);

-- Add trial visits based on the HD timepoint
insert into i2b2demodata.trial_visit_dimension(
  study_num,
  rel_time_label
) select distinct
  s.study_num,
  ssm.timepoint as rel_time_label
from deapp.de_subject_sample_mapping ssm
inner join i2b2demodata.study s on s.study_id = ssm.trial_name
where ssm.timepoint is not null and ssm.timepoint <> '' and not exists(select * from i2b2demodata.trial_visit_dimension tvd where tvd.study_num = s.study_num and tvd.rel_time_label = ssm.timepoint);

-- Regenerate HD observations
--- 1. Remove existin HD observations.
delete from i2b2demodata.observation_fact obs where obs.concept_cd in (select concept_code from deapp.de_subject_sample_mapping ssm);
-- need confirmation from Haiyan

--- 2. Add the HD sample code observation
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
  -1 as ENCOUNTER_NUM,
  ssm.PATIENT_ID as PATIENT_NUM,
  ssm.concept_code as CONCEPT_CD,
  '@' as PROVIDER_ID,
  TO_DATE('01-01-01', 'yy-mm-dd') as START_DATE,
  '@' as MODIFIER_CD,
  row_number() over (partition by ssm.patient_id, ssm.concept_code order by ssm.assay_id) as INSTANCE_NUM,
  COALESCE(trial_visit.TRIAL_VISIT_NUM, general_trial_visit.TRIAL_VISIT_NUM) as TRIAL_VISIT_NUM,
  'T' as VALTYPE_CD,
  ssm.sample_cd as TVAL_CHAR,
  '@' as LOCATION_CD,
  ssm.trial_name  as SOURCESYSTEM_CD
from DEAPP.DE_SUBJECT_SAMPLE_MAPPING ssm
  join I2B2DEMODATA.STUDY study on ssm.TRIAL_NAME = study.STUDY_ID
  left join I2B2DEMODATA.TRIAL_VISIT_DIMENSION trial_visit on trial_visit.STUDY_NUM = study.STUDY_NUM and ssm.TIMEPOINT = trial_visit.REL_TIME_LABEL
  left join I2B2DEMODATA.TRIAL_VISIT_DIMENSION general_trial_visit on general_trial_visit.STUDY_NUM = study.STUDY_NUM and general_trial_visit.REL_TIME_LABEL = 'General';

--- 3. Add the HD assay id modifying observation
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
   NVAL_NUM,
   LOCATION_CD,
   SOURCESYSTEM_CD
  )
select 
  -1 as ENCOUNTER_NUM,
  ssm.PATIENT_ID as PATIENT_NUM,
  ssm.concept_code as CONCEPT_CD,
  '@' as PROVIDER_ID,
  TO_DATE('01-01-01', 'yy-mm-dd') as START_DATE,
  'TRANSMART:HIGHDIM:' || upper(gpl.MARKER_TYPE) as MODIFIER_CD,
  row_number() over (partition by ssm.patient_id, ssm.concept_code order by ssm.assay_id) as INSTANCE_NUM,
  COALESCE(trial_visit.TRIAL_VISIT_NUM, general_trial_visit.TRIAL_VISIT_NUM) as TRIAL_VISIT_NUM,
  'N' as VALTYPE_CD,
  'E' as TVAL_CHAR,
  ssm.ASSAY_ID as NVAL_NUM,
  '@' as LOCATION_CD,
  ssm.trial_name  as SOURCESYSTEM_CD  
from DEAPP.DE_SUBJECT_SAMPLE_MAPPING ssm
  join I2B2DEMODATA.STUDY study on ssm.TRIAL_NAME = study.STUDY_ID
  left join I2B2DEMODATA.TRIAL_VISIT_DIMENSION trial_visit on trial_visit.STUDY_NUM = study.STUDY_NUM and ssm.TIMEPOINT = trial_visit.REL_TIME_LABEL
  left join I2B2DEMODATA.TRIAL_VISIT_DIMENSION general_trial_visit on general_trial_visit.STUDY_NUM = study.STUDY_NUM and general_trial_visit.REL_TIME_LABEL = 'General'
  join DEAPP.DE_GPL_INFO gpl on ssm.GPL_ID = gpl.PLATFORM;

-- Assign the rest of the observations to the default trial visit.
update i2b2demodata.observation_fact set trial_visit_num = 
      (select 
          tv.trial_visit_num
        from i2b2demodata.trial_visit_dimension tv
        inner join i2b2demodata.study s on s.study_num = tv.study_num 
        where tv.rel_time_label = 'General'
          and (s.study_id = observation_fact.sourcesystem_cd or observation_fact.sourcesystem_cd like s.study_id || ':%')
      )
where trial_visit_num is null;

-- What to do with the SECURITY records that have null in the trial visit?
-- ALTER TABLE "I2B2DEMODATA"."OBSERVATION_FACT" MODIFY "TRIAL_VISIT_NUM" NOT NULL;

-- Fix referencial consistency for the visit dimension.
update i2b2demodata.observation_fact set encounter_num = -1
where encounter_num <> -1 and not exists(select * from i2b2demodata.visit_dimension v where v.encounter_num = observation_fact.encounter_num);

-- added for performance
ALTER TABLE i2b2demodata.observation_fact ADD CONSTRAINT observation_fact_pkey PRIMARY KEY (encounter_num, patient_num, concept_cd, provider_id, instance_num, modifier_cd, start_date);
ALTER TABLE i2b2demodata.observation_fact ADD CONSTRAINT trial_visit_dim_fk FOREIGN KEY (trial_visit_num) REFERENCES i2b2demodata.trial_visit_dimension(trial_visit_num);
CREATE INDEX idx_fact_trial_visit_num ON i2b2demodata.observation_fact(trial_visit_num);
CREATE INDEX I2B2DEMODATA.IDX_OB_FACT_2 ON I2B2DEMODATA.OBSERVATION_FACT(CONCEPT_CD, PATIENT_NUM, ENCOUNTER_NUM);

