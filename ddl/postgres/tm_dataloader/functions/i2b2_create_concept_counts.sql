--
-- Name: i2b2_create_concept_counts(character varying, numeric, character varying); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION i2b2_create_concept_counts(path character varying, currentjobid numeric DEFAULT '-1'::integer, buildtree character varying DEFAULT 'Y'::character varying) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
/*************************************************************************
* Copyright 2008-2012 Janssen Research & Development, LLC.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
******************************************************************/
Declare
 
	--Audit variables
	newJobFlag		integer;
	databaseName 	VARCHAR(100);
	procedureName 	VARCHAR(100);
	jobID 			numeric(18,0);
	stepCt 			numeric(18,0);
	rowCt			numeric(18,0);
	errorNumber		character varying;
	errorMessage	character varying;
	rtnCd			numeric;
  
BEGIN
     IF(buildTree = 'Y')
	THEN
		SELECT I2B2_CREATE_FULL_TREE(path, currentJobID) INTO rtnCd;
	END IF;


	--Set Audit Parameters
	newJobFlag := 0; -- False (Default)
	jobID := currentJobID;

	databaseName := current_schema();
	procedureName := 'I2B2_CREATE_CONCEPT_COUNTS';

	--Audit JOB Initialization
	--If Job ID does not exist, then this is a single procedure run and we need to create it
	IF(jobID IS NULL or jobID < 1)
	THEN
		newJobFlag := 1; -- True
		select cz_start_audit (procedureName, databaseName) into jobID;
	END IF;


	
	/*SELECT count(*) INTO rowCt FROM
(
	select fa.c_fullname
		  ,ltrim(SUBSTR(fa.c_fullname, 1,instr(fa.c_fullname, '\',-1,2)))
		  ,count(distinct tpm.patient_num)
	from i2b2metadata.i2b2 fa
	    ,i2b2metadata.i2b2 la
		,i2b2demodata.observation_fact tpm
		,i2b2demodata.patient_dimension p
		,I2B2_LOAD_TREE_FULL tree
	where fa.c_fullname like '\Private Studies\Jace_Study_C0168T37' || '%' escape '`'
	  and substr(fa.c_visualattributes,2,1) != 'H'
	 -- and la.c_fullname like fa.c_fullname || '%' escape '`'
	  and fa.RECORD_ID = tree.IDROOT 
	  and la.RECORD_ID = tree.IDCHILD
	  and la.c_visualattributes like 'L%'
	  and tpm.patient_num = p.patient_num
	  and la.c_basecode = tpm.concept_cd   -- outer join in oracle ???
	group by fa.c_fullname
			,ltrim(SUBSTR(fa.c_fullname, 1,instr(fa.c_fullname, '\',-1,2)))

) t;

	select cz_write_audit(jobId,databaseName,procedureName,'Insert TEST counts for trial into I2B2DEMODATA concept_counts',rowCt,stepCt,'Done') into rtnCd;*/
	
	--SET ANY NODE WITH MISSING OR ZERO COUNTS TO HIDDEN

	begin
	update i2b2metadata.i2b2
	set c_visualattributes = substr(c_visualattributes,1,1) || 'H' || substr(c_visualattributes,3,1)
	where c_fullname like path || '%' escape '`'
	  and (not exists
			 (select 1 from concept_counts nc
				  where c_fullname = nc.concept_path)
				 or
			 exists
				 (select 1 from concept_counts zc
				  where c_fullname = zc.concept_path
					and zc.patient_count = 0)
			  )
		and c_name != 'SECURITY';
	get diagnostics rowCt := ROW_COUNT;	
	exception
	when others then
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		--Handle errors.
		select cz_error_handler (jobID, procedureName, errorNumber, errorMessage) into rtnCd;
		--End Proc
		select cz_end_audit (jobID, 'FAIL') into rtnCd;
		return -16;
	end;
	stepCt := stepCt + 1;
	select cz_write_audit(jobId,databaseName,procedureName,'Nodes hidden with missing/zero counts for trial into I2B2DEMODATA concept_counts',rowCt,stepCt,'Done') into rtnCd;
		
	---Cleanup OVERALL JOB if this proc is being run standalone
	IF newJobFlag = 1
	THEN
		select cz_end_audit (jobID, 'SUCCESS') into rtnCd;
	END IF;

	return 1;

END;

$$;
