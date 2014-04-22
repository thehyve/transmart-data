--
-- Type: PROCEDURE; Owner: TM_CZ; Name: EXEC_TEST_RUN
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."EXEC_TEST_RUN" (
  v_test_category_id integer,
  v_param1 VARCHAR2,
  v_test_name VARCHAR2 --optional test name for searching
)
AS 
 --BASIC TEST HARNESS FOR SQL TESTS
 --KCR: 2009-08-24
 --TAKES IN 3 CATEGORY PARAMETERS. These are used to filter the tests to run
 --Uses 1 "PARAM1" value to pass to the individual tests to use in the test.
 
 
  --initiate variables for Job run and step ID's
  testRunID  CONTROL.AZ_TEST_RUN.TEST_RUN_ID%TYPE;
  testStepRunID CONTROL.AZ_TEST_STEP_RUN.TEST_STEP_RUN_ID%TYPE;

  startDate DATE;
  testStatus VARCHAR2(100);
  err_code VARCHAR2(4000);
  err_msg VARCHAR2(4000);
  testName VARCHAR2(200);
  testNameExists INTEGER;

  --Create a cursor of tests
  CURSOR testList is
  select test_id
    from CZ_TEST
  WHERE
    test_category_id = v_test_category_id;
    
BEGIN
  startDate := sysdate;

  testName := v_test_name;

  --validate test name
  IF testName = '' then
  select to_char(max(dw_version_id)) || '-' || v_test_category_id  || '-' || v_param1 || '-' || to_char(sysdate,'YYYYMMDD-HH24:MI:SS')
    into testName
    from cz_dw_version;
  ELSE 
    --add date/time to make distinct
    testName := testName || '-' || to_char(startDate,'YYYYMMDD-HH24:MI:SS');
  end if;

  --CREATE A NEW TEST RUN
  INSERT
  INTO AZ_TEST_RUN
  (
    TEST_RUN_NAME,
    DW_VERSION_ID,
    START_DATE,
    STATUS,
    TEST_CATEGORY_ID,
    PARAM1
  )
  select 
    testName,
    max(dw_version_id), 
    startDate, 
    'RUNNING',
    v_test_category_id,
    v_param1
      FROM cz_dw_version;
  commit;    

    --Get the new Test Run ID
    select      
      max(test_run_id) into testRunID
    from az_test_run
      WHERE start_date = startDate;
  

  --ITERATE THROUGH TESTS AND EXECUTE THEM
  FOR r_testList in testList Loop
    exec_test(testRunID, r_testList.test_id, v_param1);
  END LOOP;  

    --determine minimum testRunStatus' for this Test.
    --They will appear as ERROR, FAIL, PASS, WARNING
    select min(status)
    into testStatus
    from az_test_step_run
      where test_run_id = testRunID;

    --update run info      
    update az_test_run
      set end_date = sysdate,
      status = testStatus
    where 
      test_run_id = testRunID;
    commit;
  
  EXCEPTION
  WHEN OTHERS THEN

    err_code := SQLCODE;
    err_msg := substr(SQLERRM, 1, 4000);

    --Update Actual Results    
    UPDATE AZ_TEST_RUN
    SET END_DATE = SYSDATE,
    STATUS = 'RUNERROR',
    RETURN_CODE = err_code, 
    RETURN_MESSAGE = err_msg
    where
      test_run_id = testRunID;
    
    commit;
END;

 
 
 
 
/
 
