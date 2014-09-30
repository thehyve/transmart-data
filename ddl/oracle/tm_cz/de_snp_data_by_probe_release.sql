--
-- Type: TABLE; Owner: TM_CZ; Name: DE_SNP_DATA_BY_PROBE_RELEASE
--
 CREATE TABLE "TM_CZ"."DE_SNP_DATA_BY_PROBE_RELEASE" 
  (	"SNP_DATA_BY_PROBE_ID" NUMBER(22,0), 
"PROBE_ID" NUMBER(22,0), 
"PROBE_NAME" VARCHAR2(255 BYTE), 
"SNP_ID" NUMBER(22,0), 
"SNP_NAME" VARCHAR2(255 BYTE), 
"TRIAL_NAME" VARCHAR2(255 BYTE), 
"DATA_BY_PROBE" CLOB, 
"RELEASE_STUDY" VARCHAR2(200 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" 
LOB ("DATA_BY_PROBE") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
 NOCACHE NOLOGGING ) ;

