
--
-- Name: de_variant_subject_idx; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE "DEAPP"."DE_VARIANT_SUBJECT_IDX" (
    dataset_id VARCHAR2(50 BYTE),
    subject_id VARCHAR2(50 BYTE),
    "position" NUMBER(22,0),
    variant_subject_idx_id NUMBER(22,0)
) SEGMENT CREATION IMMEDIATE
TABLESPACE "DEAPP";

--
-- Name: variant_subject_idx_uk; Type: INDEX; Schema: deapp; Owner: -
--
CREATE UNIQUE INDEX variant_subject_idx_uk ON "DEAPP"."DE_VARIANT_SUBJECT_IDX" (dataset_id, subject_id, "position");

--
-- Name: variant_subject_idx_fk; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE "DEAPP"."DE_VARIANT_SUBJECT_IDX"
    ADD FOREIGN KEY (dataset_id) REFERENCES DEAPP.DE_VARIANT_DATASET(dataset_id);

--
-- Type: SEQUENCE; Owner: DEAPP; Name: SEQ_VARIANT_POPULATION_DATA_ID
--
CREATE SEQUENCE  "DEAPP"."DE_VARIANT_SUBJECT_IDX_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_VARIANT_POPULATION_DATA_ID
--
create or replace
TRIGGER "DEAPP"."TRG_VARIANT_SUBJECT_IDX_ID"
before insert on DEAPP.DE_VARIANT_SUBJECT_IDX
for each row
begin
   if inserting then
      if :NEW.VARIANT_SUBJECT_IDX_ID is null then
         select DEAPP.DE_VARIANT_SUBJECT_IDX_SEQ.nextval into :NEW.VARIANT_SUBJECT_IDX_ID from dual;
      end if;
  end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_VARIANT_SUBJECT_IDX_ID" ENABLE;