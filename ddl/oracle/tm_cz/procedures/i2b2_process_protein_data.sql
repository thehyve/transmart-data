--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_PROCESS_PROTEIN_DATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_PROCESS_PROTEIN_DATA" 
(
  trial_id VARCHAR2
 ,currentJobID NUMBER := null
)
AS
  
  --	JEA@20100128	New

  TrialID varchar2(100);
  RootNode VARCHAR2(100);
  pExists number;
    
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);

	--	cursor for add_nodes
	
  CURSOR addNodes is
  select distinct REGEXP_REPLACE('\' || rootnode || '\' || TrialID || '\Biomarker Data\Protein\Proteomics\' || timepoint || '\' ,
                  '(\\){2,}', '\') as path
         ,timepoint as node_name
  from  deapp.de_subject_protein_data
  where trial_name = TrialId;
	
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
  control.cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_load_protein_data',0,stepCt,'Done');
	
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
  
	delete from deapp_wz.stg_subject_protein_data_raw 
    where trial_name = TrialID; 

	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from DEAPP_WZ stg_subject_protein_data_raw',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Insert into raw data table from staging
 
	insert into deapp_wz.stg_subject_protein_data_raw
	(trial_name
	,component
	,intensity_text
	,timepoint
	,assay_id
	,gene_symbol
	,gene_id
	,subject_id
	,site_id
	)
	select trial_name
		  ,component
		  ,intensity_text
		  ,timepoint
		  ,assay_id
		  ,gene_symbol
		  ,gene_id
		  ,subject_id
		  ,site_id
	from deapp_wz.stg_subject_protein_data
    where trial_name = TrialID; 

	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial into DEAPP_WZ stg_subject_protein_data_raw',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Perform node-curation on timepoint

	update deapp_wz.stg_subject_protein_data a
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
	control.cz_write_audit(jobId,databaseName,procedureName,'Updated timepoints in DEAPP_WZ stg_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	--	Update any values that contain < to value-.01 and that contain > to value+.01
	
	update deapp_wz.stg_subject_protein_data t
	set intensity_text=decode(instr(intensity_text,'<'),0,to_char(to_number(replace(intensity_text,'>',''))+.01),to_char(to_number(replace(intensity_text,'<',''))-.01))
	where (intensity_text like '%<%' or intensity_text like '%>%')
	  and control.is_number(replace(replace(intensity_text,'<',''),'>','')) = 0;

	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Updated values with < or > in DEAPP_WZ stg_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	--	Delete any data where component is null and value is null
	
	delete from deapp_wz.stg_subject_protein_data
	where component is null
	  and intensity_text is null;
	  
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete records with null antigen_name and intensity_text in DEAPP_WZ stg_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	--	Update numeric values 
	
	update deapp_wz.stg_subject_protein_data
	set intensity=to_number(intensity_text)
	where control.is_number(intensity_text) = 0;
	  
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Updated numeric values in DEAPP_WZ stg_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;		

	--Cleanup any existing data from data file
  
	delete from deapp_wz.de_subject_protein_data
    where trial_name = TrialID; 

	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from DEAPP_WZ de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	create temporary indexes
	
	select count(*)
	into pExists
	from all_indexes
	where owner = 'DEAPP_WZ'
	  and index_name = 'stg_subject_protein_data_I1';
	  
	if pExists > 0 then
		execute immediate('drop index deapp_wz.stg_subject_protein_data_i1');
	end if;
	execute immediate('create index deapp_wz.stg_subject_protein_data_i1 on deapp_wz.stg_subject_protein_data (component, subject_id) tablespace deapp');

	select count(*)
	into pExists
	from all_indexes
	where owner = 'I2B2_LZ'
	  and index_name = 'PROTEIN_PATIENT_INFO_I1';
	  
	if pExists > 0 then
		execute immediate('drop index i2b2_lz.protein_patient_info_i1');
	end if;
	
	execute immediate('create index i2b2_lz.protein_patient_info_i1 on i2b2_lz.patient_info (study_id, subject_id, usubjid) tablespace i2b2_data');
	
	select count(*)
	into pExists
	from all_indexes
	where owner = 'I2B2DEMODATA'
	  and index_name = 'PROTEIN_PATIENT_DIMENSION_I1';
	  
	if pExists > 0 then
		execute immediate('drop index i2b2demodata.protein_patient_dimension_i1');
	end if;	
			
	execute immediate('create index i2b2demodata.protein_patient_dimension_i1 on i2b2demodata.patient_dimension (sourcesystem_cd) tablespace i2b2_data');
	
    insert into deapp_wz.de_subject_protein_data
	(trial_name
	,component
	,intensity
	,n_value
	,patient_id
	,gene_symbol
	,gene_id
	,assay_id
	,timepoint
	,zscore
	)
	select p.trial_name
		  ,p.component
		  ,avg(p.intensity) as value
		  ,avg(p.intensity) as n_value
		  ,pd.patient_num
		  ,p.gene_symbol
		  ,p.gene_id
		  ,p.assay_id
		  ,p.timepoint
		  ,0 as zscore
	from deapp_wz.stg_subject_protein_data p
		,i2b2_lz.patient_info pi
		,i2b2demodata.patient_dimension pd
	where p.subject_id = pi.subject_id
	  and nvl(p.site_id,'**NULL**') = nvl(pi.site_id,'**NULL**')
	  and pi.study_id = TrialId
	  and pi.usubjid = pd.sourcesystem_cd
	  and p.trial_name = TrialId
	  and p.intensity is not null
	  and p.intensity > 0
	  and p.gene_symbol is not null
	  group by p.trial_name
		  ,p.component
		  ,pd.patient_num
		  ,p.gene_symbol
		  ,p.gene_id
		  ,p.assay_id
		  ,p.timepoint;
	  
	stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP_WZ de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	execute immediate('drop index deapp_wz.stg_subject_protein_data_i1');
	execute immediate('drop index i2b2_lz.protein_patient_info_i1');
	execute immediate('drop index i2b2demodata.protein_patient_dimension_i1');
	
	--	ZScore calculation which will insert data to deapp.de_subject_protein_data
	
	i2b2_protein_zscore_calc(Trialid, jobid);
	
--	add the high level \Biomarker Data\ node if it doesn't exist (first time loading data)
  
	select count(*)
	into pExists
	from i2b2
	where c_fullname = '\' || RootNode || '\'|| TrialID || '\Biomarker Data\';
  
	if pExists = 0 then 
		i2b2_add_node(trialID, '\' || RootNode || '\' || trialID || '\Biomarker Data\', 'Biomarker Data', jobID);
        stepCt := stepCt + 1;
	    control.cz_write_audit(jobId,databaseName,procedureName,'Add Biomarker Data node for trial',0,stepCt,'Done');
	end if;

    --	check if Proteomics node exists, if yes, then delete existing data
	
	select count(*) into pExists
	from i2b2
	where c_fullname = '\' || RootNode || '\'|| TrialID || '\Biomarker Data\Protein\Proteomics\';
		  
	if pExists != 0 then
		--This deletes all i2b2, concept_dimension, and observation_fact records wher the path starts with the passed paramenter
		i2b2_delete_all_nodes('\' || RootNode || '\'|| TrialID || '\Biomarker Data\Protein\Proteomics\', jobID);
		stepCt := stepCt + 1;
		control.cz_write_audit(jobId,databaseName,procedureName,'Delete existing Proteomics data for trial in I2B2METADATA i2b2',0,stepCt,'Done');
	end if;
	
	--	Cleanup any existing data in de_subject_sample_mapping.  
	
	delete from deapp.DE_SUBJECT_SAMPLE_MAPPING 
	where trial_name = TrialID 
	  and platform = 'Protein'
	  and platform_cd = trialID || ':Protein'; --Making sure only protein data is deleted
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete trial from DEAPP de_subject_sample_mapping',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--	add \Biomarker\Protein\Proteomics\timepoint nodes
	
	FOR r_addNodes in addNodes Loop
		
		i2b2_add_node(TrialId, r_addNodes.path, r_addNodes.node_name, jobId);

	End loop;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Added Biomarker\Protein\Proteomics\timepoint nodes',0,stepCt,'Done');
	commit;
	
  --Load the DE_SUBJECT_SAMPLE_MAPPING from deapp_wz.stg_subject_mrna_data

  --CONCEPT_CODE    = generated JNJ concept code 
  --PATIENT_ID      = PATIENT_ID (SAME AS ID ON THE PATIENT_DIMENSION)
  --TRIAL_NAME      = TRIAL_NAME
  --TIMEPOINT       = TIMEPOINT
  --ASSAY_ID        = ASSAY_ID
  --PLATFORM        = Protein - this is required by ui code
  --PLATFORM_CD     = trial_name || 'Protein' 
  --TISSUE_TYPE     = NULL
  --SITE_ID         = NULL
  --SUBJECT_ID      = NULL
  --SUBJECT_TYPE    = NULL
  --PATIENT_UID     = NULL
  --SAMPLE_TYPE     = NULL
  --ASSAY_UID       = NULL
  --TIMEPOINT_CD    = same as concept_cd
  --SAMPLE_TYPE_CD  = NULL
  --TISSUE_TYPE_CD  = NULL
  --GPL_ID			= NULL
    
	insert into de_subject_sample_mapping
	(data_uid
	,concept_code
	,patient_id
	,trial_name
	,timepoint
	,assay_id
	,platform
	,platform_cd
	,timepoint_cd
	,sample_type
	,sample_type_cd
	,gpl_id
    )
	select distinct replace(cd.concept_cd || '-' || a.patient_id,' ','') as data_uid
	      ,cd.concept_cd
		  ,a.patient_id
		  ,a.trial_name
		  ,a.timepoint
		  ,a.assay_id
		  ,'Protein'
		  ,a.trial_name || ':Protein'
		  ,cd.concept_cd as timepoint_cd
		  ,null
		  ,null as sample_type_cd
		  ,null
	from deapp.de_subject_protein_data a		
    --Joining to Pat_dim to ensure the ID's match. If not I2B2 won't work.
	join i2b2demodata.patient_dimension b
	  on a.patient_id = b.patient_num
	join i2b2demodata.concept_dimension cd
	  on cd.concept_path = '\' || rootNode || '\' || TrialId || '\Biomarker Data\Protein\Proteomics\' || a.timepoint || '\'
    where a.trial_name = TrialID; 
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into DEAPP de_subject_sample_mapping',SQL%ROWCOUNT,stepCt,'Done');
	commit;
         
--	Insert records for patients and timepoints into observation_fact

	insert into observation_fact
    (patient_num
	,concept_cd
	,modifier_cd
	,valtype_cd
	,tval_char
	,nval_num
	,sourcesystem_cd
	,import_date
	,valueflag_cd
	,provider_id
	,location_cd
	,units_cd
    )
    select m.patient_id
		  ,m.concept_code
		  ,m.trial_name
		  ,'T' -- Text data type
		  ,'E'  --Stands for Equals for Text Types
		  ,null	--	not numeric for Proteomics
		  ,m.trial_name
		  ,sysdate
		  ,'@'
		  ,'@'
		  ,'@'
		  ,'' -- no units available
    from  deapp.de_subject_sample_mapping m
    where trial_name = TrialID 
      and platform = 'Protein'
    group by patient_id
			,concept_code
			,trial_name;
    stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');

    commit;
    
--	Update visual attributes for leaf active (default is folder)

	update i2b2 a
    set c_visualattributes = 'LA'
    where 1 = (select count(*)
			   from i2b2 b
			   where b.c_fullname like (a.c_fullname || '%'))
      and a.c_fullname like '\' || RootNode || '\' || TrialID || '\Biomarker Data\%';
    stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Update leaf active attribute for trial in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
    commit;
	
--	fill in tree

	i2b2_fill_in_tree(TrialID,'\' || rootNode || '\' || TrialID || '\Biomarker Data\', jobID);
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Fill in tree for Biomarker Data for trial',SQL%ROWCOUNT,stepCt,'Done');
  
  --Build concept Counts
  --Also marks any i2B2 records with no underlying data as Hidden, need to do at Biomarker level because there may be multiple platforms and patient count can vary
  
    i2b2_create_concept_counts('\' || RootNode || '\' || TrialID || '\Biomarker Data\',jobID );
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Create concept counts',0,stepCt,'Done');

  --Reload Security: Inserts one record for every I2B2 record into the security table

    i2b2_load_security_data(jobId);
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Load security data',0,stepCt,'Done');

	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'End i2b2_process_protein_data',0,stepCt,'Done');
		
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
