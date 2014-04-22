--
-- Type: FUNCTION; Owner: BIOMART; Name: COMPRESSION_RATIO
--
  CREATE OR REPLACE FUNCTION "BIOMART"."COMPRESSION_RATIO" (tabname varchar2) 
return number as 
pct number := 0.000099;
blkcnt number := 0; 
blkcntc number; 
begin
--execute immediate ' create table TEMP$$FOR_TEST pctfree 0 as select * from ' || tabname || ' where rownum < 1';
while ((pct < 100) and (blkcnt < 1000)) loop
execute immediate 'truncate table TEMP$$FOR_TEST';
execute immediate 'insert into TEMP$$FOR_TEST select * from ' || tabname || ' sample block (' || pct || ',10)';
execute immediate 'select count(distinct(dbms_rowid.rowid_block_number(rowid))) from TEMP$$FOR_TEST' into blkcnt;
pct := pct * 10;
end loop;
execute immediate 'alter table TEMP$$FOR_TEST move compress ';
execute immediate 'select
count(distinct(dbms_rowid.rowid_block_number(rowid)))
from TEMP$$FOR_TEST' into blkcntc;
--execute immediate 'drop table TEMP$$FOR_TEST';
return (blkcnt/blkcntc);
end;
 
/
