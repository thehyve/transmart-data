--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_PROCESS_RAW_DATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_PROCESS_RAW_DATA" 
(
  in_trialID varchar2
 ,currentJobID NUMBER := null
)
AS

	--	JEA@20100525	Added auditing
	--	JEA@20100610	Generate USUBJID from study_id, subject_id and site_id if USUBJID is null
	--					      This is mainly for Public Studies
  --  JEA@20100616  Delete all data for study from time_point_measurement_raw, no incremental loads of data
  --  JDC@20110822  Added logic for studies that have subject IDs and incomplete USUBJIDs
	
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  nullSubjectID INTEGER;
  nullUSUBJID INTEGER;
  trialID varchar2(255);
  
BEGIN
 
  --Set Audit Parameters
  newJobFlag := 0; -- False (Default)
  jobID := currentJobID;
  nullSubjectID := 0;
  nullUSUBJID := 0;
  
  trialID := upper(in_trialID);

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
  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Start Procedure',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  
    	--Fix category records
	UPDATE TM_LZ.time_point_measurement
	SET  study_id = upper(study_id);
	  
	TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Set study id to UPPERCASE in TM_LZ.time_point_measurement',SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;	
  
	commit;
  
	UPDATE TM_LZ.CATEGORY
	SET study_id = upper(study_id);
  
	TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Set study id to UPPERCASE in TM_LZ.CATEGORY',SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;	
  
	commit;
  
  
  
  --Record counts to counts table
  INSERT
  INTO TM_LZ.TPM_COUNTS
  (
    STUDY_ID,
    CATEGORY_CD,
    RECORD_COUNT,
    LOAD_DATE
  )
  select 
    study_id,
    category_cd, 
    count(*),
    sysdate
    from TM_LZ.time_point_measurement
    where study_id = trialID
    group by 
      study_id,
      category_cd;

  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Add study counts to TM_LZ tpm_counts',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  commit;
    
  --Delete data from Time Point Measurement raw table where Trial Number and Category Code match.
  delete from TM_LZ.time_point_measurement_raw
    where study_id = trialID;
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Deleted study/category_cd from TM_LZ time_point_measurement_raw',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  COMMIT;
  
  
  --select count(*) INTO nullSubjectID from TM_LZ.time_point_measurement where subject_id is null;
  select count(*) INTO nullUSUBJID from TM_LZ.time_point_measurement where usubjid is null;
  
  If (nullUSUBJID > 0) THEN
  
    --	Create USUBJID if null, this is usually only necessary for Public Studies
    update TM_LZ.time_point_measurement
    set usubjid = study_id || subject_id || site_id;
      
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Created missing USUBJID in TM_LZ time_point_measurement',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
    
    ELSE
        update TM_LZ.time_point_measurement
        set subject_id = null
        where subject_id is not null;
      TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Removed Subject IDs where USUBJ IDs exist',SQL%ROWCOUNT,stepCt,'Done');
      stepCt := stepCt + 1;	
  END IF;
  
	  

    
  commit;
  --Insert new records into Raw tables
  insert into 
    TM_LZ.time_point_measurement_raw
  select * 
    from TM_LZ.time_point_measurement
    where study_id = trialID;
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Inserted study/category_cd into TM_LZ time_point_measurement_raw',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  commit;
  
  --Clear the Working zone table
  execute immediate('truncate table TM_WZ.time_point_measurement');
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Truncate TM_WZ time_point_measurement',0,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  --Load the new records
  insert into TM_WZ.time_point_measurement
  select distinct * 
    from TM_LZ.time_point_measurement a
      where data_value is not null
        and study_id = trialID;
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Inserted study into TM_WZ time_point_measurement',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  commit;
  
  --CATEGORY DATA
  --DELETE DATA from category table.
  delete 
    from TM_LZ.category 
      where study_id = trialID;
  --      and category_cd IN (Select category_cd from TM_LZ.stg_category where study_id = trialID);
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Delete category from TM_LZ category',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  COMMIT;

  --insert new records into the category table
  INSERT INTO TM_LZ.CATEGORY
    (study_id, category_cd, category_path)
  SELECT trialID, category_cd, rdc_init_cap(category_path) as category_path
    FROM TM_LZ.stg_category;
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Insert category into TM_LZ category',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  COMMIT;

  --clear the category table in the working zone
	execute immediate('truncate table TM_WZ.category');
	  
  TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Truncate TM_WZ category',0,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  --Insert the Category data converting the path to proper case
  INSERT INTO TM_WZ.CATEGORY
  select
    category_Cd, 
    TM_CZ.rdc_init_cap(category_path) as category_path,
    study_id
  FROM
    TM_LZ.category
    where study_id = trialID;
	  
	TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Insert category into TM_WZ category',SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;	
  
  commit;

	--Fix category records
	UPDATE TM_WZ.CATEGORY
	SET CATEGORY_PATH = REPLACE(CATEGORY_PATH, 'Elisa', 'ELISA')
	where category_path like '%Elisa%';
	  
	TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'Fix any ELISA records',SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;	
  
	commit;
    
  
	--Clean up LZ tables
	
--	execute immediate('truncate table TM_LZ.stg_category');
--	execute immediate('truncate table TM_LZ.time_point_measurement');

	TM_CZ.cz_write_audit(jobId,databaseName,procedureName,'End Procedure',0,stepCt,'Done');
	stepCt := stepCt + 1;	
 
     ---Cleanup OVERALL JOB if this proc is being run standalone
  IF newJobFlag = 1
  THEN
    cz_end_audit (jobID, 'SUCCESS');
  END IF;
  
    EXCEPTION
  WHEN OTHERS THEN
    --Handle errors.
    cz_error_handler (jobID, procedureName);
    --End Proc
    cz_end_audit (jobID, 'FAIL');
  
END;
/
