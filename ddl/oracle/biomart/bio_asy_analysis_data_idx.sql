--
-- Type: TABLE; Owner: BIOMART; Name: BIO_ASY_ANALYSIS_DATA_IDX
--
 CREATE TABLE "BIOMART"."BIO_ASY_ANALYSIS_DATA_IDX" 
  (	"BIO_ASY_ANALYSIS_DATA_IDX_ID" NUMBER NOT NULL ENABLE, 
"EXT_TYPE" VARCHAR2(255 BYTE) NOT NULL ENABLE, 
"FIELD_IDX" NUMBER(10,0) NOT NULL ENABLE, 
"FIELD_NAME" VARCHAR2(255 BYTE) NOT NULL ENABLE, 
"DISPLAY_IDX" NUMBER(10,0) NOT NULL ENABLE, 
"DISPLAY_NAME" VARCHAR2(255 BYTE) NOT NULL ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: BIOMART; Name: TRG_BIO_ASY_ADI_ID
--
  CREATE OR REPLACE TRIGGER "BIOMART"."TRG_BIO_ASY_ADI_ID" 
before insert on biomart.bio_asy_analysis_data_idx
for each row begin
       	if inserting then
               	if :NEW.bio_asy_analysis_data_idx_id is null then
                       	select seq_bio_data_id.nextval into :NEW.bio_asy_analysis_data_idx_id from dual;
               	end if;
       	end if;
end;
/
ALTER TRIGGER "BIOMART"."TRG_BIO_ASY_ADI_ID" ENABLE;
 
