--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_CREATE_PATIENT_TRIAL
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_CREATE_PATIENT_TRIAL" 
(
  TrialID 		IN	VARCHAR2
 ,study_type 	IN	VARCHAR2 := NULL
 ,currentJobID 	IN	NUMBER := null
 ,rtnCode		OUT	int
)
AS
		
  -------------------------------------------------------------
  -- Insert records into the Patient Trial table for new Trials
  -- KCR@20090518 - First Rev
  -- JEA@20091013 - Added new column secure_obj_token and logic for Public Study
  -- JEA@20091118 - Added auditing
  -- JEA@20100112 - Set secure_obj_token to EXP:PUBLIC for \Internal Studies\ and \Experimental Medicine Study\Normals\
  -- JEA@20100505 - Added return code
  -------------------------------------------------------------
  
	StudyType varchar2(100);
	  
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);

BEGIN

    StudyType := study_type;
  
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
  	
	if StudyType is null then
		StudyType := 'Secured';
	end if;

  
  --Remove existing records
  delete 
    from patient_trial
  where 
     trial  = TrialID;
  stepCt := stepCt + 1;
  cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2DEMODATA patient_trial',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;
  
  insert into i2b2demodata.patient_trial
  (patient_num
  ,trial
  ,secure_obj_token
  )
  select 
    patient_num, 
    TrialID,
	decode(studyType,'Public Studies','EXP:PUBLIC'
	                ,'Internal Studies','EXP:PUBLIC'
					,'Experimental Medicine Study',decode(TrialId,'NORMALS','EXP:PUBLIC','EXP:' || TrialID)
					,'EXP:' || TrialID)
  from 
    patient_dimension
  where
    sourcesystem_cd like TrialID || '%';
  stepCt := stepCt + 1;
 cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial into I2B2DEMODATA patient_trial',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;
    
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
