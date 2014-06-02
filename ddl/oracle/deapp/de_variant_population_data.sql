
--
-- Name: de_variant_population_data; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE "DEAPP"."DE_VARIANT_POPULATION_DATA" (
    variant_population_data_id NUMBER(22,0),
    dataset_id VARCHAR2(50 BYTE),
    chr VARCHAR2(50 BYTE),
    pos number(18,0),
    info_name VARCHAR2(100 BYTE),
    info_index number DEFAULT 0,
    integer_value number(22,0),
    float_value number,
    text_value varchar2(4000 BYTE)
) SEGMENT CREATION IMMEDIATE
TABLESPACE "DEAPP";

--
-- Name: de_variant_metadata_pk; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.DE_VARIANT_POPULATION_DATA
  ADD CONSTRAINT DE_VARIANT_POPULATION_DATA_PK PRIMARY KEY (variant_population_data_id);

--
-- Name: dataset_id; Type: FK CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE DEAPP.DE_VARIANT_POPULATION_DATA
   ADD FOREIGN KEY (DATASET_ID)
   REFERENCES deapp.de_variant_dataset(DATASET_ID);

--
-- Name: de_variant_population_data_default_idx; Type: INDEX; Schema: deapp; Owner: -
--
CREATE UNIQUE INDEX DEAPP.de_variant_pop_data_idx
    ON DEAPP.DE_VARIANT_POPULATION_DATA (dataset_id, chr, pos, info_name);


--
-- Type: SEQUENCE; Owner: DEAPP; Name: SEQ_VARIANT_POPULATION_DATA_ID
--
CREATE SEQUENCE  "DEAPP"."SEQ_VARIANT_POPULATION_DATA_ID"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE ;

--
-- Type: TRIGGER; Owner: DEAPP; Name: TRG_VARIANT_POPULATION_DATA_ID
--
create or replace
TRIGGER "DEAPP"."TRG_VARIANT_POPULATION_DATA_ID"
before insert on DEAPP.DE_VARIANT_POPULATION_DATA
for each row
begin
   if inserting then
      if :NEW.VARIANT_POPULATION_DATA_ID is null then
         select DEAPP.SEQ_VARIANT_POPULATION_DATA_ID.nextval into :NEW.VARIANT_POPULATION_DATA_ID from dual;
      end if;
  end if;
end;
/
ALTER TRIGGER "DEAPP"."TRG_VARIANT_POPULATION_DATA_ID" ENABLE;
