
--
-- Name: de_variant_metadata; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE "DEAPP"."DE_VARIANT_METADATA" (
    de_variant_metadata_id NUMBER(22,0),
    dataset_id VARCHAR2(50 BYTE),
    key VARCHAR2(255 BYTE),
    value CLOB
) SEGMENT CREATION IMMEDIATE
TABLESPACE "DEAPP";

--
-- Name: de_variant_metadata_pk; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.DE_VARIANT_METADATA
  ADD CONSTRAINT DE_VARIANT_METADATA_PK PRIMARY KEY (de_variant_metadata_id);

--
-- Name: dataset_id; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.de_variant_metadata
   ADD FOREIGN KEY (DATASET_ID)
   REFERENCES deapp.de_variant_dataset(DATASET_ID);

--
-- Type: SEQUENCE; Owner: DEAPP; Name: SEQ_DE_MRNA_ANNOTATION_ID
--
CREATE SEQUENCE  "DEAPP"."SEQ_DE_VARIANT_METADATA_ID"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_DE_MRNA_ANNOTATION_ID
--
create or replace
TRIGGER "DEAPP"."TRG_DE_VARIANT_METADATA_ID"
before insert on DEAPP.DE_VARIANT_METADATA
for each row
begin
   if inserting then
      if :NEW.DE_VARIANT_METADATA_ID is null then
         select DEAPP.SEQ_DE_VARIANT_METADATA_ID.nextval into :NEW.DE_VARIANT_METADATA_ID from dual;
      end if;
  end if;
end;

ALTER TRIGGER "DEAPP"."TRG_DE_VARIANT_METADATA_ID" ENABLE;