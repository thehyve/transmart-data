--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_RUN_TEST_CATEGORY
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."CZX_RUN_TEST_CATEGORY" 
(
  V_TEST_CATEGORY_ID	number
  ,study_id varchar2
)
AS
	--	Procedure to run one test in CZ_TEST	
	--	JEA@20111019	New
	--	Define the abstract result set record
	
	runID			number(18,0);
	RUNDATE			date;
  V_NAMEID    number(18,0);
  currentRunID 			NUMBER;  
	

  CURSOR C_TEST IS 
  select distinct 
         TEST_ID
   from  CZ_TEST a
   where TEST_CATEGORY_ID = V_TEST_CATEGORY_ID;
   
BEGIN   
     select sysdate into runDate from dual;
		
		--	Initialize runId if not passed as parameter
		
		runId := currentRunId;
		
		if (runId is null or runId < 0) then
			select seq_cz.nextval into runId from dual;
		end if;
    
    
    OPEN C_TEST;
    FETCH C_TEST INTO V_NameID;
    
    WHILE C_TEST%FOUND
			LOOP
        begin
        CZX_RUN_ONE_TEST(V_TEST_CATEGORY_ID,V_NameID,Runid);
        END;
       
       --DBMS_OUTPUT.PUT_LINE(;
       FETCH C_TEST INTO V_NAMEID;
       END LOOP;
       CLOSE C_TEST;
   
  
		
END;
/
 
