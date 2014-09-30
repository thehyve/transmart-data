--
-- Type: TABLE; Owner: TM_WZ; Name: TMP_SUBJECT_RBM_MED
--
 CREATE TABLE "TM_WZ"."TMP_SUBJECT_RBM_MED" 
  (	"TRIAL_NAME" VARCHAR2(100 BYTE), 
"ANTIGEN_NAME" VARCHAR2(100 BYTE), 
"N_VALUE" NUMBER, 
"PATIENT_ID" NUMBER(38,0), 
"GENE_SYMBOL" VARCHAR2(100 BYTE), 
"GENE_ID" NUMBER(10,0), 
"ASSAY_ID" NUMBER, 
"NORMALIZED_VALUE" NUMBER(18,5), 
"CONCEPT_CD" NVARCHAR2(100), 
"TIMEPOINT" VARCHAR2(100 BYTE), 
"LOG_INTENSITY" NUMBER, 
"VALUE" NUMBER(18,4), 
"MEAN_INTENSITY" NUMBER, 
"STDDEV_INTENSITY" NUMBER, 
"MEDIAN_INTENSITY" NUMBER, 
"ZSCORE" NUMBER
  ) SEGMENT CREATION DEFERRED
NOCOMPRESS LOGGING
 TABLESPACE "TRANSMART" ;
