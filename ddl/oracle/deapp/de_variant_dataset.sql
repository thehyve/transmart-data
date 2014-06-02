--
-- Name: de_variant_dataset; Type: TABLE; Schema: deapp; Owner: -
--
  CREATE TABLE "DEAPP"."DE_VARIANT_DATASET"
   (
      "DATASET_ID" VARCHAR2(50 BYTE),
      "DATASOURCE_ID" VARCHAR2(200 BYTE),
      "ETL_ID" VARCHAR2(20 BYTE),
      "ETL_DATE" DATE,
      "GENOME" VARCHAR2(50 BYTE),
      "METADATA_COMMENT" CLOB,
      "VARIANT_DATASET_TYPE" VARCHAR2(50 BYTE),
      "GPL_ID" VARCHAR2(50 BYTE)
   ) SEGMENT CREATION IMMEDIATE
   TABLESPACE "DEAPP" ;

--
-- Name: dataset_id; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.DE_VARIANT_DATASET
  ADD CONSTRAINT DE_VARIANT_DATASET_PK PRIMARY KEY (DATASET_ID);

-- Cannot add the foreign key to GPL_INFO, as that table doesn't have
-- a unique constraint or a primary key defined on that column
-- ALTER TABLE DEAPP.DE_VARIANT_DATASET
--   ADD FOREIGN KEY (GPL_ID)
--   REFERENCES deapp.de_gpl_info(platform);

