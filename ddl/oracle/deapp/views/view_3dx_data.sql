--
-- Type: VIEW; Owner: DEAPP; Name: VIEW_3DX_DATA
--
  CREATE OR REPLACE FORCE VIEW "DEAPP"."VIEW_3DX_DATA" ("TRIAL_NAME", "PROBESET_ID", "ASSAY_ID", "PATIENT_ID", "RAW_INTENSITY", "LOG_INTENSITY", "ZSCORE", "PROBE_ID", "GENE_SYMBOL", "GENE_ID", "ORGANISM") AS 
  select smd.trial_name, smd.probeset_id, smd.assay_id, smd.patient_id, 
smd.raw_intensity, smd.log_intensity, smd.zscore, ma.probe_id, ma.gene_symbol, 
ma.gene_id, ma.organism
from DEAPP.de_subject_microarray_data smd, DEAPP.de_mrna_annotation ma
where trial_name like 'LWG_P101194_NZBW'
and ma.probeset_id = ma.probeset_id
 ;
