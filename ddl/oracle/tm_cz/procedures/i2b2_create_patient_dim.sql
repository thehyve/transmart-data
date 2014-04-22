--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_CREATE_PATIENT_DIM
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_CREATE_PATIENT_DIM" 
(
  trial_id VARCHAR2
 ,currentJobID NUMBER := null
)
AS
  TrialID varchar2(100);
    
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);

BEGIN 
  -------------------------------------------------------------
  -- Load the Patient Dimension Table
  -- KCR@20090404 - First Rev
  -- JEA@20091117 - Added auditing
  -------------------------------------------------------------
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
  
  --delete existing data if it exists 
  DELETE 
    FROM PATIENT_DIMENSION
  WHERE 
    sourcesystem_cd like TrialID || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete existing data for trial in I2B2DEMODATA patient_dimension',SQL%ROWCOUNT,stepCt,'Done');
  commit;
  --insert patient data
  INSERT
    INTO PATIENT_DIMENSION
    (
      PATIENT_NUM,
      SEX_CD,
      AGE_IN_YEARS_NUM,
      RACE_CD,
      UPDATE_DATE,
      DOWNLOAD_DATE,
      IMPORT_DATE,
      SOURCESYSTEM_CD
    )
    SELECT
      SEQ_PATIENT_NUM.nextval,
      CASE 
        WHEN UPPER(SEX_CD) = 'MALE' THEN 'M'
        WHEN UPPER(SEX_CD) = 'FEMALE' THEN 'F'
        WHEN UPPER(SEX_CD) = 'UNKNOWN' THEN 'U'
        ELSE sex_cd
      END,
      AGE_IN_YEARS_NUM,
      RACE_CD,
      SYSDATE,
      SYSDATE,
      SYSDATE,
      USUBJID
    FROM
      TM_WZ.PATIENT_INFO
      where UPPER(study_id) = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial in I2B2DEMODATA patient_dimension',SQL%ROWCOUNT,stepCt,'Done');
  COMMIT;

/*
  --Update temp table for UI
  DELETE 
    FROM PATIENT_TRIAL
    WHERE trial = TrialID;
  COMMIT;
  

  INSERT INTO PATIENT_TRIAL (
    PATIENT_NUM, 
    TRIAL) 
  select 
    patient_num,
    TrialID
  from
    patient_dimension
  where
    sourcesystem_cd like TrialID || '%';
  COMMIT;
*/    

  
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
 
