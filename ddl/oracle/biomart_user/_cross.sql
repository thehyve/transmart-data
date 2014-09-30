--
-- Type: VIEW; Owner: BIOMART_USER; Name: BROWSE_ANALYSES_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART_USER"."BROWSE_ANALYSES_VIEW" ("ID", "TITLE", "DESCRIPTION", "MEASUREMENT_TYPE", "PLATFORM_NAME", "VENDOR", "TECHNOLOGY") AS 
  select
fd.unique_id
, baa.analysis_name as title
, baa.long_description as description
, listagg(to_char(bap.platform_type), '|') within group (order by bap.platform_type) as measurement_type
, listagg(to_char(bap.platform_name), '|') within group (order by bap.platform_name ) as platform_name
, listagg(to_char(bap.platform_vendor), '|') within group (order by bap.platform_vendor) as vendor
, listagg(to_char(bap.platform_technology), '|') within group (order by bap.platform_technology) as technology
from biomart.bio_assay_analysis baa
inner join biomart.bio_data_uid bd on baa.bio_assay_analysis_id = bd.bio_data_id
inner join fmapp.fm_folder_association fa on fa.object_uid = bd.unique_id
inner join fmapp.fm_data_uid fd on fa.folder_id = fd.fm_data_id
inner join fmapp.fm_folder ff on ff.folder_id = fa.folder_id
left outer join amapp.am_tag_association ata on fd.unique_id = ata.subject_uid
left outer join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
left outer join biomart.bio_assay_platform bap on bap.bio_assay_platform_id = bdu.bio_data_id
where
    ata.object_type in ('BIO_ASSAY_PLATFORM')
    and ff.active_ind = 1
group by  fd.unique_id, baa.analysis_name, baa.long_description;
--
-- Type: INDEX; Owner: BIOMART_USER; Name: OBSERVATION_FACT_PD
--
CREATE INDEX "BIOMART_USER"."OBSERVATION_FACT_PD" ON "I2B2DEMODATA"."OBSERVATION_FACT" ("PATIENT_NUM")
TABLESPACE "TRANSMART" ;
--
-- Type: VIEW; Owner: BIOMART_USER; Name: BROWSE_STUDIES_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART_USER"."BROWSE_STUDIES_VIEW" ("ID", "TITLE", "DESCRIPTION", "DESIGN", "BIOMARKER_TYPE", "ACCESS_TYPE", "ACCESSION", "INSTITUTION", "COUNTRY", "DISEASE", "COMPOUND", "STUDY_OBJECTIVE", "ORGANISM", "STUDY_PHASE") AS 
  SELECT
  fd.unique_id
, exp.title
, exp.description
, exp.design
, exp.biomarker_type
, exp.access_type
, exp.accession
, exp.institution
, exp.country
, x.disease
, x.compound
, x.study_objective
, x.species as organism
, x.phase as study_phase
from biomart.bio_experiment exp
inner join biomart.bio_data_uid bd on exp.bio_experiment_id = bd.bio_data_id
inner join fmapp.fm_folder_association fa on fa.object_uid = bd.unique_id
inner join fmapp.fm_data_uid fd on fa.folder_id = fd.fm_data_id
inner join fmapp.fm_folder ff on ff.folder_id = fa.folder_id
left outer join (select id, disease, compound, study_objective, species, phase from
  (
  select
    fdu.unique_id as id, ata.object_type as object_type, ata.object_uid as object_uid
  from
    fmapp.fm_folder_association ffa
    inner join fmapp.fm_data_uid fdu on ffa.folder_id = fdu.fm_data_id
    inner join amapp.am_tag_association ata on fdu.unique_id= ata.subject_uid

  where
    ata.object_type in ('BIO_DISEASE', 'BIO_COMPOUND')

  union
  select
    fdu.unique_id as id, ati.code_type_name as object_type, ata.object_uid as object_uid
  from
    fmapp.fm_folder_association ffa
    inner join fmapp.fm_data_uid fdu on ffa.folder_id = fdu.fm_data_id
    inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
    inner join amapp.am_tag_item ati on ata.tag_item_id = ati.tag_item_id
  where
    ata.object_type = 'BIO_CONCEPT_CODE'
) pivot (
  listagg(TO_CHAR(object_uid), '|') within group (order by object_uid)
  for object_type in ('BIO_DISEASE' as disease, 'BIO_COMPOUND' as compound, 'STUDY_OBJECTIVE' as study_objective, 'SPECIES' as species, 'STUDY_PHASE' as phase)
)
)x on  x.id = fd.unique_id
where ff.active_ind = 1;
--
-- Type: VIEW; Owner: BIOMART_USER; Name: BROWSE_PROGRAMS_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART_USER"."BROWSE_PROGRAMS_VIEW" ("ID", "TITLE", "DESCRIPTION", "DISEASE", "OBSERVATION", "PATHWAY", "GENE", "THERAPEUTIC_DOMAIN", "INSTITUTION", "TARGET") AS 
  select fd.unique_id
