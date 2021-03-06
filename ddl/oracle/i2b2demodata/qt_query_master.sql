--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: QT_QUERY_MASTER
--
 CREATE TABLE "I2B2DEMODATA"."QT_QUERY_MASTER" 
  (	"QUERY_MASTER_ID" NUMBER(5,0), 
"NAME" VARCHAR2(250 BYTE) NOT NULL ENABLE, 
"USER_ID" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"GROUP_ID" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"CREATE_DATE" DATE NOT NULL ENABLE, 
"DELETE_DATE" DATE, 
"REQUEST_XML" CLOB, 
"DELETE_FLAG" VARCHAR2(3 BYTE), 
"GENERATED_SQL" CLOB, 
"I2B2_REQUEST_XML" CLOB, 
"MASTER_TYPE_CD" VARCHAR2(2000 BYTE), 
"PLUGIN_ID" NUMBER(10,0), 
 PRIMARY KEY ("QUERY_MASTER_ID")
 USING INDEX
 TABLESPACE "I2B2_DATA"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2_DATA" 
LOB ("REQUEST_XML") STORE AS BASICFILE (
 TABLESPACE "I2B2_DATA" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
 NOCACHE LOGGING ) 
LOB ("GENERATED_SQL") STORE AS BASICFILE (
 TABLESPACE "I2B2_DATA" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
 NOCACHE LOGGING ) 
LOB ("I2B2_REQUEST_XML") STORE AS BASICFILE (
 TABLESPACE "I2B2_DATA" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) ;

--
-- Type: INDEX; Owner: I2B2DEMODATA; Name: QT_IDX_QM_UGID
--
CREATE INDEX "I2B2DEMODATA"."QT_IDX_QM_UGID" ON "I2B2DEMODATA"."QT_QUERY_MASTER" ("USER_ID", "GROUP_ID", "MASTER_TYPE_CD")
TABLESPACE "I2B2_DATA" ;

