--
-- Type: PROCEDURE; Owner: TM_CZ; Name: EXEC_TEST
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."EXEC_TEST" (
  v_test_run_id NUMBER, -- From AZ_TEST_RUN
  v_test_id NUMBER,     -- From CZ_TEST
  v_param1 VARCHAR2      -- used if parameter is passed.
)
AS 

  --initiate variables for Job run and step ID's
  testRunID  CONTROL.AZ_TEST_RUN.TEST_RUN_ID%TYPE;
  testStepRunID CONTROL.AZ_TEST_STEP_RUN.TEST_STEP_RUN_ID%TYPE;

  --Other variables
  sqlTestCode VARCHAR2(4000);
  startDate DATE;
  returnCount NUMBER;
  minValue NUMBER;
  maxValue NUMBER;
  err_code VARCHAR2(4000);
  err_msg VARCHAR2(4000);
  testStatus VARCHAR2(100);
  testType VARCHAR2(100);
  testSeverity varchar2(20);
  dwVersionID NUMBER;
  comparisonExists NUMBER;

BEGIN
  --Set start Date (Need to set so the correct record can be retrieved)
  startDate := sysdate;
  
  --Check for test run id. If null, create one.
  if v_test_run_id is null or v_test_run_id = 0 then 
    INSERT
    INTO AZ_TEST_RUN
    (
      DW_VERSION_ID,
      START_DATE,
      STATUS
    )
    select max(dw_version_id), startDate, 'RUNNING'
      FROM cz_dw_version;
    commit;    

    --Get the new Test Run ID
    select      
      max(test_run_id) into testRunID
    from az_test_run
      WHERE start_date = startDate;
  else
    testRunID := v_test_run_id;
  end if;
  
  --Create a new test step record
  INSERT INTO 
    AZ_TEST_STEP_RUN (
      TEST_RUN_ID, 
      START_DATE, 
      TEST_ID, 
      STATUS,
      PARAM1) 
  VALUES(
    testRunID, 
    sysdate, 
    v_test_id, 
    'RUNNING',
    v_param1);
  COMMIT;    
  
  --Get the new Test Step ID
  select      
    max(test_step_run_id) into testStepRunID
    from az_test_step_run
      WHERE start_date = startDate;
      
 BEGIN
    --Get SQL for test
    SELECT 
      TEST_SQL, TEST_TYPE, TEST_MIN_VALUE, TEST_MAX_VALUE, TEST_SEVERITY_CD
    INTO 
      sqlTestCode, testType, minValue, maxValue, testSeverity
    FROM CZ_TEST
    WHERE TEST_ID = v_test_id;

  --Replace 'PARAM1' with passed variable
  sqlTestCode := replace(sqlTestCode,'PARAM1', v_Param1);

    --Execute Test
    EXECUTE immediate sqlTestCode into returnCount;
  
    INSERT INTO 
        AZ_TEST_STEP_ACT_RESULT 
        (TEST_STEP_RUN_ID, 
        ACT_RECORD_CNT) 
    SELECT 
      testStepRunID,
      returnCount
    FROM
      CONTROL.AZ_TEST_STEP_RUN a
    WHERE 
      a.TEST_STEP_RUN_ID = testStepRunId;
    commit;

    --ADDING LOGIC FOR COMPARISON TESTS
    IF testType = 'COMPARISON' THEN
      --get current dw version
      select max(dw_version_id) into dwVersionID 
        from cz_dw_version;

      --Add or update current data to comparison table
      select count(*) 
        into comparisonExists
        from az_test_comparison_info 
      where param1 = v_param1 
      and test_id = v_test_id;
      
      
      if (comparisonExists) = 1 then
        update az_test_comparison_info
          set curr_act_record_cnt = returncount,
          curr_dw_version_id = dwversionid,
          curr_test_step_run_id = teststeprunid,
          curr_run_date = sysdate
        where param1 = v_param1
        and test_id = v_test_id;
        commit;        
      end if;
      
      if (comparisonExists) = 0 then
        INSERT INTO CONTROL.AZ_TEST_COMPARISON_INFO
        (TEST_ID,
        PARAM1,
        CURR_DW_VERSION_ID,
        CURR_TEST_STEP_RUN_ID,
        CURR_ACT_RECORD_CNT,
        curr_run_date
        )
        VALUES
        (
          v_test_id,
          v_param1,
          dwVersionID,
          teststeprunid,
          returncount,
          sysdate
        );
        commit;
      end if;
        
        
    --GET THE RESULTS FOR THIS TEST FROM THE PREVIOUS BUILD
    -- put it in both min and max for comparison
      SELECT PREV_ACT_RECORD_CNT, PREV_ACT_RECORD_CNT 
      into minValue, maxValue
        from az_test_comparison_info
      where
        v_test_id = test_id -- get correct test
      and v_param1 = param1; -- correct parameter
    
    end if;
    

    --Determine Pass/Fail  
    if returnCount BETWEEN minValue AND maxValue then
      testStatus := 'PASS';
    elsif testSeverity =  'INFO' then  --Informational Test
      testStatus := 'WARNING';
    else --Required test
      testStatus := 'FAIL';
    end if;

    --update step info      
    update az_test_Step_run
      set end_date = sysdate,
      status = testStatus
    where 
      test_step_run_id = testStepRunID;
    commit;
  END;
  
  commit;
  
  EXCEPTION
  WHEN OTHERS THEN
    
    err_code := SQLCODE;
    err_msg := substr(SQLERRM, 1, 4000);

    --Update Actual Results    
    INSERT INTO AZ_TEST_STEP_ACT_RESULT
    (
      TEST_STEP_RUN_ID,
      RETURN_CODE,
      RETURN_MESSAGE,
      RETURN_ERROR_STACK,
      RETURN_ERROR_BACK_TRACE
    )
    VALUES
    (
      testStepRunID,
      err_code, 
      err_msg, 
      DBMS_UTILITY.FORMAT_ERROR_STACK, 
      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
    
    update az_test_Step_run
      set end_date = sysdate,
      status = 'ERROR'
    where 
      test_step_run_id = testStepRunID;
    commit;
END;

 
 
 
 
/
