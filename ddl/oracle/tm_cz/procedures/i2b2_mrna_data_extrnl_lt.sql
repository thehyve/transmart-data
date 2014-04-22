--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_MRNA_DATA_EXTRNL_LT
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_MRNA_DATA_EXTRNL_LT" 
(
  trial_id 		IN	VARCHAR2
 ,currentJobID	IN	NUMBER := null
)
AS

	--	JEA@20111028	New, loads MRNA data from external table to landing zone temporary table
  
  topNode		VARCHAR2(2000);
  topLevel		number(10,0);
  root_node		varchar2(2000);
  root_level	int;
  study_name	varchar2(2000);
  TrialID		varchar2(100);
  secureStudy	varchar2(200);
  etlDate		date;
  tPath			varchar2(2000);
  pCount		int;
  rtnCode		int;
  
    --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  

BEGIN
  
	TrialID := upper(trial_id);
	
	--Set Audit Parameters
	newJobFlag := 0; -- False (Default)
	jobID := currentJobID;

	SELECT sys_context('USERENV', 'CURRENT_SCHEMA') INTO databaseName FROM dual;
	procedureName := $$PLSQL_UNIT;
	
	select sysdate into etlDate from dual;

	--Audit JOB Initialization
	--If Job ID does not exist, then this is a single procedure run and we need to create it
	IF(jobID IS NULL or jobID < 1)
	THEN
		newJobFlag := 1; -- True
		cz_start_audit (procedureName, databaseName, jobID);
	END IF;
    	
	stepCt := 0;
	
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Start i2b2_clinical_data_extrnl_lt',0,stepCt,'Done');
	
	--	truncate landing zone work table
	
	execute immediate('truncate table tm_lz.lt_src_mrna_data');
	
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Truncate table lt_src_mrna_data',0,stepCt,'Done');
		
	--	Insert data to lt_src_mrna_data
	
	insert into lt_src_mrna_data
	(trial_name
	,probeset
	,expr_id
	,intensity_value
	)
	select TrialId
		  ,probeset
		  ,expr_id
		  ,intensity_value
	from mrna_data_extrnl;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Insert data into lt_src_mrna_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--	truncate landing zone work table for subject_sample mapping
	
	execute immediate('truncate table tm_lz.lt_src_mrna_subj_samp_map');
	
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Truncate table lt_src_mrna_subj_samp_map',0,stepCt,'Done');
		
	--	insert data to lt_src_mrna_subj_samp_map
	
	insert into lt_src_mrna_subj_samp_map
	(trial_name
	,site_id
	,subject_id
	,sample_cd
	,platform
	,tissue_type
	,attribute_1
	,attribute_2
	,category_cd
	)
	select Trial_id
		  ,site_id
		  ,subject_id
		  ,sample_cd
		  ,platform
		  ,tissue_type
		  ,attribute_1
		  ,attribute_2
		  ,category_cd
	from mrna_subj_sample_map_extrnl;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Insert data into lt_src_mrna_subj_samp_map',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'End i2b2_clinical_data_extrnl_lt',0,stepCt,'Done');
	
    ---Cleanup OVERALL JOB if this proc is being run standalone
	if newJobFlag = 1
	then
		cz_end_audit (jobID, 'SUCCESS');
	end if;

	rtnCode := 0;
  
	exception
	when others then
    --Handle errors.
		cz_error_handler (jobID, procedureName);
    --End Proc
		cz_end_audit (jobID, 'FAIL');
		rtnCode := 16;
	
end;
/
 
