--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_APPLY_CURATION_RULES
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_APPLY_CURATION_RULES" 
(
  trial_id 		IN	VARCHAR2
 ,currentJobID	IN	NUMBER := null
 ,rtnCode		OUT	int
)
AS
 
  --APPLY CURATION RULES (HARD-CODED and from NODE_CURATION table) TO THE TIME POINT MEASUREMENT TABLE
  --KCR: 8.14.2009 (original in i2b2_LOAD_TPM)
  --JEA@20090831	Moved this code from i2b2_LOAD_TPM to i2b2_APPLY_CURATION_RULES
  --JEA@20090911  Changed logic to determine if data_type should be N
  --JEA@20090912  Added data_type to addNodesAll cursor, if data_type = 'T', don't add path for Biomarkers/Clinical, it 
  --              will be added in text node processing
  --JEA@20090917  Added additional curation for Demographic nodes
  --JEA@20090923  Changed to use tmp table and build leaf nodes for both text and numeric data type in one pass,
  --              combined reset of data_type and suppress_flag, combined trim/replace of '|' 
  --JEA@20090924  Added Subjects\Demographics\Screening Failure to list of category_cds that have their category_paths nulled out
  --JEA@20090925  Added nvl wrapper to data_label when inserting into tmp_num_data_types, changed select that determines if values
  --              are numeric to check if sum of is_number of all data_values is 0, previous code only checked min/max and that
  --              didn't trap non-numerics, added visit_name, period, sample_type to tmp_num_data_types
  --JEA@20090929  Fixed node_name for text data types
  --JEA@20091019  Add analyze table for tm_wz.tmp_trial_nodes
  --JEA@20091109  Add logic to node_curation updates to pick the record for the study_id when both global and study-specific
  --			  records exist for a single node_type/node_name
  --JEA@20091117  Added auditing
  --JEA@20091201  Remove test for display_in_ui value for all node_curation updates, changed node_curation suppress logic to
  --			  decode display_in_ui to suppress_flag
  --JEA@20100412  Changed Demographic node curation from in to like, delete all records where data_value is null
  --JEA@20100412  (JNJ-1916) Add SAMPLE_TYPE node curation, remove sample_type if already in category_path, additional trimming
  --JEA@20100505  Added return code
  --JEA@20100611  Added more curation for single visit_name, single sample_type
  --JEA@20100614  Exclude Across Trials node when determining root_node name
  --JEA@20100614  Set data_label to null for Samples and Timepoints
  --JEA@20100617  Keep data_labels for samples_and_timepoints, use node_curation to remove if necessary 
  --			  ex:  Sample Type (SMPTYPE) as data_label should be removed, Whole Blood should not
  --JEA@21010813  Change delete of single sample_type to only delete where category_cd not like 'SAMPLES_AND_TIMEPOINTS'
  
  root_node VARCHAR2(100);
  TrialID varchar2(100);
  
    --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  
  ----------------------------------------------
  --Cursor and variables for determining data type
  ----------------------------------------------
  CURSOR cVariables is
  select distinct category_cd, data_label
    FROM time_point_measurement;
      
  MAXVAL NUMBER;
  MINVAL NUMBER;    
 
  ----------------------------------------------
  --Cursor and variables for loading ALL I2B2 Nodes:
  --3 types of Paths for I2B2
  --#1: default Path: ROOT_NODE\STUDY_ID\CATEGORY_PATH\VISIT_NAME\PERIOD\SAMPLE_TYPE\DATA_LABEL
  --#2: Visit Last Path: ROOT_NODE\STUDY_ID\CATEGORY_PATH\SAMPLE_TYPE\PERIOD\DATA_LABEL\VISIT_NAME
  --for any Biomarker Node or Clinical Data\Other Measurements
  --#3: No Visit Path: ROOT_NODE\STUDY_ID\CATEGORY_PATH\SAMPLE_TYPE\DATA_LABEL
  --For any node with the Week in the Category_path(Clinical Data\Primary Endpoint\Acr20 Response At Week 16)
  ----------------------------------------------
  CURSOR addNodes is
  select DISTINCT 
         leaf_node,
    		 node_name
  from  tm_wz.tmp_trial_nodes a 
  ;

