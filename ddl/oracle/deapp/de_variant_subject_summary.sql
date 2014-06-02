--
-- Name: de_variant_subject_summary; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE "DEAPP"."DE_VARIANT_SUBJECT_SUMMARY" (
    variant_subject_summary_id NUMBER(22,0) ,
    chr VARCHAR2(50 BYTE),
    pos NUMBER(22,0),
    dataset_id VARCHAR2(50 BYTE) NOT NULL,
    subject_id VARCHAR2(50 BYTE) NOT NULL,
    rs_id VARCHAR2(50 BYTE),
    variant VARCHAR2(1000 BYTE),
    variant_format VARCHAR2(100 BYTE),
    variant_type VARCHAR2(100 BYTE),
    reference char(1) check( reference in ('T', 'F') ),
    allele1 NUMBER(5,0),
    allele2 NUMBER(5,0),
    assay_id NUMBER(18,0)
);

--
-- Name: COLUMN de_variant_subject_summary.reference; Type: COMMENT; Schema: deapp; Owner: -
--
COMMENT ON COLUMN deapp.de_variant_subject_summary.reference IS 'This column contains a flag whether this subject has a reference value on this variant, or not.';

--
-- Name: COLUMN de_variant_subject_summary.assay_id; Type: COMMENT; Schema: deapp; Owner: -
--
COMMENT ON COLUMN deapp.de_variant_subject_summary.assay_id IS 'Reference to de_subject_sample_mapping';

--
-- Name: variant_subject_summary_id; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE "DEAPP"."DE_VARIANT_SUBJECT_SUMMARY"
    ADD CONSTRAINT variant_subject_summary_id PRIMARY KEY (variant_subject_summary_id);

--
-- Name: variant_subject_summary_uk; Type: INDEX; Schema: deapp; Owner: -
--
CREATE UNIQUE INDEX variant_subject_summary_uk
  ON "DEAPP"."DE_VARIANT_SUBJECT_SUMMARY" (dataset_id, chr, pos, rs_id, subject_id);

--
-- Name: variant_subject_summary_fk; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE "DEAPP"."DE_VARIANT_SUBJECT_SUMMARY"
    ADD FOREIGN KEY (dataset_id) REFERENCES DEAPP.DE_VARIANT_DATASET(dataset_id);

--
-- Type: SEQUENCE; Owner: DEAPP; Name: de_variant_subject_summary_seq
--
CREATE SEQUENCE  "DEAPP"."DE_VARIANT_SUBJECT_SUMMARY_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_VARIANT_POPULATION_INFO_ID
--
create or replace
TRIGGER "DEAPP"."TRG_VARIANT_SUBJECT_SUMMARY_ID"
before insert on DEAPP.DE_VARIANT_SUBJECT_SUMMARY
for each row
begin
   if inserting then
      if :NEW.variant_subject_summary_id is null then
         select DEAPP.DE_VARIANT_SUBJECT_SUMMARY_SEQ.nextval into :NEW.variant_subject_summary_id from dual;
      end if;
  end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_VARIANT_SUBJECT_SUMMARY_ID" ENABLE;