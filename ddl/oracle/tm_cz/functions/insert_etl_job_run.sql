--
-- Type: FUNCTION; Owner: TM_CZ; Name: INSERT_ETL_JOB_RUN
--
  CREATE OR REPLACE FUNCTION "TM_CZ"."INSERT_ETL_JOB_RUN" (
  jobName IN CONTROL.CZ_JOB.JOB_NAME%TYPE, --Name from SYSTEM_JOB Table
  dataFileID IN CONTROL.CZ_DATA_FILE.DATA_FILE_ID% TYPE,
  userName IN CONTROL.CZ_PERSON.USER_NAME%TYPE,
  jobDesc IN CONTROL.CZ_JOB.JOB_DESC%TYPE,
  runFreq IN CONTROL.CZ_JOB.RUN_FREQ%TYPE,
  conceptLoadType IN CONTROL.CZ_JOB.CONCEPT_LOAD_TYPE%TYPE
)

RETURN CONTROL.AZ_JOB_RUN.JOB_RUN_ID%TYPE

IS
insertDt CONTROL.AZ_JOB_RUN.START_DATE%TYPE;
jobID CONTROL.AZ_JOB_RUN.JOB_ID%TYPE;
personID CONTROL.CZ_PERSON.PERSON_ID%TYPE;
jobRunID CONTROL.AZ_JOB_RUN.JOB_RUN_ID%TYPE; --return value

BEGIN
  -------------------------------------------------------------------------------
   -- iF a Job does, not exist, it will create it.
  -- Adds a record to the Job Run table
   -- OUTER JOIN TO  SYSPERSON USED SO THAT ROW IS INSERTED NO MATTER WHAT.
   -- Returns the job run id for adding steps.
   -- KCR@20090327 - First rev. 
   -------------------------------------------------------------------------------
  --get insert date/time
  insertDt := SYSDATE;
  jobid := '';
  personid := '';
  


  BEGIN
    --GET JOB ID
    SELECT a.JOB_ID
      INTO jobID
    FROM CONTROL.CZ_JOB a
      WHERE UPPER(a.JOB_NAME) = UPPER(jobName);

  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN jobid := 0;
  
  END;    

  BEGIN
    --GET PERSON ID
    SELECT a.PERSON_ID
      INTO personID
    FROM CONTROL.CZ_PERSON a
      WHERE UPPER(a.USER_NAME) = UPPER(userName);
    
  EXCEPTION
  WHEN NO_DATA_FOUND
  THEN personid := '';
  
  END;    
    
  --if the job doesn't exist, create a new job
  IF jobID = 0
  THEN
    Insert into 
      CONTROL.CZ_JOB
      (JOB_NAME, 
      JOB_DESC,
      RUN_FREQ,
      CREATE_DATE,
      CREATED_BY,
      CONCEPT_LOAD_TYPE)
    VALUES
      (jobName,
      jobDesc,
      runFreq,
      insertDt,
      personID,
      conceptLoadType
      );
    COMMIT;

    --GET JOB ID
    SELECT a.JOB_ID
      INTO jobID
    FROM CONTROL.CZ_JOB a
      WHERE UPPER(a.JOB_NAME) = UPPER(jobName);

    --IF PERSON EXISTS, INSERT IT
    IF personID !=''
    THEN
      UPDATE CONTROL.CZ_JOB  
        SET CREATED_BY = personID;
 
    END IF;
 END IF;

  --Insert Record
  INSERT INTO 
   CONTROL.AZ_JOB_RUN 
    (JOB_ID, START_DATE, STATUS, DW_VERSION_ID, PERSON_ID) 
  SELECT 
   jobID, 
   insertDt,
   'RUNNING',
   a.DW_VERSION_ID,
   personID
  FROM  CONTROL.CZ_DW_VERSION a
  WHERE 
   UPPER(a.IS_CURRENT) = 'Y';
  COMMIT;
  
  --Get Job Run ID
  SELECT a.JOB_RUN_ID 
    INTO jobRunID
    FROM CONTROL.AZ_JOB_RUN a
    WHERE 
      a.JOB_ID = jobID
      AND a.START_DATE = insertDt;
   
  --insert JOB RUN TO DATA FILE INFO
  INSERT INTO 
    AZ_JOB_RUN_X_DATA_FILE 
      (JOB_RUN_ID, 
      DATA_FILE_ID) 
  SELECT 
    jobRunID,
    a.data_file_id
  FROM 
    CONTROL.cz_data_file a
  WHERE a.data_file_id = dataFileID;

   --Return Job Run ID   
   RETURN jobRunID;   

END;
  

 
 
 
 
 
 
 
/
 
