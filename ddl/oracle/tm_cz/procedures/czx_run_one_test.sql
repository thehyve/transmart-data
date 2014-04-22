--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_RUN_ONE_TEST
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."CZX_RUN_ONE_TEST" 
(
  v_test_category_id	number
 ,v_test_id				number
 ,currentRunID 			NUMBER := null
)
AS
	--	Procedure to run one test in CZ_TEST
	
	--	JEA@20111019	New

	--	Define the abstract result set record
	
	TYPE r_type IS RECORD (
		rtn_text          VARCHAR2 (2000),
		rtn_nbr           integer
	);
	
	--	Define the abstract result set table
	TYPE tr_type IS TABLE OF r_type;

	--	Define the result set
	
	rtn_array tr_type;

	--	Variables
	
	testTable		varchar2(2000);
	testSQL   		varchar2(2000);
	tableType		varchar2(2000);
	extrnlLocation	varchar2(2000);
	runID			number(18,0);
	runDate			date;
	
	BEGIN	
	
		--	Initialize runDate
		
		select sysdate into runDate from dual;
		
		--	Initialize runId if not passed as parameter
		
		runId := currentRunId;
		
		if (runId is null or runId < 0) then
			select seq_cz.nextval into runId from dual;
		end if;
		
		--	Get information on test from CZ_TEST
		
		select test_table
			  ,test_sql
			  ,nvl(table_type,'REGULAR') as table_type
		into testTable
			,testSQL
			,tableType
		from cz_test
		where test_id = v_test_id;
		
		if upper(tableType) = 'EXTERNAL' then
			select location into extrnlLocation 
			from all_external_locations
			where table_name = testTable;
		else
			extrnlLocation := '';
		end if;

	--	testSQL := 'Select  ' || '''' || 'x' || '''' || ' as rtn_value, count(distinct site_id || subject_id) from clinical_data_extrnl';

		execute immediate(testSQL) BULK COLLECT INTO rtn_array;
      
		for i in rtn_array.first .. rtn_array.last
		loop
		--	dbms_output.put_line(rtn_array(i).rtn_text || ' ' || to_char(rtn_array(i).rtn_nbr));
			
			if (rtn_array(i).rtn_text is not null) then
				insert into cz_test_result
				(test_id, test_result_text, test_result_nbr, test_run_id, external_location, run_date)
				select v_test_id
					  ,nullif(upper(rtn_array(i).rtn_text),'X')
					  ,rtn_array(i).rtn_nbr
					  ,runId
					  ,extrnlLocation
					  ,runDate
				from dual;
			end if;
			
		end loop;
	
END;
/
 