, f.folder_name as title
, f.description
, x.disease
, x.observation
, x.pathway
, x.gene
, x.therapeutic_domain
, x.institution
, x.target
from fmapp.fm_folder f
inner join fmapp.fm_data_uid fd on f.folder_id = fd.fm_data_id
left outer join
  (select id, disease, observation, pathway, gene, therapeutic_domain, institution, target  from
    (
    select
      fdu.unique_id as id, 'BIO_DISEASE' as object_type, ata.object_uid as object_uid
      from
        fmapp.fm_folder ff
        inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
        inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
        inner join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
        inner join biomart.bio_disease bd on bd.bio_disease_id = bdu.bio_data_id

      where
        ata.object_type in ('BIO_DISEASE', 'PROGRAM_TARGET')
        and ff.folder_type = 'PROGRAM'

    union

    select
      fdu.unique_id as id, 'BIO_OBSERVATION' as object_type, ata.object_uid as object_uid
      from
        fmapp.fm_folder ff
        inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
        inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
        inner join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
        inner join biomart.bio_observation bo on bo.bio_observation_id = bdu.bio_data_id

      where
        ata.object_type in ('BIO_OBSERVATION', 'PROGRAM_TARGET')
        and ff.folder_type = 'PROGRAM'

    union

        select
      fdu.unique_id as id, 'PATHWAY' as object_type, ata.object_uid as object_uid
      from
        fmapp.fm_folder ff
        inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
        inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
      inner join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
      inner join biomart.bio_marker bm on bm.bio_marker_id = bdu.bio_data_id

      where
        bm.bio_marker_type = 'PATHWAY'
        and (ata.object_type = 'BIO_MARKER' or ata.object_type = 'PROGRAM_TARGET')
        and ff.folder_type = 'PROGRAM'

    union

        select
      fdu.unique_id as id, 'GENE' as object_type, ata.object_uid as object_uid
      from
        fmapp.fm_folder ff
        inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
        inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
        inner join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
        inner join biomart.bio_marker bm on bm.bio_marker_id = bdu.bio_data_id

      where
        bm.bio_marker_type = 'GENE'
        and (ata.object_type = 'BIO_MARKER' or ata.object_type = 'PROGRAM_TARGET')
        and ff.folder_type = 'PROGRAM'

    union

    select
      fdu.unique_id as id, to_char(ati.code_type_name) as object_type, ata.object_uid as object_uid
    from
      fmapp.fm_folder ff
      inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
      inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
      inner join amapp.am_tag_item ati on ata.tag_item_id = ati.tag_item_id
      inner join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
      inner join biomart.bio_concept_code bcc on bcc.bio_concept_code_id = bdu.bio_data_id
    where
      ata.object_type in ('BIO_CONCEPT_CODE', 'PROGRAM_TARGET')
      and ff.folder_type = 'PROGRAM'

  ) pivot (
    listagg(to_char(object_uid), '|') within group (order by object_uid)
    for object_type in ('BIO_DISEASE' as disease, 'BIO_OBSERVATION' as observation, 'PATHWAY' as pathway, 'GENE' as gene, 'THERAPEUTIC_DOMAIN' as therapeutic_domain, 'PROGRAM_INSTITUTION' as institution, 'PROGRAM_TARGET_PATHWAY_PHENOTYPE' as target)
  )
  ) x on x.id = fd.unique_id
