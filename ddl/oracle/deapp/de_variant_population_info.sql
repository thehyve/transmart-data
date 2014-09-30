--
-- Type: SEQUENCE; Owner: DEAPP; Name: DE_VARIANT_POPULATION_INFO_SEQ
--
CREATE SEQUENCE  "DEAPP"."DE_VARIANT_POPULATION_INFO_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE ;

--
-- Type: TABLE; Owner: DEAPP; Name: DE_VARIANT_POPULATION_INFO
--
 CREATE TABLE "DEAPP"."DE_VARIANT_POPULATION_INFO" 
  (	"VARIANT_POPULATION_INFO_ID" NUMBER NOT NULL ENABLE, 
"DATASET_ID" VARCHAR2(50 BYTE), 
"INFO_NAME" VARCHAR2(100 BYTE), 
"DESCRIPTION" CLOB, 
"TYPE" VARCHAR2(30 BYTE), 
"NUMBER" VARCHAR2(10 BYTE), 
 CONSTRAINT "DE_VAR_POPULAT_INFO_ID_IDX" PRIMARY KEY ("VARIANT_POPULATION_INFO_ID")
 USING INDEX
 TABLESPACE "TRANSMART"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" 
LOB ("DESCRIPTION") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) ;
--
-- Type: INDEX; Owner: DEAPP; Name: VAR_POPULAT_INFO_DATASET_NAME
--
CREATE INDEX "DEAPP"."VAR_POPULAT_INFO_DATASET_NAME" ON "DEAPP"."DE_VARIANT_POPULATION_INFO" ("DATASET_ID", "INFO_NAME")
TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_DE_VP_INFO_ID
--
  CREATE OR REPLACE TRIGGER "DEAPP"."TRG_DE_VP_INFO_ID" 
before insert on "DEAPP"."DE_VARIANT_POPULATION_INFO"
for each row begin
       	if inserting then
               	if :NEW."VARIANT_POPULATION_INFO_ID" is null then
                       	select DE_VARIANT_POPULATION_INFO_SEQ.nextval into :NEW."VARIANT_POPULATION_INFO_ID" from dual;
               	end if;
       	end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_DE_VP_INFO_ID" ENABLE;
 
