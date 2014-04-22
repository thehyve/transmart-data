--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_BACKOUT_TRIAL
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_BACKOUT_TRIAL" 
(
  trial_id VARCHAR2
 ,path_string varchar2
 ,currentJobID NUMBER := null
)
AS

--	JEA@20100106	New
--	JEA@20100112	Added removal of SECURITY records from observation_fact

  TrialID varchar2(100);
  TrialType VARCHAR2(250);
  
  
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);

BEGIN
  --TrialID := upper(trial_id);
  TrialId := trial_id;
  
  stepCt := 0;
	
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
  
  if path_string != ''  or path_string != '%'
  then 
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_backout_trial',0,stepCt,'Done');

	--	delete all i2b2 nodes
	
  
  
  
  
   if path_string != ''  or path_string != '%'
  then 
    --I2B2
    DELETE 
      FROM OBSERVATION_FACT 
    WHERE 
      upper(SOURCESYSTEM_CD) = upper(TrialId);
	  stepCt := stepCt + 1;
	  cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
    COMMIT;
	

      --CONCEPT DIMENSION
    DELETE 
      FROM CONCEPT_DIMENSION
    WHERE 
      upper(SOURCESYSTEM_CD) = upper(TrialId);
	  stepCt := stepCt + 1;
	  cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
    COMMIT;
    
      --I2B2
      DELETE
        FROM i2b2
      WHERE 
        upper(SOURCESYSTEM_CD) = upper(TrialId);
	  stepCt := stepCt + 1;
	  cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
    COMMIT;
  END IF;
  
  --i2b2_secure
      DELETE
        FROM i2b2_secure
      WHERE 
        upper(SOURCESYSTEM_CD) = upper(TrialId);
	  stepCt := stepCt + 1;
	  cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2METADATA i2b2_secure',SQL%ROWCOUNT,stepCt,'Done');
    COMMIT;

  --concept_counts
      DELETE
        FROM concept_counts
      WHERE 
        concept_path LIKE path_string || '%';
	  stepCt := stepCt + 1;
	  CZ_WRITE_AUDIT(JOBID,DATABASENAME,PROCEDURENAME,'Delete data for trial from I2B2DEMODATA concept_counts',SQL%ROWCOUNT,STEPCT,'Done');
    COMMIT;
    
  
  
  
  
  
	
	--	delete any i2b2_tag data
	
	delete from i2b2_tags
	where path like path_string || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2METADATA i2b2_tags',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--	delete clinical data
	
	delete from lz_src_clinical_data
	where study_id = trialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from lz_src_clinical_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
		
	--	delete observation_fact SECURITY data, do before patient_dimension delete
	
	delete from observation_fact f
	where f.concept_cd = 'SECURITY'
	  and f.patient_num in
	     (select distinct p.patient_num from patient_dimension p
		  where p.sourcesystem_cd like trialId || '%');
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete SECURITY data for trial from I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	--	delete patient data
	
	delete from patient_dimension
	where sourcesystem_cd like trialId || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2DEMODATA patient_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	delete from patient_trial
	where trial=  trialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from I2B2DEMODATA patient_trial',SQL%ROWCOUNT,stepCt,'Done');
	commit;

  end if;
  
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
