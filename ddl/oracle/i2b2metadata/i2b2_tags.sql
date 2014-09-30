--
-- Type: TABLE; Owner: I2B2METADATA; Name: I2B2_TAGS
--
 CREATE TABLE "I2B2METADATA"."I2B2_TAGS" 
  (	"TAG_ID" NUMBER(18,0) NOT NULL ENABLE, 
"PATH" VARCHAR2(400 BYTE), 
"TAG" VARCHAR2(1000 BYTE), 
"TAG_TYPE" VARCHAR2(400 BYTE), 
"TAGS_IDX" NUMBER NOT NULL ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: I2B2METADATA; Name: TRG_I2B2_TAG_ID
--
  CREATE OR REPLACE TRIGGER "I2B2METADATA"."TRG_I2B2_TAG_ID" 
before insert on "I2B2_TAGS"    
for each row begin     
  if inserting then       
    if :NEW."TAG_ID" is null then          
      select SEQ_I2B2_DATA_ID.nextval into :NEW."TAG_ID" from dual;       
    end if;    
  end if; 
end;





/
ALTER TRIGGER "I2B2METADATA"."TRG_I2B2_TAG_ID" ENABLE;
 
