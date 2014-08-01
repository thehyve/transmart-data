--
-- Type: TABLE; Owner: AMAPP; Name: AM_TAG_ASSOCIATION
--
 CREATE TABLE "AMAPP"."AM_TAG_ASSOCIATION" 
  (	"SUBJECT_UID" NVARCHAR2(300) NOT NULL ENABLE, 
"OBJECT_UID" NVARCHAR2(300) NOT NULL ENABLE, 
"OBJECT_TYPE" NVARCHAR2(50), 
"TAG_ITEM_ID" NUMBER(18,0), 
 PRIMARY KEY ("SUBJECT_UID", "OBJECT_UID")
 USING INDEX
 TABLESPACE "TRANSMART"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;