BEGIN
  
  TrialID := upper(trial_id);

  --Set Audit Parameters
  newJobFlag := 0; -- False (Default)
  jobID := currentJobID;

  SELECT sys_context('USERENV', 'CURRENT_SCHEMA') INTO databaseName FROM dual;
  procedureName := $$PLSQL_UNIT;

  --Audit JOB Initialization
  --If Job ID does not exist, then this is a single procedure run and we need to create it
  IF(jobID IS NULL or jobID < 1)
  THEN
    newJobFlag := 1; -- True
    cz_start_audit (procedureName, databaseName, jobID);
  END IF;
    	
  stepCt := 0;
  
  -- determine root node
  select parse_nth_value(c_fullname, 2, '\') into root_node
  from i2b2
  where c_name = TrialID
    and c_fullname not like '%Across Trials%';

  ----------------------------------------------------------------
  --PERFORM CURATION RULES.
  ----------------------------------------------------------------
  --Reset Suppress_flag in case this is a rerun

  --	reset flags 
  update time_point_measurement
  set suppress_flag = 'N'
     ,data_type = 'T';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Reset suppress_flag, data_type in WZ time_point_measurement',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;
  
  --	Delete rows where data_value is null
  
  delete from time_point_measurement
  where data_value is null;
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete null data_values in WZ time_point_measurement',SQL%ROWCOUNT,stepCt,'Done');
	
  --Remove Invalid pipes in the data values.
  --RULE: If Pipe is last or first, delete it
  --If it is in the middle replace with a dash

  update time_point_measurement
  set data_value = replace(trim('|' from data_value), '|', '-')
  where data_value like '%|%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove pipes in data_value',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;  
  
  --Remove invalid Parens in the data
  --They have appeared as empty pairs or only single ones.
  
  update time_point_measurement
  set data_value = replace(data_value,'(', '')
  where 
  data_value like '%()%'
  OR data_value like '%( )%'
  OR (data_value like '%(%' and data_value NOT like '%)%');
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove empty parentheses 1',SQL%ROWCOUNT,stepCt,'Done');
	
  update time_point_measurement
  set data_value = replace(data_value,')', '')
  where 
  data_value like '%()%'
  OR data_value like '%( )%'
  OR (data_value like '%)%' and data_value NOT like '%(%');
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove empty parentheses 2',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;

  --Parse unit info from data value field 
  --Unit Code is specified by a pipe prior to it in the field.
  --Insert units into the unit_cd field.
  update time_point_measurement
    set unit_cd = parse_nth_value(data_label, 2,'|')
    where parse_nth_value(data_label, 2,'|') is not null;
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Parse unit info from data_value',SQL%ROWCOUNT,stepCt,'Done');
	

  --Replace the Pipes with Commas in the data_label column
  update time_point_measurement
    set data_label = replace (data_label, '|', ',')
    where data_label like '%|%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Replace pipes with comma in data_label',SQL%ROWCOUNT,stepCt,'Done');
	
  Commit;
  
  

  --Update the following categories to remove the Category Path value 
  --If not, the tree node will display the name twice twice
  update category a
    set category_path = ''
      where upper(category_cd) in ('SCHEDULED_VISITS', 'TREATMENT_GROUPS','STUDY_GROUPS');
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove category_path value for Scheduled Visits/Treatment Groups',SQL%ROWCOUNT,stepCt,'Done');
	
  Commit;
  

  --The following categories need to have path adjusted for duplication of Node.
  update category
    set category_path = 'Subjects\Demographics'
	where category_path like 'Subjects\Demographics\Age%'
	   or category_path like 'Subjects\Demographics\Race%'
	   or category_path like 'Subjects\Demographics\Sex%'
	   or category_path like 'Subjects\Demographics\Height%'
	   or category_path like 'Subjects\Demographics\Weight%'
	   or upper(category_path) like 'SUBJECTS\DEMOGRAPHICS\BMI%'
     or upper(category_path) like 'SUBJECTS\DEMOGRAPHICS\BODY MASS%'
	   or category_path = 'Subjects\Demographics\Screening Failure'
