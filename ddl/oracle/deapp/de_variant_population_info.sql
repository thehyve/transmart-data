
--
-- Name: de_variant_population_info; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE "DEAPP"."DE_VARIANT_POPULATION_INFO" (
    variant_population_info_id NUMBER(22,0),
    dataset_id VARCHAR2(50 BYTE),
    info_name VARCHAR2(100 BYTE),
    description VARCHAR2(4000 BYTE),
    type VARCHAR2(30 BYTE),
    "number" VARCHAR2(10 BYTE)
) SEGMENT CREATION IMMEDIATE
TABLESPACE "DEAPP";

--
-- Name: de_variant_metadata_pk; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.DE_VARIANT_POPULATION_INFO
  ADD CONSTRAINT DE_VARIANT_POPULATION_INFO_PK PRIMARY KEY (variant_population_info_id);

--
-- Name: dataset_id; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.DE_VARIANT_POPULATION_INFO
   ADD FOREIGN KEY (DATASET_ID)
   REFERENCES deapp.de_variant_dataset(DATASET_ID);

--
-- Name: de_variant_population_info_default_idx; Type: INDEX; Schema: deapp; Owner: -
--
CREATE UNIQUE INDEX DEAPP.de_variant_pop_info_idx
    ON DEAPP.DE_VARIANT_POPULATION_INFO (dataset_id, info_name);


--
-- Type: SEQUENCE; Owner: DEAPP; Name: SEQ_VARIANT_POPULATION_INFO_ID
--
CREATE SEQUENCE  "DEAPP"."SEQ_VARIANT_POPULATION_INFO_ID"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_VARIANT_POPULATION_INFO_ID
--
create or replace
TRIGGER "DEAPP"."TRG_VARIANT_POPULATION_INFO_ID"
before insert on DEAPP.DE_VARIANT_POPULATION_INFO
for each row
begin
   if inserting then
      if :NEW.VARIANT_POPULATION_INFO_ID is null then
         select DEAPP.SEQ_VARIANT_POPULATION_INFO_ID.nextval into :NEW.VARIANT_POPULATION_INFO_ID from dual;
      end if;
  end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_VARIANT_POPULATION_INFO_ID" ENABLE;
