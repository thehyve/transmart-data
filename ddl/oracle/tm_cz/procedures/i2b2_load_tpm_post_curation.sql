--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_LOAD_TPM_POST_CURATION
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_LOAD_TPM_POST_CURATION" 
(
  trial_id 		IN	VARCHAR2
 ,currentJobID	IN	NUMBER := null
 ,rtnCode		OUT	int
)
AS
  --Loading I2B2 TABLES WITH ALL DATA FROM THE TIME POINT MEASUREMENT TABLE
  --KCR: 8.14.2009
  --	JEA@20091117	Added auditing
  --	JEA@20100505	Added return code
  --	JEA@20106014	Exclude Across Trials node when determining root_node name 

  TrialID varchar2(100);
  root_node VARCHAR2(100);

     
  MAXVAL NUMBER;
  MINVAL NUMBER;    
  
    --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);

BEGIN
  
  TrialID := upper(trial_id);
  
  --Set Audit Parameters
  newJobFlag := 0; -- False (Default)
  jobID := currentJobID;

  SELECT sys_context('USERENV', 'CURRENT_SCHEMA') INTO databaseName FROM dual;
  procedureName := $$PLSQL_UNIT;

  --Audit JOB Initialization
  --If Job ID does not exist, then this is a single procedure run and we need to create it
  IF(jobID IS NULL or jobID < 1)
  THEN
    newJobFlag := 1; -- True
    cz_start_audit (procedureName, databaseName, jobID);
  END IF;
    	
  stepCt := 0;
  
  -- determine root node
  select parse_nth_value(c_fullname, 2, '\') into root_node
  from i2b2
  where c_name = TrialID
    and c_fullname not like '%Across Trials%';
  
 /* 
  --Create data for Observation Fact
  --Truncate temp table
  DELETE FROM TMP_TRIAL_DATA;
  COMMIT;  

  --Insert new data into temp table
  --Numeric data
  INSERT
  INTO TMP_TRIAL_DATA
  (
    USUBJID,
    STUDY_ID,
    DATA_TYPE,
    VISIT_NAME,
    DATA_LABEL,
    DATA_VALUE,
    UNIT_CD,
    CATEGORY_PATH,
    PATIENT_NUM,
    SOURCESYSTEM_CD,
    BASE_PATH
  )
  select distinct
    a.usubjid,
    a.study_id, 
    a.data_type,
    a.visit_name,
    a.data_label,
    a.data_value,
    a.unit_cd,
    b.category_path,
    c.patient_num,
    c.sourcesystem_cd,
    t.leaf_node
  from time_point_measurement a
  join category b
    on a.category_cd = b.category_cd
  JOIN patient_dimension c
    on c.sourcesystem_cd = a.usubjid
  join tm_wz.tmp_trial_nodes t
    on a.category_cd = t.category_cd
	   and a.data_label = t.data_label
	   and nvl(a.visit_name,'**NULL**') = nvl(t.visit_name,'**NULL**')
	   and nvl(a.period,'**NULL**') = nvl(t.period,'**NULL**')
	   and nvl(a.sample_type,'**NULL**') = nvl(t.sample_type,'**NULL**')
  where a.data_value is not null
  AND a.suppress_flag = 'N';
commit;

*/

  --Insert into final table
  INSERT
  INTO OBSERVATION_FACT
  (
    PATIENT_NUM,
    CONCEPT_CD,
    MODIFIER_CD,
    VALTYPE_CD,
    TVAL_CHAR,
    NVAL_NUM,
    SOURCESYSTEM_CD,
    IMPORT_DATE,
    VALUEFLAG_CD,
    PROVIDER_ID,
    LOCATION_CD,
    UNITS_CD
  )
  select /*+NO_USE_HASH_AGGREGATION*/ distinct
  c.patient_num,
  i.c_basecode,
  a.study_id,
  a.data_type,
  case 
    when a.data_type = 'T' then 
      a.data_value
    else 'E'  --Stands for Equals for numeric types
  end,
  case 
    when a.data_type = 'N' then 
      a.data_value
    else '' --Null for text types
  end,
  c.sourcesystem_cd, 
  sysdate, 
  '@',
  '@',
  '@',
  a.unit_cd
  from time_point_measurement a
  join category b
    on a.category_cd = b.category_cd
  JOIN patient_dimension c
    on c.sourcesystem_cd = a.usubjid
  join tm_wz.tmp_trial_nodes t
    on a.category_cd = t.category_cd
	   and nvl(a.data_label,'**NULL**') = nvl(t.data_label,'**NULL**')
	   and nvl(a.visit_name,'**NULL**') = nvl(t.visit_name,'**NULL**')
	   and nvl(a.period,'**NULL**') = nvl(t.period,'**NULL**')
	   and nvl(a.sample_type,'**NULL**') = nvl(t.sample_type,'**NULL**')
     and decode(a.data_type,'T',a.data_value,'**NULL**') = nvl(t.data_value,'**NULL**')
  join i2b2 i
  on i.c_fullname = t.leaf_node
  where a.data_value is not null
  AND a.suppress_flag = 'N';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;

  --5 Update I2B2
  --Update I2b2 for correct data type
  update i2b2
  SET c_columndatatype = 'N',
      --Static XML String
      c_metadataxml = '<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis></ValueMetadata>'
  where c_basecode IN (
    select concept_cd from observation_fact
      having Max(valtype_cd) = 'N'
      group by concept_Cd
    )
    and c_fullname like '%' || TrialID || '%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update c_columndatatype and c_metadataxml for numeric data types in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
  commit;
  
  
  --UPDATE VISUAL ATTRIBUTES for Leaf Active (Default is folder)
  update i2b2 a
    set c_visualattributes = 'LA'
    where 1 = (
      select count(*)
      from i2b2 b
      where b.c_fullname like (a.c_fullname || '%'))
    AND c_fullname like '%' || TrialID || '%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update visual attributes for leaf nodes in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
  
  COMMIT;

  --Set c_basecode = null where type is a folder.
  --Basecode is not needed since no records exist on the Observation Fact for Folders.
  update i2b2 
    set c_basecode = ''
    where c_visualattributes = 'FA'
    AND c_fullname like '%' || TrialID || '%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set c_basecode to null for folders in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;

    ---Cleanup OVERALL JOB if this proc is being run standalone
  IF newJobFlag = 1
  THEN
    cz_end_audit (jobID, 'SUCCESS');
  END IF;

	rtnCode := 0;
	
  EXCEPTION
  WHEN OTHERS THEN
    --Handle errors.
    cz_error_handler (jobID, procedureName);
    --End Proc
    cz_end_audit (jobID, 'FAIL');
	rtnCode := 16;
	
END;
/
