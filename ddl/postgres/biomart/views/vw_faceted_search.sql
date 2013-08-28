--
-- Name: vw_faceted_search; Type: VIEW; Schema: biomart; Owner: -
--
CREATE VIEW vw_faceted_search AS
 SELECT ba.bio_assay_analysis_id AS analysis_id, 
    be.bio_experiment_id AS study, 
    be.bio_experiment_id AS study_id, 
    bd.disease, 
    ba.analysis_type AS analyses, 
    ba.bio_assay_data_type AS data_type, 
    bplat.platform_accession AS platform, 
    bpobs.obs_name AS observation, 
    row_number() OVER (ORDER BY ba.bio_assay_analysis_id) AS facet_id
   FROM (((((((bio_assay_analysis ba
   JOIN bio_experiment be ON (((ba.etl_id)::text = (be.accession)::text)))
   LEFT JOIN bio_data_disease bdd ON ((ba.bio_assay_analysis_id = bdd.bio_data_id)))
   LEFT JOIN bio_disease bd ON ((bdd.bio_disease_id = bd.bio_disease_id)))
   LEFT JOIN bio_data_platform bdplat ON ((ba.bio_assay_analysis_id = bdplat.bio_data_id)))
   LEFT JOIN bio_assay_platform bplat ON ((bdplat.bio_assay_platform_id = bplat.bio_assay_platform_id)))
   LEFT JOIN bio_data_observation bdpobs ON ((ba.bio_assay_analysis_id = bdpobs.bio_data_id)))
   LEFT JOIN bio_observation bpobs ON ((bdpobs.bio_observation_id = bpobs.bio_observation_id)))
  WHERE ((ba.bio_assay_data_type)::text = ANY ((ARRAY['GWAS'::character varying, 'Metabolic GWAS'::character varying, 'EQTL'::character varying])::text[]));

