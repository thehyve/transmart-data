--
-- Type: SEQUENCE; Owner: TM_CZ; Name: SEQ_CZ_DATA
--
CREATE SEQUENCE  "TM_CZ"."SEQ_CZ_DATA"  MINVALUE 1 MAXVALUE 999999999999999999999999 INCREMENT BY 1 START WITH 5 CACHE 2 NOORDER  NOCYCLE ;

--
-- Type: TABLE; Owner: TM_CZ; Name: CZ_DATA
--
 CREATE TABLE "TM_CZ"."CZ_DATA" 
  (	"DATA_ID" NUMBER(18,0) NOT NULL ENABLE, 
"DATA_NAME" NVARCHAR2(200), 
"TECHNICAL_DESC" NVARCHAR2(1000), 
"BUSINESS_DESC" NVARCHAR2(1000), 
"CREATE_DATE" DATE, 
"CUSTODIAN_ID" NUMBER(18,0), 
"OWNER_ID" NUMBER(18,0), 
"LOAD_FREQ" VARCHAR2(20 BYTE), 
 CONSTRAINT "CZ_DATA_PK" PRIMARY KEY ("DATA_ID")
 USING INDEX
 TABLESPACE "INDX"  ENABLE
  ) SEGMENT CREATION IMMEDIATE
 TABLESPACE "TRANSMART" ;

--
-- Type: TRIGGER; Owner: TM_CZ; Name: TRG_CZ_DATA_ID
--
  CREATE OR REPLACE TRIGGER "TM_CZ"."TRG_CZ_DATA_ID" before insert on "CZ_DATA"    for each row 
begin     if inserting then       if :NEW."DATA_ID" is null then          select SEQ_CZ_DATA.nextval into :NEW."DATA_ID" from dual;       end if;    end if; end;









/
ALTER TRIGGER "TM_CZ"."TRG_CZ_DATA_ID" ENABLE;
 
