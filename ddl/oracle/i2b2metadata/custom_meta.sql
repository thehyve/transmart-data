--
-- Type: TABLE; Owner: I2B2METADATA; Name: CUSTOM_META
--
 CREATE TABLE "I2B2METADATA"."CUSTOM_META" 
  (	"C_HLEVEL" NUMBER(22,0) NOT NULL ENABLE, 
"C_FULLNAME" VARCHAR2(700 BYTE) NOT NULL ENABLE, 
"C_NAME" VARCHAR2(2000 BYTE) NOT NULL ENABLE, 
"C_SYNONYM_CD" CHAR(1 BYTE) NOT NULL ENABLE, 
"C_VISUALATTRIBUTES" CHAR(3 BYTE) NOT NULL ENABLE, 
"C_TOTALNUM" NUMBER(22,0), 
"C_BASECODE" VARCHAR2(50 BYTE), 
"C_METADATAXML" CLOB, 
"C_FACTTABLECOLUMN" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"C_TABLENAME" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"C_COLUMNNAME" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"C_COLUMNDATATYPE" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
"C_OPERATOR" VARCHAR2(10 BYTE) NOT NULL ENABLE, 
"C_DIMCODE" VARCHAR2(900 BYTE) NOT NULL ENABLE, 
"C_COMMENT" CLOB, 
"C_TOOLTIP" VARCHAR2(900 BYTE), 
"UPDATE_DATE" DATE NOT NULL ENABLE, 
"DOWNLOAD_DATE" DATE, 
"IMPORT_DATE" DATE, 
"SOURCESYSTEM_CD" VARCHAR2(50 BYTE), 
"VALUETYPE_CD" VARCHAR2(50 BYTE), 
"M_APPLIED_PATH" VARCHAR2(700 BYTE) NOT NULL ENABLE, 
"M_EXCLUSION_CD" VARCHAR2(25 BYTE), 
"C_PATH" VARCHAR2(700 BYTE), 
"C_SYMBOL" VARCHAR2(50 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" 
LOB ("C_METADATAXML") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) 
LOB ("C_COMMENT") STORE AS BASICFILE (
 TABLESPACE "TRANSMART" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
 NOCACHE LOGGING ) ;

--
-- Type: INDEX; Owner: I2B2METADATA; Name: META_FULLNAME_CUSTOM_IDX
--
CREATE INDEX "I2B2METADATA"."META_FULLNAME_CUSTOM_IDX" ON "I2B2METADATA"."CUSTOM_META" ("C_FULLNAME")
TABLESPACE "INDX" ;

--
-- Type: INDEX; Owner: I2B2METADATA; Name: META_APPLIED_PATH_CUSTOM_IDX
--
CREATE INDEX "I2B2METADATA"."META_APPLIED_PATH_CUSTOM_IDX" ON "I2B2METADATA"."CUSTOM_META" ("M_APPLIED_PATH")
TABLESPACE "INDX" ;

