--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: QT_BREAKDOWN_PATH
--
 CREATE TABLE "I2B2DEMODATA"."QT_BREAKDOWN_PATH" 
  (	"NAME" VARCHAR2(100 BYTE), 
"VALUE" VARCHAR2(2000 BYTE), 
"CREATE_DATE" DATE, 
"UPDATE_DATE" DATE, 
"USER_ID" VARCHAR2(50 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2_DATA" ;