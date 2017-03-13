--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: SET_UPLOAD_STATUS
--
 CREATE TABLE "I2B2DEMODATA"."SET_UPLOAD_STATUS" 
  (	"UPLOAD_ID" NUMBER NOT NULL ENABLE, 
"SET_TYPE_ID" NUMBER(38,0) NOT NULL ENABLE, 
"SOURCE_CD" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"NO_OF_RECORD" NUMBER, 
"LOADED_RECORD" NUMBER, 
"DELETED_RECORD" NUMBER, 
"LOAD_DATE" DATE NOT NULL ENABLE, 
"END_DATE" DATE, 
"LOAD_STATUS" VARCHAR2(100 BYTE), 
"MESSAGE" CLOB, 
"INPUT_FILE_NAME" CLOB, 
"LOG_FILE_NAME" CLOB, 
"TRANSFORM_NAME" VARCHAR2(500 BYTE), 
 CONSTRAINT "PK_UP_UPSTATUS_IDSETTYPEID" PRIMARY KEY ("UPLOAD_ID", "SET_TYPE_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" 
LOB ("MESSAGE") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) 
LOB ("INPUT_FILE_NAME") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) 
LOB ("LOG_FILE_NAME") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) ;

--
-- Type: REF_CONSTRAINT; Owner: I2B2DEMODATA; Name: FK_UP_SET_TYPE_ID
--
ALTER TABLE "I2B2DEMODATA"."SET_UPLOAD_STATUS" ADD CONSTRAINT "FK_UP_SET_TYPE_ID" FOREIGN KEY ("SET_TYPE_ID")
 REFERENCES "I2B2DEMODATA"."SET_TYPE" ("ID") ENABLE;

