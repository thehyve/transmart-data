--
-- Type: TABLE; Owner: DEAPP; Name: DE_SNP_COPY_NUMBER
--
 CREATE TABLE "DEAPP"."DE_SNP_COPY_NUMBER" 
  (	"TRIAL_NAME" VARCHAR2(20 BYTE), 
"PATIENT_NUM" NUMBER(20,0), 
"SNP_NAME" VARCHAR2(50 BYTE), 
"CHROM" VARCHAR2(2 BYTE), 
"CHROM_POS" NUMBER(20,0), 
"COPY_NUMBER" NUMBER(2,0)
  )
 TABLESPACE "DEAPP" 
 PARTITION BY LIST ("PATIENT_NUM") 
(PARTITION "NULL_PARTITION" VALUES(NULL) TABLESPACE "DEAPP") ;

--
-- Type: INDEX; Owner: DEAPP; Name: IDX_SNP_COPY_NUMBER_PS
--
 CREATE BITMAP INDEX "DEAPP"."IDX_SNP_COPY_NUMBER_PS" ON "DEAPP"."DE_SNP_COPY_NUMBER" ("PATIENT_NUM", "SNP_NAME") 
 LOCAL
 TABLESPACE "INDX" ;
