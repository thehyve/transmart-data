--
-- Type: TABLE; Owner: SEARCHAPP; Name: SUBSET
--
 CREATE TABLE "SEARCHAPP"."SUBSET" 
  (	"SUBSET_ID" NUMBER NOT NULL ENABLE, 
"DESCRIPTION" VARCHAR2(1000 BYTE) NOT NULL ENABLE, 
"CREATE_DATE" DATE NOT NULL ENABLE, 
"CREATING_USER" VARCHAR2(200 BYTE) NOT NULL ENABLE, 
"PUBLIC_FLAG" CHAR(1 BYTE) NOT NULL ENABLE, 
"DELETED_FLAG" CHAR(1 BYTE) NOT NULL ENABLE, 
"QUERY_MASTER_ID_1" NUMBER NOT NULL ENABLE, 
"QUERY_MASTER_ID_2" NUMBER, 
"STUDY" VARCHAR2(200 BYTE)
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

