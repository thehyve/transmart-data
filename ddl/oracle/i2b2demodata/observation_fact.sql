--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: OBSERVATION_FACT
--
 CREATE TABLE "I2B2DEMODATA"."OBSERVATION_FACT" 
  (	"ENCOUNTER_NUM" NUMBER(38,0), 
"PATIENT_NUM" NUMBER(38,0), 
"CONCEPT_CD" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"PROVIDER_ID" VARCHAR2(50 BYTE), 
"START_DATE" DATE, 
"MODIFIER_CD" VARCHAR2(100 BYTE), 
"VALTYPE_CD" VARCHAR2(50 BYTE), 
"TVAL_CHAR" VARCHAR2(255 BYTE), 
"NVAL_NUM" NUMBER(18,5), 
"VALUEFLAG_CD" VARCHAR2(50 BYTE), 
"QUANTITY_NUM" NUMBER(18,5), 
"UNITS_CD" VARCHAR2(50 BYTE), 
"END_DATE" DATE, 
"LOCATION_CD" VARCHAR2(50 BYTE), 
"CONFIDENCE_NUM" NUMBER(18,0), 
"UPDATE_DATE" DATE, 
"DOWNLOAD_DATE" DATE, 
"IMPORT_DATE" DATE, 
"SOURCESYSTEM_CD" VARCHAR2(50 BYTE), 
"UPLOAD_ID" NUMBER(38,0), 
"OBSERVATION_BLOB" CLOB, 
"INSTANCE_NUM" NUMBER(18,0), 
"SAMPLE_CD" VARCHAR2(200 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2_DATA" 
LOB ("OBSERVATION_BLOB") STORE AS BASICFILE (
 TABLESPACE "I2B2_DATA" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
 NOCACHE NOLOGGING ) ;
--
-- Type: INDEX; Owner: I2B2DEMODATA; Name: IDX_OB_FACT_2
--
CREATE INDEX "I2B2DEMODATA"."IDX_OB_FACT_2" ON "I2B2DEMODATA"."OBSERVATION_FACT" ("CONCEPT_CD", "PATIENT_NUM", "ENCOUNTER_NUM")
TABLESPACE "I2B2_DATA" ;
--
-- Type: INDEX; Owner: I2B2DEMODATA; Name: IDX_OB_FACT_1
--
CREATE INDEX "I2B2DEMODATA"."IDX_OB_FACT_1" ON "I2B2DEMODATA"."OBSERVATION_FACT" ("CONCEPT_CD")
TABLESPACE "I2B2_DATA" ;
--
-- Type: SEQUENCE; Owner: I2B2DEMODATA; Name: SEQ_ENCOUNTER_NUM
--
CREATE SEQUENCE  "I2B2DEMODATA"."SEQ_ENCOUNTER_NUM"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 49814595 CACHE 20 NOORDER  NOCYCLE ;
--
-- Type: TRIGGER; Owner: I2B2DEMODATA; Name: TRG_ENCOUNTER_NUM
--
  CREATE OR REPLACE TRIGGER "I2B2DEMODATA"."TRG_ENCOUNTER_NUM" 
	before insert on "OBSERVATION_FACT"    
	for each row begin     
	  if inserting then       
		if :NEW."ENCOUNTER_NUM" is null then          
		  select SEQ_ENCOUNTER_NUM.nextval into :NEW."ENCOUNTER_NUM" from dual;       
		end if;    
	  end if; 
	end;
/
ALTER TRIGGER "I2B2DEMODATA"."TRG_ENCOUNTER_NUM" ENABLE;