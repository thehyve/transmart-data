--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_PROCESS_RBM_DATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_PROCESS_RBM_DATA" 
(
  trial_id VARCHAR2
 ,currentJobID NUMBER := null
)
AS
  
  --	JEA@20100115	New
  --	JEA@20100121	Removed IgA/IgE/IgM-specific code, moved entries to stg_rbm_antigen_gene table
  --	JEA@20100129	Removed delete of N/A, Not Requested, QNS value_text, will be dropped because not numeric
  --	JEA@20100201	Renamed to I2B2_PROCESS_RBM_DATA from I2B2_LOAD_RBM_DATA for consistency amoung mRNA, RBM, and protein load procedures

  TrialID varchar2(100);
  RootNode VARCHAR2(100);
  pExists number;
    
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

  --Audit JOB Initialization
  --If Job ID does not exist, then this is a single procedure run and we need to create it
  IF(jobID IS NULL or jobID < 1)
  THEN
    newJobFlag := 1; -- True
    cz_start_audit (procedureName, databaseName, jobID);
  END IF;
    	
  stepCt := 0;
  stepCt := stepCt + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Start i2b2_process_rbm_data',0,stepCt,'Done');
	
  --Determine root value of I2B2: Could be Clinical or Experimental
  select parse_nth_value(c_fullname, 2, '\') into RootNode
  from i2b2
  where c_name = TrialID;

  --if Root Node is null, then add a root node as a clinical trial as a default.
  if RootNode is null then  
    i2b2_add_node(TrialID, '\Clinical Trials\' || TrialID || '\', TrialID, jobID);
    RootNode := 'Clinical Trials';
  end if;

	--Cleanup any existing data from raw table
  
	delete from deapp_wz.stg_subject_rbm_data_raw 
    where trial_name = TrialID; 

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from DEAPP_WZ stg_subject_rbm_data_raw',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Insert into raw data table from staging
 
	insert into deapp_wz.stg_subject_rbm_data_raw
	(trial_name
	,antigen_name
	,value_text
	,timepoint
	,assay_id
	,sample_id
	,subject_id
	,site_id
	)
	select trial_name
		  ,antigen_name
		  ,value_text
		  ,timepoint
		  ,assay_id
		  ,sample_id
		  ,subject_id
		  ,site_id
	from deapp_wz.stg_subject_rbm_data
    where trial_name = TrialID; 

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial into DEAPP_WZ stg_subject_rbm_data_raw',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--Remove any unit values from antigen_name and trim antigen_name
	
	update deapp_wz.stg_subject_rbm_data
	set antigen_name = trim(case when instr(upper(antigen_name),'NMOL/L') > 0
								 then substr(antigen_name,1,instr(UPPER(antigen_name),'NMOL/L')-1)
								 when instr(upper(antigen_name),'MIU/ML') > 0
								 then substr(antigen_name,1,instr(UPPER(antigen_name),'MIU/ML')-1)
								 else antigen_name
							end
						   );

	stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Removed units from antigen_name and trimmed in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Perform node-curation on timepoint

	update deapp_wz.stg_subject_rbm_data a
    set a.timepoint = 
       (select replace(Upper(a.timepoint), b.node_name, b.display_name)
        from node_curation b
        where b.node_type = 'VISIT_NAME'
          and upper(a.timepoint) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.trial_name)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.trial_name = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'VISIT_NAME'
        and upper(a.timepoint) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.trial_name)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.trial_name = x.study_id)
             )
    );
	
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated timepoints in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	--	Perform node-curation on antigen_name

	update deapp_wz.stg_subject_rbm_data a
    set a.antigen_name = 
       (select replace(Upper(a.antigen_name), b.node_name, b.display_name)
        from node_curation b
        where b.node_type = 'ANTIGEN'
          and upper(a.antigen_name) = b.node_name  
          and b.active_flag = 'Y'
          and (b.global_flag = 'Y' OR b.study_id = a.trial_name)
		  and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.trial_name = x.study_id)
             )
      )
    where exists
    (select 1 
      from node_curation b 
      where b.node_type = 'ANTIGEN'
        and upper(a.antigen_name) = b.node_name  
        and b.active_flag = 'Y'
        and (b.global_flag = 'Y' OR b.study_id = a.trial_name)
		and b.global_flag =
			 (select min(x.global_flag) from node_curation x
			  where b.node_type = x.node_type
                and b.node_name = x.node_name
                and (x.global_flag = 'Y' or a.trial_name = x.study_id)
             )
    );
	
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated antigen_name in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	--	Update any values that contain < to value-.01 and that contain > to value+.01
	
	update deapp_wz.stg_subject_rbm_data t
	set value_text=decode(instr(value_text,'<'),0,to_char(to_number(replace(value_text,'>',''))+.01),to_char(to_number(replace(value_text,'<',''))-.01))
	where (value_text like '%<%' or value_text like '%>%')
	  and tm_cz.is_number(replace(replace(value_text,'<',''),'>','')) = 0;

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated values with < or > in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	--	Delete any data where antigen_name is null and value is null
	
	delete from deapp_wz.stg_subject_rbm_data
	where antigen_name is null
	  and value_text is null;
	  
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete records with null antigen_name and value_text in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	--	Delete any antigens that have more than 50% of the values as LOW
	
	delete from deapp_wz.stg_subject_rbm_data s
	where s.antigen_name in
	     (select x.antigen_name
		 from deapp_wz.stg_subject_rbm_data x
		 group by x.antigen_name
		 having sum(decode(instr(upper(x.value_text),'LOW'),0,0,1))/count(*) > .50);
	  
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete antigens with > 50% LOW values in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	--	Update numeric values 
	
	update deapp_wz.stg_subject_rbm_data
	set value_number=to_number(value_text)
	where tm_cz.is_number(value_text) = 0;
	  
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated numeric values in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;		

	--	Update any remaining LOW values to 50% of minimum value for antigen
	
	update deapp_wz.stg_subject_rbm_data s
	set value_number=
	    (select min(x.value_number)*.5
		 from deapp_wz.stg_subject_rbm_data x
		 where s.antigen_name = x.antigen_name
		  and x.value_number is not null)
	where upper(s.value_text) like '%LOW%';

	stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Updated LOW values in DEAPP_WZ stg_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--Cleanup any existing data from data file
  
	delete from deapp_wz.de_subject_rbm_data
    where trial_name = TrialID; 

	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from DEAPP_WZ de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	create temporary indexes
	
	select count(*)
	into pExists
	from all_indexes
	where owner = 'DEAPP_WZ'
	  and index_name = 'STG_SUBJECT_RBM_DATA_I1';
	  
	if pExists > 0 then
		execute immediate('drop index deapp_wz.stg_subject_rbm_data_i1');
	end if;
	execute immediate('create index deapp_wz.stg_subject_rbm_data_i1 on deapp_wz.stg_subject_rbm_data (antigen_name, subject_id) tablespace deapp');
	
	select count(*)
	into pExists
	from all_indexes
	where owner = 'DEAPP'
	  and index_name = 'STG_RBM_ANTIGEN_GENE_I1';
	  
	if pExists > 0 then
		execute immediate('drop index deapp.stg_rbm_antigen_gene_i1');
	end if;

	execute immediate('create index deapp.stg_rbm_antigen_gene_i1 on deapp.stg_rbm_antigen_gene (antigen_name) tablespace deapp');
	
	select count(*)
	into pExists
	from all_indexes
	where owner = 'I2B2_LZ'
	  and index_name = 'RBM_PATIENT_INFO_I1';
	  
	if pExists > 0 then
		execute immediate('drop index i2b2_lz.rbm_patient_info_i1');
	end if;
	
	execute immediate('create index i2b2_lz.rbm_patient_info_i1 on i2b2_lz.patient_info (study_id, subject_id, usubjid) tablespace i2b2_data');
	
	select count(*)
	into pExists
	from all_indexes
	where owner = 'I2B2DEMODATA'
	  and index_name = 'RBM_PATIENT_DIMENSION_I1';
	  
	if pExists > 0 then
		execute immediate('drop index i2b2demodata.rbm_patient_dimension_i1');
	end if;	
			
	execute immediate('create index i2b2demodata.rbm_patient_dimension_i1 on i2b2demodata.patient_dimension (sourcesystem_cd) tablespace i2b2_data');
	
    insert into deapp_wz.de_subject_rbm_data
	(trial_name
	,antigen_name
	,value
	,n_value
	,patient_id
	,gene_symbol
	,gene_id
	,assay_id
	,normalized_value
	,concept_cd
	,timepoint
	,zscore
	)
	select rbm.trial_name
		  ,rbm.antigen_name
		  ,avg(rbm.value_number) as value
		  ,avg(rbm.value_number) as n_value
		  ,pd.patient_num
		  ,ag.gene_symbol
		  ,ag.gene_id
		  ,to_number(rbm.assay_id)
		  ,0 as normalized_value
		  ,rbm.trial_name || ':' || substr(rbm.antigen_name,1,20) as concept_cd
		  ,rbm.timepoint
		  ,0 as zscore
	from deapp_wz.stg_subject_rbm_data rbm
		,i2b2_lz.patient_info pi
		,i2b2demodata.patient_dimension pd
		,deapp.stg_rbm_antigen_gene ag
	where rbm.subject_id = pi.subject_id
	  and nvl(rbm.site_id,'**NULL**') = nvl(pi.site_id,'**NULL**')
	  and pi.study_id = TrialId
	  and pi.usubjid = pd.sourcesystem_cd
	  and rbm.trial_name = TrialId
	  and rbm.antigen_name = ag.antigen_name
	  and rbm.value_number is not null
	  and rbm.value_number > 0
	  group by rbm.trial_name
		  ,rbm.antigen_name
		  ,pd.patient_num
		  ,ag.gene_symbol
		  ,ag.gene_id
		  ,to_number(rbm.assay_id)
		  ,rbm.trial_name || ':' || substr(rbm.antigen_name,1,20) 
		  ,rbm.timepoint;
	  
	stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP_WZ de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	execute immediate('drop index deapp_wz.stg_subject_rbm_data_i1');
	execute immediate('drop index deapp.stg_rbm_antigen_gene_i1');
	execute immediate('drop index i2b2_lz.rbm_patient_info_i1');
	execute immediate('drop index i2b2demodata.rbm_patient_dimension_i1');
	
	/*	the delete/insert will be done as part of i2b2_rbm_zscore_calc procedure'
	
	--	Delete existing data from deapp.de_subject_rbm_data

	delete from deapp.de_subject_rbm_data
	where trial_name = TrialId;
		  
	stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Insert trial into deapp.de_subject_rbm_data
	
	insert into deapp.de_subject_rbm_data
	(trial_name
	,antigen_name
	,n_value
	,patient_id
	,gene_symbol
	,gene_id
	,assay_id
	,normalized_value
	,concept_cd
	,timepoint
	,value
	,zscore
	)
	select trial_name
		  ,antigen_name
		  ,n_value
		  ,patient_id
		  ,gene_symbol
		  ,gene_id
		  ,assay_id
		  ,normalized_value
		  ,concept_cd
		  ,timepoint
		  ,value
		  ,zscore 
	from deapp_wz.de_subject_rbm_data
	where trial_name = TrialID;
	  
	stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
*/

	--	ZScore calculation
	
	i2b2_rbm_zscore_calc(Trialid, jobid);
	
	--	Add observed and zscore to i2b2
	
	i2b2_load_rbm_data(TrialID, 'O', jobId); 	-- Observed values
	i2b2_load_rbm_data(TrialID, 'Z', jobId);		-- Z-Scores
	
	stepCt := stepCt + 1;
    tm_cz.cz_write_audit(jobId,databaseName,procedureName,'End i2b2_process_rbm_data',0,stepCt,'Done');
	
    ---Cleanup OVERALL JOB if this proc is being run standalone
  IF newJobFlag = 1
  THEN
    cz_end_audit (jobID, 'SUCCESS');
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
    --Handle errors.
    cz_error_handler (jobID, procedureName);
    --End Proc
    cz_end_audit (jobID, 'FAIL'); 

END;
/
 