where f.folder_type = 'PROGRAM' and f.active_ind = 1;
--
-- Type: VIEW; Owner: BIOMART_USER; Name: BROWSE_FOLDERS_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART_USER"."BROWSE_FOLDERS_VIEW" ("ID", "TITLE", "DESCRIPTION", "FILE_TYPE") AS 
  select fd.unique_id
, f.folder_name as title
, f.description
, listagg(to_char(ata.object_uid), '|') within group (order by ata.object_uid) as file_type
from fmapp.fm_folder f
inner join fmapp.fm_data_uid fd on f.folder_id = fd.fm_data_id
left outer join amapp.am_tag_association ata on fd.unique_id = ata.subject_uid
where f.folder_type = 'FOLDER' and f.active_ind = 1
and ata.object_type='BIO_CONCEPT_CODE'
and ata.object_uid like 'FILE_TYPE%'
group by fd.unique_id, f.folder_name, f.description;
--
-- Type: VIEW; Owner: BIOMART_USER; Name: BROWSE_ASSAYS_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART_USER"."BROWSE_ASSAYS_VIEW" ("ID", "TITLE", "DESCRIPTION", "MEASUREMENT_TYPE", "PLATFORM_NAME", "VENDOR", "TECHNOLOGY", "GENE", "MIRNA", "BIOMARKER_TYPE") AS 
  select DISTINCT fd.unique_id
  , f.folder_name as title
  , f.description
  , listagg(to_char(bap.platform_type), '|') within group (order by bap.platform_type) as measurement_type
  , listagg(to_char(bap.platform_name), '|') within group (order by bap.platform_name ) as platform_name
  , listagg(to_char(bap.platform_vendor), '|') within group (order by bap.platform_vendor) as vendor
  , listagg(to_char(bap.platform_technology), '|') within group (order by bap.platform_technology) as technology
  , x.gene
  , x.mirna
  , x.biomarker_type
  from fmapp.fm_folder f
  inner join fmapp.fm_data_uid fd on f.folder_id = fd.fm_data_id
  left outer join amapp.am_tag_association ata on fd.unique_id = ata.subject_uid and ata.object_type = 'BIO_ASSAY_PLATFORM'
  left outer join biomart.bio_data_uid bdu on bdu.unique_id = ata.object_uid
  left outer join biomart.bio_assay_platform bap on bap.bio_assay_platform_id = bdu.bio_data_id
  left outer join
    (select id, gene, mirna, biomarker_type from
      (
      select
        fdu.unique_id as id, 'BIO_MARKER_' || SUBSTR( ata.object_uid, 1, INSTR( ata.object_uid, ':' ) - 1 )  as object_type, ata.object_uid as object_uid

        from
          fmapp.fm_folder ff
          inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
          inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
        where
          ata.object_type in ('BIO_MARKER')
          and ff.folder_type = 'ASSAY'
      union
      select
        fdu.unique_id as id, ati.code_type_name as object_type, ata.object_uid as object_uid
      from
        fmapp.fm_folder ff
        inner join fmapp.fm_data_uid fdu on ff.folder_id = fdu.fm_data_id
        inner join amapp.am_tag_association ata on fdu.unique_id = ata.subject_uid
        inner join amapp.am_tag_item ati on ata.tag_item_id = ati.tag_item_id
      where
        ata.object_type = 'BIO_CONCEPT_CODE'
        and ff.folder_type = 'ASSAY'
    ) pivot (
      listagg(to_char(object_uid), '|') within group (order by object_uid)
      for object_type in ('BIO_MARKER_GENE' as gene,'BIO_MARKER_MIRNA' as mirna,'ASSAY_TYPE_OF_BM_STUDIED' as biomarker_type)

    )
    ) x on x.id = fd.unique_id
  where f.folder_type = 'ASSAY' and f.active_ind = 1
group by fd.unique_id, f.folder_name, f.description, x.gene, x.mirna, x.biomarker_type;
