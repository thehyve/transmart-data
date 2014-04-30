--
-- Type: TABLE; Owner: TM_CZ; Name: DE_SNP_INFO_RELEASE
--
 CREATE TABLE "TM_CZ"."DE_SNP_INFO_RELEASE" 
  (	"SNP_INFO_ID" NUMBER(22,0), 
"NAME" VARCHAR2(255 BYTE), 
"CHROM" VARCHAR2(16 BYTE), 
"CHROM_POS" NUMBER
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;