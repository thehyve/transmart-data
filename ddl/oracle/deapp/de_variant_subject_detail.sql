--
-- Name: de_variant_subject_detail; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE "DEAPP"."DE_VARIANT_SUBJECT_DETAIL" (
    variant_subject_detail_id NUMBER(22,0) NOT NULL,
    dataset_id VARCHAR2(50 BYTE),
    chr VARCHAR2(50 BYTE),
    pos NUMBER(22,0),
    rs_id VARCHAR2(50 BYTE),
    ref VARCHAR2(500 BYTE),
    alt VARCHAR2(500 BYTE),
    qual VARCHAR2(100 BYTE),
    filter VARCHAR2(50 BYTE),
    info VARCHAR2(4000 BYTE),
    format VARCHAR2(500 BYTE),
    variant_value CLOB

) SEGMENT CREATION IMMEDIATE
TABLESPACE "DEAPP";

--
-- Name: variant_subject_detail_id; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE deapp.de_variant_subject_detail
    ADD CONSTRAINT variant_subject_detail_id_pk PRIMARY KEY (variant_subject_detail_id);

--
-- Name: de_variant_sub_detail_idx2; Type: INDEX; Schema: deapp; Owner: -
--
CREATE INDEX de_variant_sub_detail_idx2 ON deapp.de_variant_subject_detail (dataset_id, chr);

--
-- Name: de_variant_sub_dt_idx1; Type: INDEX; Schema: deapp; Owner: -
--
CREATE INDEX de_variant_sub_dt_idx1 ON deapp.de_variant_subject_detail (dataset_id, rs_id);

--
-- Name: variant_subject_detail_uk; Type: INDEX; Schema: deapp; Owner: -
--
CREATE UNIQUE INDEX variant_subject_detail_uk ON deapp.de_variant_subject_detail (dataset_id, chr, pos, rs_id);

--
-- Name: variant_subject_detail_fk; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE deapp.de_variant_subject_detail
    ADD FOREIGN KEY (dataset_id) REFERENCES deapp.de_variant_dataset(dataset_id);

--
-- Type: SEQUENCE; Owner: DEAPP; Name: SEQ_VARIANT_POPULATION_INFO_ID
--
CREATE SEQUENCE  "DEAPP"."DE_VARIANT_SUBJECT_DETAIL_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_VARIANT_POPULATION_INFO_ID
--
create or replace
TRIGGER "DEAPP"."TRG_VARIANT_SUBJECT_DETAIL_ID"
before insert on DEAPP.de_variant_subject_detail
for each row
begin
   if inserting then
      if :NEW.variant_subject_detail_id is null then
         select DEAPP.DE_VARIANT_SUBJECT_DETAIL_SEQ.nextval into :NEW.variant_subject_detail_id from dual;
      end if;
  end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_VARIANT_SUBJECT_DETAIL_ID" ENABLE;


