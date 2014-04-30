--
-- Type: TABLE; Owner: BIOMART; Name: BIO_STATS_EXP_MARKER
--
 CREATE TABLE "BIOMART"."BIO_STATS_EXP_MARKER" 
  (	"BIO_MARKER_ID" NUMBER(18,0) NOT NULL ENABLE, 
"BIO_EXPERIMENT_ID" NUMBER(18,0), 
"BIO_STATS_EXP_MARKER_ID" NUMBER(18,0), 
 CONSTRAINT "BIO_S_E_M_PK" PRIMARY KEY ("BIO_MARKER_ID", "BIO_EXPERIMENT_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "BIOMART" ;
--
-- Type: INDEX; Owner: BIOMART; Name: BIO_STATS_EXP_MK_MK_IDX
--
CREATE INDEX "BIOMART"."BIO_STATS_EXP_MK_MK_IDX" ON "BIOMART"."BIO_STATS_EXP_MARKER" ("BIO_MARKER_ID")
TABLESPACE "INDX" 
PARALLEL 4 ;
--
-- Type: INDEX; Owner: BIOMART; Name: BIO_STATS_EXP_MK_EXP_IDX
--
CREATE INDEX "BIOMART"."BIO_STATS_EXP_MK_EXP_IDX" ON "BIOMART"."BIO_STATS_EXP_MARKER" ("BIO_EXPERIMENT_ID")
TABLESPACE "INDX" 
PARALLEL 4 ;