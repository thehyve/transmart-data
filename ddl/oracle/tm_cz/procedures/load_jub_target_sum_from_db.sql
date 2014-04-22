--
-- Type: PROCEDURE; Owner: TM_CZ; Name: LOAD_JUB_TARGET_SUM_FROM_DB
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."LOAD_JUB_TARGET_SUM_FROM_DB" 
AS
  --initiate variables for Job run and step ID's
  --jobRunID CONTROL.SYSTEM_JOB_RUN.JOB_RUN_ID%TYPE;
  --jobStepID CONTROL.SYSTEM_JOB_STEP.JOB_STEP_ID%TYPE;

BEGIN
  -------------------------------------------------------------------------------
  -- Loads Jubilant Summary Data from the Jubilant DB received on 3/2009
  -- KCR@20090324 - First rev.
  -------------------------------------------------------------------------------
  --Start ETL Control: Create a Job Run
  --jobRunID := control.insert_system_job_run('LoadCCJubilantTargetSummaryData','Load Jubilant Target Summary data from CentClinRD');

  BEGIN
    
    --Delete
--    DELETE 
--      FROM BIO_CURATED_DATA
--      WHERE BIO_CURATION_DATASET_ID IN
--        (SELECT BIO_CURATION_DATASET_ID
--          FROM BIO_CURATION_DATASET
--            BIO_CURATION_NAME = 'Jubilant DB from March 2009');

    DELETE 
      FROM BIO_DATA_UID
      WHERE BIO_DATA_TYPE = 'BIO_JUB_ONC_SUM_DATA'
        AND UNIQUE_ID LIKE '5-%';
    
    
    DELETE 
      FROM BIO_JUB_ONC_SUM_DATA
      WHERE UNIQUE_ID LIKE '5-%';    
    
    COMMIT;
  END;

  BEGIN
  	--Insert Job Run Info
    --jobStepID := control.insert_system_job_step(jobRunID, 'Insert to BIO_JUB_ONCOL_DATA', 'Inserting Jubilant Target Summary Data from CentClinRD', 915); 

    --Loading Target table
    INSERT INTO 
      BIO_JUB_ONC_SUM_DATA 
        (DATATYPE, 
        ALTERATION_TYPE, 
        TOTAL_FREQUENCY, 
        TOTAL_AFFECTED_CASES, 
        TARGET_NAME, 
        VARRIANT_NAME, 
        DISEASE_SITE_NAME, 
        TOTAL_NUMERATOR, 
        TOTAL_DENOMINATOR,
        UNIQUE_ID) 
    SELECT 
      DATA_TYPE, 
      ALTERATION_TYPE, 
      TOTAL_FREQUENCY, 
      TOTAL_AFFECTED_CASES, 
      TARGET_NAME, 
      VARRIANT_NAME, 
      DISEASE_SITE_NAME, 
      TOTAL_NUMERATOR, 
      TOTAL_DENOMINATOR,
      '5-' || rownum
    FROM jbl_jwb.TEMP_DISEASE_SUMMARY;

    --control.UPDATE_SYSTEM_JOB_STEP_PASS(jobStepID, SQL%ROWCOUNT);
    COMMIT;        

  END; 

  BEGIN
  	--Insert Job Run Info
    --jobStepID := control.insert_system_job_step(jobRunID, 'Insert to BIO_DATA_UID', 'Inserting UID data for Jubilant Target Summary Data', 915); 

    --INSERT THE UID FOR THIS TYPE.
    INSERT INTO 
      BIO_DATA_UID 
        (BIO_DATA_ID, 
        UNIQUE_ID, 
        BIO_DATA_TYPE) 
    SELECT
      BIO_DATA_ID,
      unique_id,
      'BIO_JUB_ONC_SUM_DATA'
    FROM BIO_JUB_ONC_SUM_DATA
    WHERE
      UNIQUE_ID LIKE '5-%';

    --control.UPDATE_SYSTEM_JOB_STEP_PASS(jobStepID, SQL%ROWCOUNT);
    COMMIT;        

  END; 

  BEGIN
  	--Insert Job Run Info
    --jobStepID := control.insert_system_job_step(jobRunID, 'Insert to BIO_CURATED_DATA', 'Inserting Jubilant Target Summary Data to the Curated Data table.', 915); 

    --BIO_CURATED DATA
    INSERT INTO 
      BIO_CURATED_DATA
        (BIO_DATA_ID, 
        BIO_CURATION_DATASET_ID,
        DATA_TYPE) 
      SELECT 
        a.bio_data_id,
        b.BIO_CURATION_DATASET_ID,
        'JUBILANT_ONCOLOGY_SUMMARY'
      FROM BIO_JUB_ONC_SUM_DATA a, 
        BIO_CURATION_DATASET b
      where 
        BIO_CURATION_NAME = 'Jubilant DB from March 2009'
        AND a.UNIQUE_ID LIKE '5-%';
        
    --control.UPDATE_SYSTEM_JOB_STEP_PASS(jobStepID, SQL%ROWCOUT);
    COMMIT;        

  END; 
  
  --END ETL CONTROL: Update Job Run with TIME/STATUS
--  control.UPDATE_SYSTEM_JOB_RUN_PASS(jobRunID);
--  EXCEPTION
--  WHEN OTHERS THEN
--    control.UPDATE_SYSTEM_JOB_STEP_FAIL(jobStepID, SQLCODE, SQLERRM(), DBMS_UTILITY.FORMAT_ERROR_STACK, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
--    control.UPDATE_SYSTEM_JOB_RUN_FAIL(jobRunID);
    --RAISE;
END;
 
 
 
 
 
 
 
/
 
