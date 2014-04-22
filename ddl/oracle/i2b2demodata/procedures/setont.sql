--
-- Type: PROCEDURE; Owner: I2B2DEMODATA; Name: SETONT
--
  CREATE OR REPLACE PROCEDURE "I2B2DEMODATA"."SETONT" (sourcevar varchar2) as begin delete from i2b2metadata.i2b2 where sourcesystem_cd=sourcevar;  insert into i2b2metadata.i2b2 select C_HLEVEL, C_FULLNAME, C_NAME, C_SYNONYM_CD, C_VISUALATTRIBUTES, C_TOTALNUM, C_BASECODE , C_METADATAXML , C_FACTTABLECOLUMN , C_TABLENAME , C_COLUMNNAME , C_COLUMNDATATYPE ,C_OPERATOR , C_DIMCODE, C_COMMENT , C_TOOLTIP , UPDATE_DATE , DOWNLOAD_DATE , IMPORT_DATE , SOURCESYSTEM_CD, VALUETYPE_CD from dimloader;   delete from concept_dimension where sourcesystem_cd = sourcevar; insert into concept_dimension (    CONCEPT_CD, CONCEPT_PATH,  NAME_CHAR, CONCEPT_BLOB, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD,  TABLE_NAME) select  c_basecode,  c_fullname||'\', c_name, null, '8-oct-07','8-oct-07',	'8-oct-07',	sourcesystem_cd,'CONCEPT_DIMENSION' from i2b2metadata.i2b2 where sourcesystem_cd=sourcevar and c_basecode is not null;end;
 

 
 
 
 
 
 
 
 
 
 
/
 
