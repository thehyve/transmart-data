--
-- Type: FUNCTION; Owner: TM_CZ; Name: INSERT_ETL_JOB_STEP
--
  CREATE OR REPLACE FUNCTION "TM_CZ"."INSERT_ETL_JOB_STEP" (
  jobrunid IN CONTROL.AZ_JOB_RUN.JOB_RUN_ID%TYPE, 
  stepname IN CONTROL.CZ_JOB_STEP.STEP_NAME%TYPE,
  stepDesc IN CONTROL.CZ_JOB_STEP.STEP_DESC%TYPE,
  tablename IN CONTROL.CZ_JOB_STEP_EXP_RESULT.TABLE_NAME%TYPE,
  dmltype IN CONTROL.CZ_JOB_STEP_EXP_RESULT.DML_TYPE%TYPE,
  expRecordcnt IN CONTROL.CZ_JOB_STEP_EXP_RESULT.EXP_RECORD_CNT%TYPE
)

  RETURN CONTROL.AZ_JOB_STEP_RUN.JOB_STEP_RUN_ID%TYPE

IS

  insertDt CONTROL.AZ_JOB_RUN.START_DATE%TYPE;
  --ID
  seqID CONTROL.CZ_JOB_X_JOB_STEP.SEQ_ID%TYPE;
  jobStepID CONTROL.CZ_JOB_STEP.JOB_STEP_ID%TYPE; 
  jobID CONTROL.CZ_JOB_X_JOB_STEP.JOB_ID%TYPE;
  
  --return value
  jobStepRunID CONTROL.AZ_JOB_STEP_RUN.JOB_STEP_RUN_ID%TYPE; 

BEGIN
  -------------------------------------------------------------------------------
   -- Inserts a record into the AZ_JOB_RUN_STEP 
   -- Returns the job step id for updating the step.
   -- KCR@20090109 - First rev. 
  --  KCR@20090330 - rewriting for new data structure

   -------------------------------------------------------------------------------
  --get insert date/time
  insertDt := SYSDATE;
  --job_step_id := 0;

  --get the job id
  select job_id into jobID
    from control.az_job_run
    where job_run_id = jobRunID;


  --DETERMINE IF STEP EXISTS:
    select coalesce(max(b.seq_id), 1),
      coalesce(max(a.job_step_id),0)
      into seqID, jobStepID
    from control.cz_job_step a
    left outer join control.cz_job_x_job_step b
      on a.job_step_id = b.job_step_id
    where a.step_name = stepName;
        
     dbms_output.put_line(seqID ||'A' || jobStepID ||'B' || jobID);
        
  --doesn't exist
  if jobStepID = 0 
    then
    --1. Create a new step
    INSERT INTO 
    CZ_JOB_STEP 
      (STEP_NAME, 
      STEP_DESC)
      VALUES (
    stepName,
    stepDesc);
  COMMIT;
 
    --2. get the step id
    select coalesce(max(b.seq_id)+1, 1),
      max(a.job_step_id)
      into seqID, jobStepID
    from control.cz_job_step a
    left outer join control.cz_job_x_job_step b
      on a.job_step_id = b.job_step_id
    where a.step_name = stepName;

     dbms_output.put_line(seqID ||'A' || jobStepID ||'B' || jobID);
    --3. Insert a record into the Job to Step crosstable
    INSERT INTO 
      CONTROL.CZ_JOB_X_JOB_STEP 
        (JOB_ID, 
        JOB_STEP_ID, 
        SEQ_ID)
    
    VALUES  (
      jobID,
      jobStepID,
      seqID);
    COMMIT;
    
    --4. Insert the Job Step Expected Results
    INSERT INTO 
      CZ_JOB_STEP_EXP_RESULT 
        (JOB_STEP_ID, 
        TABLE_NAME, 
        DML_TYPE, 
        EXP_RECORD_CNT) 
    VALUES(
      jobStepID,
      tableName,
      dmlType,
      expRecordCnt);
    COMMIT;

  end if; 
  
     dbms_output.put_line(seqID ||'A' || jobStepID ||'B' || jobID);
  
--insert a record into the job step run table
  INSERT INTO 
    AZ_JOB_STEP_RUN (
      JOB_RUN_ID, 
      JOB_STEP_ID, 
      START_DATE, 
      STATUS,
      SEQ_ID) 
  VALUES(
    jobRunID, 
    jobStepID, 
    insertDt, 
    'RUNNING',
    seqID);
   COMMIT;    
    
  --Get Job step Run ID
  SELECT max(JOB_STEP_RUN_ID) 
    INTO jobStepRunID
    FROM CONTROL.AZ_JOB_STEP_RUN a
    WHERE 
      a.job_run_id = jobRunID
      and a.job_step_id = jobStepID;
   
   --Return Job Run ID   
   RETURN jobStepRunID;   
END;

 
 
 
 
 
 
 
/