/*
      where category_path IN (
        'Subjects\Demographics\Age',
        'Subjects\Demographics\Race',
        'Subjects\Demographics\Sex',
        'Subjects\Demographics\Weight In Kg',
        'Subjects\Demographics\Height In Cm',
		    'Subjects\Demographics\Height In Centimeters',
		    'Subjects\Demographics\Weight In Kilograms',
		    'Subjects\Demographics\Bmi',
        'Subjects\Demographics\Screening Failure')
*/
		;  
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Adjust Subjects\Demographics to remove duplicate node',SQL%ROWCOUNT,stepCt,'Done');
			
  COMMIT;  

	--	set visit_name to null when there's only a single visit_name for the catgory
	
	update time_point_measurement tpm
	set visit_name=null
	where (tpm.category_cd) in
		  (select x.category_cd
		   from time_point_measurement x
		   group by x.category_cd
		   having count(distinct upper(x.visit_name)) = 1);

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set single visit_name to null',SQL%ROWCOUNT,stepCt,'Done');
		
	commit;
	
	--	set sample_type to null when there's only a single sample_type for the category except Samples and Timepoints
	
	update time_point_measurement tpm
	set sample_type=null
	where tpm.category_cd in
		 (select x.category_cd
		  from time_point_measurement x
		  group by x.category_cd
		  having count(distinct upper(x.sample_type)) = 1)
	  and upper(tpm.category_cd) not like 'SAMPLES_AND_TIMEPOINTS%';

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set single sample_type to null',SQL%ROWCOUNT,stepCt,'Done');
		
	commit;
	
	--	set data_label to null when it duplicates the last part of the category_path
	
	update time_point_measurement tpm
	set data_label = null
	where (tpm.category_cd, tpm.data_label) in
		  (select distinct t.category_cd
				 ,t.data_label
		   from time_point_measurement t
			   ,category c
		   where t.category_cd = c.category_cd 
			 and upper(substr(c.category_path,instr(c.category_path,'\',-1)+1,length(c.category_path)-instr(c.category_path,'\',-1))) 
			     = upper(t.data_label)
		     and t.data_label is not null)
	  and tpm.data_label is not null;

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set data_label to null when found in category_path',SQL%ROWCOUNT,stepCt,'Done');
		
	commit;

	--	set visit_name to null if same as data_label
	
	update time_point_measurement t
	set visit_name=null
	where (t.category_cd, t.visit_name, t.data_label) in
	      (select distinct tpm.category_cd
				 ,tpm.visit_name
				 ,tpm.data_label
		  from time_point_measurement tpm
		  where tpm.visit_name = tpm.data_label);

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set visit_name to null when found in data_label',SQL%ROWCOUNT,stepCt,'Done');
		
	commit;
	
	--	set visit_name to null if same as data_value
	
	update time_point_measurement t
	set visit_name=null
	where (t.category_cd, t.visit_name, t.data_value) in
	      (select distinct tpm.category_cd
				 ,tpm.visit_name
				 ,tpm.data_value
		  from time_point_measurement tpm
		  where tpm.visit_name = tpm.data_value);

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set visit_name to null when found in data_value',SQL%ROWCOUNT,stepCt,'Done');
		
	commit;
  

		
	
  ---------------------------------------------------------------
  --BEGIN Using Node Curation table to convert values or set Suppression flag.
  ---------------------------------------------------------------

  --VISIT_NAME
  update time_point_measurement a
    set a.visit_name = 
      (select replace(Upper(a.visit_name), b.node_name, b.display_name)
        from node_curation b
        where b.node_type = 'VISIT_NAME'
          and upper(a.visit_name) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'VISIT_NAME'
        and upper(a.visit_name) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Node curation for VISIT_NAME',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;
  
  --DATA_VALUE
  update time_point_measurement a
    set a.data_value = 
      (select replace(Upper(a.data_value), b.node_name, b.display_name)
        from node_curation b
      where b.node_type = 'DATA_VALUE'
        and upper(a.data_value) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'DATA_VALUE'
        and upper(a.data_value) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Node curation for DATA_VALUE',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;
    
  --------------------------------------------------------------------------
  --category path
  update time_point_measurement a
    set a.data_label = 
      (select replace(Upper(a.data_label), b.node_name, b.display_name)
        from node_curation b
      where b.node_type = 'DATA_LABEL'
        and upper(a.data_label) = b.node_name  
        and active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'DATA_LABEL'
        and upper(a.data_label) = b.node_name  
        and active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Node curation for DATA_LABEL',SQL%ROWCOUNT,stepCt,'Done');
	
  Commit;
  --------------------------------------------------------------------------
  

  --DATA_LABEL
  update time_point_measurement a
    set a.data_label = 
      (select replace(Upper(a.data_label), b.node_name, b.display_name)
        from node_curation b
      where b.node_type = 'DATA_LABEL'
        and upper(a.data_label) like b.node_name  
        and active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      Where B.Node_Type = 'DATA_LABEL'
        and upper(a.data_label) like b.node_name  
        and active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Node curation for DATA_LABEL',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;

  --PERIOD
  update time_point_measurement a
    set a.period = 
      (select replace(Upper(a.period), b.node_name, b.display_name)
        from node_curation b
      where b.node_type = 'PERIOD'
        and upper(a.period) = b.node_name  
        and active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'PERIOD'
        and upper(a.period) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Node curation for PERIOD',SQL%ROWCOUNT,stepCt,'Done');
  COMMIT;

  --SAMPLE_TYPE
  update time_point_measurement a
    set a.sample_type = 
      (select replace(Upper(a.sample_type), b.node_name, b.display_name)
        from node_curation b
      where b.node_type = 'SAMPLE_TYPE'
        and upper(a.sample_type) = b.node_name  
        and active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'SAMPLE_TYPE'
        and upper(a.sample_type) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Node curation for SAMPLE_TYPE',SQL%ROWCOUNT,stepCt,'Done');
  COMMIT;
  
  
  --SUPPRESS VALUES BASED ON VISIT_NAME
  
  update time_point_measurement a
    set suppress_flag = 
      (select decode(b.display_in_ui,'N','Y',a.suppress_flag)
        from node_curation b
        where b.node_type = 'VISIT_NAME'
          and upper(a.visit_name) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'VISIT_NAME'
        and upper(a.visit_name) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Suppress VISIT_NAME',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;

  --SUPPRESS VALUES BASED ON DATA_LABEL
  update time_point_measurement a
    set suppress_flag = 
      (select decode(b.display_in_ui,'N','Y',a.suppress_flag)
        from node_curation b
        where b.node_type = 'DATA_LABEL'
          and upper(a.visit_name) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'DATA_LABEL'
        and upper(a.visit_name) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Suppress DATA_LABEL',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;

  --SUPPRESS VALUES BASED ON DATA_VALUE
  update time_point_measurement a
    set suppress_flag = 
      (select decode(b.display_in_ui,'N','Y',a.suppress_flag)
        from node_curation b
        where b.node_type = 'DATA_VALUE'
          and upper(a.visit_name) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'DATA_VALUE'
        and upper(a.visit_name) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Suppress DATA_VALUE',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;
  
  --SUPPRESS VALUES BASED ON PERIOD
   update time_point_measurement a
    set suppress_flag = 
      (select decode(b.display_in_ui,'N','Y',a.suppress_flag)
        from node_curation b
        where b.node_type = 'PERIOD'
          and upper(a.visit_name) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'PERIOD'
        and upper(a.visit_name) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.study_id)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.study_id = x.study_id)
             )
    );
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Suppress PERIOD',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;

	--	Remove sample_type if found in category_path
	
	update time_point_measurement t
	set sample_type = null
	where exists
	     (select 1 from category c
		  where instr(c.category_path,t.sample_type) > 0);
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove sample_type if already in category_path',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
  --Trim trailing and leadling spaces as well as remove any double spaces, remove space from before comma, remove trailing comma

  update time_point_measurement
  set data_label  = trim(trailing ',' from trim(replace(replace(data_label,'  ', ' '),' ,',','))),
      data_value  = trim(trailing ',' from trim(replace(replace(data_value,'  ', ' '),' ,',','))),
      period      = trim(trailing ',' from trim(replace(replace(period,'  ', ' '),' ,',','))),
      sample_type = trim(trailing ',' from trim(replace(replace(sample_type,'  ', ' '),' ,',','))),
      visit_name  = trim(trailing ',' from trim(replace(replace(visit_name,'  ', ' '),' ,',',')));
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Remove leading, trailing, double spaces',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;
  


    --1. DETERMINE THE DATA_TYPES OF THE FIELDS
	--	replaced cursor with update, used temp table to store category_cd/data_label because correlated subquery ran too long
	
	execute immediate('truncate table tm_cz.tmp_num_data_types');
	--delete from tmp_num_data_types;
    --commit;
  
	insert into tmp_num_data_types
	(category_cd
	,data_label
	,visit_name
	,period
	,sample_type
	)
      select category_cd,
            data_label,
            visit_name,
            period,
            sample_type
    FROM tm_wz.time_point_measurement
    WHERE data_value is not null
      AND suppress_flag = 'N'
      group by category_cd
	          ,data_label
                  ,visit_name
                  ,period
                  ,sample_type
      having sum(tm_cz.is_number(data_value)) = 0;
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert numeric data into WZ tmp_num_data_types',SQL%ROWCOUNT,stepCt,'Done');
	
	  commit;
	  
	  update time_point_measurement t
	  set data_type='N'
	  where exists
	        (select 1 from tmp_num_data_types x
			     where t.category_cd = x.category_cd
			       and nvl(t.data_label,'**NULL**') = nvl(x.data_label,'**NULL**')
				   and nvl(t.visit_name,'**NULL**') = nvl(x.visit_name,'**NULL**')
				   and nvl(t.period,'**NULL**') = nvl(x.period,'**NULL**')
				   and nvl(t.sample_type,'**NULL**') = nvl(x.sample_type,'**NULL**')
			);
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated data_type flag for numeric data_types',SQL%ROWCOUNT,stepCt,'Done');
	
	  commit;

	     
/*    
  --1. DETERMINE THE DATA_TYPES OF THE FIELDS
  -- set all values to Text type (T)
  update time_point_measurement 
    set data_type = 'T';
  COMMIT;
  --LOOPING THROUGH DISTINCT DATA_LABELS PER CATEGORY_PATH
  --CHECKING FIRST AND LAST VALUE, IF NUMERIC, THEN CONVERT IT.
  FOR r_cVariables in cVariables Loop
    select
      tm_cz.IS_NUMBER(MAX(data_value)), 
      tm_cz.IS_NUMBER(MIN(data_value)) INTO MAXVAL,MINVAL
    FROM time_point_measurement
    WHERE category_cd = r_cVariables.category_cd
      AND data_label = r_cVariables.data_label
      AND data_value IS NOT NULL
      AND suppress_flag = 'N';
       
    IF MAXVAL + MINVAL = 0 THEN
      update time_point_measurement 
        set data_type = 'N' 
        where category_cd = r_cVariables.category_Cd
          and data_label = r_cVariables.data_label;
      commit;
    END IF;
  END LOOP;
  
*/

 --2.  Build all needed leaf nodes in one pass for both numeric and text nodes
 
	execute immediate('truncate table tm_wz.tmp_trial_nodes');
	
	insert into tm_wz.tmp_trial_nodes
  (leaf_node
  ,category_cd
  ,visit_name
	,sample_type
	,period
	,data_label
  ,node_name
  ,data_value)
    select DISTINCT 
    Case 
	--	Scheduled Visits category
	When  upper(a.category_cd) like '%SCHEDULED_VISITS%'
		  then REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || 
                   '\' || data_label || '\' || data_value || '\',
                   '(\\){2,}', '\') 
                   
 -- In-Vivo studies\Samples and Timepoints
	When  upper(root_node) like '%IN-VIVO STUDIES%' AND upper(a.category_cd) like '%SAMPLES_AND_TIMEPOINTS%'
		  Then Regexp_Replace('\' || Root_Node || '\' || A.Study_Id || '\' || B.Category_Path || 
                   '\' || data_label|| '\' ||  a.visit_name  || '\' || a.period   || '\' || data_value || '\',
                   '(\\){2,}', '\') 

 -- In-Vivo studies\Treatment Groups
	When  upper(root_node) like '%IN-VIVO STUDIES%' AND upper(a.category_cd) like '%TREATMENT_GROUP%'
		  Then Regexp_Replace('\' || Root_Node || '\' || A.Study_Id || '\' || B.Category_Path || 
                   '\' || Data_Label|| '\' || Data_Value || '\',
                   '(\\){2,}', '\') 

                                     
	--	Text data_type and Biomarker/Other category
	When (upper(a.category_cd) like '%BIOMARKER%' 
          or upper(a.category_cd) like '%CLINICAL_DATA+OTHER_MEASUREMENTS%')
		  and a.data_type = 'T'
		  then REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || 
                   '\' || a.sample_type  || '\' || a.period   || '\' || data_label || '\' || data_value || '\' || a.visit_name  || '\',
                   '(\\){2,}', '\') 

	--	Text data_type and Week in category_cd
	When upper(a.category_cd) like '%_WEEK_%'
	     and a.data_type = 'T'
		 then REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || 
                   '\' || a.sample_type || '\' || data_label || '\' || data_value || '\',
                   '(\\){2,}', '\') 
	--	Text data_type (default node)
	When a.data_type = 'T'
	     then REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || 
                   '\' || a.visit_name  || '\' || a.period || '\' || a.sample_type || '\' || data_label || '\' || data_value || '\',
                   '(\\){2,}', '\') 
	--	Numeric data_type and Biomarker/Other/Scheduled Visits category
	When (upper(a.category_cd) like '%BIOMARKER%' 
          or upper(a.category_cd) like '%CLINICAL_DATA+OTHER_MEASUREMENTS%')
		 then REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || '\' || a.sample_type  || 
                    '\' || a.period || '\' || a.data_label || '\' || a.visit_name  || '\',
                   '(\\){2,}', '\')
	--	Numeric data_type and Week in category_cd
	When upper(a.category_cd) like '%_WEEK_%'
		 then  REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || 
                   '\' || a.sample_type || '\' || a.data_label || '\',
                   '(\\){2,}', '\')
	--	else is numeric data_type and default_node
	else REGEXP_REPLACE('\' || root_node || '\' || a.study_id || '\' || b.category_path || 
                   '\' || a.visit_name  || '\' || a.period || '\' || a.sample_type || '\' || a.data_label || '\',
                   '(\\){2,}', '\')
	end as leaf_node,
    a.category_cd,
    a.visit_name,
	a.sample_type,
	a.period,
	a.data_label,
  Case 
	When  upper(a.category_cd) like '%SCHEDULED_VISITS%'
		  then  a.data_value 
	--	Text data_type and Biomarker/Other category
	When (upper(a.category_cd) like '%BIOMARKER%' 
          or upper(a.category_cd) like '%CLINICAL_DATA+OTHER_MEASUREMENTS%')
		  and a.data_type = 'T'
		  then coalesce(a.visit_name,a.data_value)  
	--	Text data_type and Week in category_cd
	When upper(a.category_cd) like '%_WEEK_%'
	     and a.data_type = 'T'
		 then a.data_value 
	--	Text data_type (default node)
	When a.data_type = 'T'
	    then a.data_value 
	--	Numeric data_type and Biomarker/Other category
	When (upper(a.category_cd) like '%BIOMARKER%' 
          or upper(a.category_cd) like '%CLINICAL_DATA+OTHER_MEASUREMENTS%')
		 then  coalesce(a.visit_name,a.data_label) 
	--	Numeric data_type and Week in category_cd
	When upper(a.category_cd) like '%_WEEK_%'
	     then a.data_label 
	--	else is numeric data_type and default_node
	else a.data_label 
	end as node_name,
	decode(a.data_type,'T',a.data_value,null) as data_value
  from  time_point_measurement a
  join category b
    on a.category_cd = b.category_cd
    and data_value is not null
    and a.study_id = TrialID
    AND a.suppress_flag = 'N';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Create leaf nodes for trial',SQL%ROWCOUNT,stepCt,'Done');
	
	
	commit;

	execute immediate('analyze table tm_wz.tmp_trial_nodes compute statistics');
	
	--	bulk insert leaf nodes
	
	insert into concept_dimension
    (concept_cd
	,concept_path
	,name_char
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,table_name
	)
    select 'JNJ'||concept_id.nextval
		  ,leaf_node
		  ,to_char(node_name)
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,TrialID
		  ,'CONCEPT_DIMENSION'
	from tm_wz.tmp_trial_nodes;
	
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted leaf nodes into I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
    commit;
	
	insert into i2b2
    (c_hlevel
	,c_fullname
	,c_name
	,c_visualattributes
	,c_synonym_cd
	,c_facttablecolumn
	,c_tablename
	,c_columnname
	,c_dimcode
	,c_tooltip
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,c_basecode
	,c_operator
	,c_columndatatype
	,c_comment
	)
    select (length(concept_path) - nvl(length(replace(concept_path, '\')),0)) / length('\') - 3
		  ,concept_path
		  ,name_char
		  ,'FA'
		  ,'N'
		  ,'CONCEPT_CD'
		  ,'CONCEPT_DIMENSION'
		  ,'CONCEPT_PATH'
		  ,concept_path
		  ,concept_path
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,sourcesystem_cd
		  ,concept_cd
		  ,'LIKE'
		  ,'T'
		  ,'trial:' || TrialID 
    from concept_dimension
    where concept_path in
	     (select leaf_node from tm_wz.tmp_trial_nodes);
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted leaf nodes into I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
    COMMIT;
	
--	3.	Add leaf nodes to i2b2, etc
/*

  FOR r_addNodes in addNodes Loop

    --Add nodes for all types (ALSO DELETES EXISTING NODE)
	
	i2b2_add_node(TrialID, r_addNodes.leaf_node, r_addNodes.node_name, jobId);
	
  END LOOP;  
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Add nodes for leaf nodes',0,stepCt,'Done');
*/



 /*  --5 Update I2B2
  --Update I2b2 for correct data type
  update i2b2
  SET c_columndatatype = 'N',
      --Static XML String
      c_metadataxml = '<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis></ValueMetadata>'
  where c_basecode IN (
    select concept_cd from observation_fact
      having Max(valtype_cd) = 'N'
      group by concept_Cd
    )
    and c_fullname like '%' || TrialID || '%';
  commit;
  
  */

  --UPDATE VISUAL ATTRIBUTES for Leaf Active (Default is folder)
  update i2b2 a
    set c_visualattributes = 'LA'
    where 1 = (
      select count(*)
      from i2b2 b
      where b.c_fullname like (a.c_fullname || '%'))
    AND c_fullname like '%' || TrialID || '%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Update visual attributes for leaf nodes in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;

  --Set c_basecode = null where type is a folder.
  --Basecode is not needed since no records exist on the Observation Fact for Folders.
  
  /* Comments for Temp Trouble Shooting - JDC 10-Oct-2010
  */
  update i2b2 
    set c_basecode = ''
    where c_visualattributes = 'FA'
    AND c_fullname like '%' || TrialID || '%';
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Set c_basecode to null for folders in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
	
  COMMIT;




    ---Cleanup OVERALL JOB if this proc is being run standalone
  IF newJobFlag = 1
  THEN
    cz_end_audit (jobID, 'SUCCESS');
  END IF;

  rtnCode := 0;
  
  EXCEPTION
  WHEN OTHERS THEN
    --Handle errors.
    cz_error_handler (jobID, procedureName);
    --End Proc
    cz_end_audit (jobID, 'FAIL');
	rtnCode := 16;
	
END;
/
