--
-- Type: TABLE; Owner: I2B2DEMODATA; Name: JMS_MESSAGES
--
 CREATE TABLE "I2B2DEMODATA"."JMS_MESSAGES" 
  (	"MESSAGEID" NUMBER(*,0) NOT NULL ENABLE, 
"DESTINATION" VARCHAR2(255 BYTE) NOT NULL ENABLE, 
"TXID" NUMBER(*,0), 
"TXOP" CHAR(1 BYTE), 
"MESSAGEBLOB" BLOB, 
 PRIMARY KEY ("MESSAGEID", "DESTINATION")
 USING INDEX
 TABLESPACE "I2B2_DATA"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "I2B2_DATA" 
LOB ("MESSAGEBLOB") STORE AS BASICFILE (
 TABLESPACE "I2B2_DATA" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
 NOCACHE LOGGING ) ;
--
-- Type: INDEX; Owner: I2B2DEMODATA; Name: JMS_MESSAGES_DESTINATION
--
CREATE INDEX "I2B2DEMODATA"."JMS_MESSAGES_DESTINATION" ON "I2B2DEMODATA"."JMS_MESSAGES" ("DESTINATION")
TABLESPACE "I2B2_DATA" ;
--
-- Type: INDEX; Owner: I2B2DEMODATA; Name: JMS_MESSAGES_TXOP_TXID
--
CREATE INDEX "I2B2DEMODATA"."JMS_MESSAGES_TXOP_TXID" ON "I2B2DEMODATA"."JMS_MESSAGES" ("TXOP", "TXID")
TABLESPACE "I2B2_DATA" ;