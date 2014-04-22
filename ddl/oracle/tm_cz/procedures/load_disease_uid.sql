--
-- Type: PROCEDURE; Owner: TM_CZ; Name: LOAD_DISEASE_UID
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."LOAD_DISEASE_UID" 
AS
  --initiate variables for Job run and step ID's
  jobRunID CONTROL.AZ_JOB_RUN.JOB_RUN_ID%TYPE;
  jobStepID CONTROL.CZ_JOB_STEP.JOB_STEP_ID%TYPE;
BEGIN
  -------------------------------------------------------------------------------
  -- Loads Disease UID Data
  -- KCR@20090331 - First rev
  -------------------------------------------------------------------------------
  --Start ETL Control: Create a Job Run
  jobRunID := control.insert_etl_job_run('DIS:UID', 0, 'KRUSSELL', 'Loads UID data for Concept Disease', 'ADHOC', 'DISEASE');
  
  BEGIN
    --Delete existing data
		DELETE 
			FROM BIO_DATA_UID 
			WHERE BIO_DATA_TYPE = 'BIO_DISEASE';

    COMMIT;  

  END;

  BEGIN --LOAD BIO_DATA_ANALYSIS TABLE
    --Insert Job Run Info
    jobStepID := control.insert_etl_job_step(jobRunID, 'LoadDiseaseUID', 'Loading Disease UID Data', 'BIO_DATA_UID', 'INSERT', 0); 
  
  
    -- Add UIDs for diseases
    insert into bio_data_uid (
      bio_data_id,
      unique_id,
      bio_data_type
    )
    select
      bio_disease_id,
      bio_disease_uid(MESH_CODE),
      'BIO_DISEASE'
    from
      bio_disease;
    --END step: Update Step Run with TIME/STATUS
    control.UPDATE_ETL_JOB_STEP_PASS(jobStepID, 'BIO_DATA_UID',SQL%ROWCOUNT);
    COMMIT;
  END; --LOAD BIO_DATA_ANALYSIS TABLE
  
  --END ETL CONTROL: Update Job Run with TIME/STATUS
  control.UPDATE_ETL_JOB_RUN_PASS(jobRunID);
EXCEPTION
  WHEN OTHERS THEN
    control.UPDATE_ETL_JOB_STEP_FAIL(jobStepID, SQLCODE, SQLERRM(), DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    control.UPDATE_ETL_JOB_RUN_FAIL(jobRunID);
    --RAISE;
END;
  

 
 

 

 
 
 
 
/
