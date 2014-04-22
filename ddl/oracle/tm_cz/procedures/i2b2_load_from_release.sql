--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_LOAD_FROM_RELEASE
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_LOAD_FROM_RELEASE" 
(
  trial_id IN VARCHAR2
 ,ont_Path IN VARCHAR2
 ,currentJobID NUMBER := null
 )
AS

	TrialId 	varchar2(200);
	ontPath 	varchar2(200);
	msgText 	varchar2(1000); 
	
	sqlText 	varchar2(2000);
	tExists 	number;
	returnCode 	number;
	gotSNP		integer;
	StudyType	varchar2(100);

	--Audit variables
	newJobFlag INTEGER(1);
	DATABASENAME VARCHAR(100);
	procedureName VARCHAR(100); 
	jobID number(18,0);
	stepCt number(18,0);

	--	JEA@20100624	Removed gene_symbol, changed probeset to probeset_id in de_subject_microarray_data,
	--					added de_mrna_annotation load (complete reload, not tied to study)
	--	JEA@20100625	Changed check if partition exists from count of records to entry in all_tab_partitions table
	--	JEA@20100901	Added insert into i2b2_tags
	--	JEA@20100903	Added haploview_data insert
	--	JEA@20100908	Added i2b2_id to i2b2
	--	JEA@20101013	Added de_gpl_info insert
	--	JEA@20101202	Added rbm_panel to de_subj_sample_map_release and de_subject_rbm_data_release
	--	JEA@20110125	Added deapp SNP tables 
	
BEGIN

	TrialID := upper(trial_id);
	ontPath := ont_path;
	
	select parse_nth_value(ontPath,2,'\') into StudyType
	from dual;

	stepCt := 0;

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

	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_load_from_release',0,stepCt,'Done');
	stepCt := stepCt + 1;
	msgText := 'Loading trial: ' || TrialId || ' path: ' || ontPath;
	cz_write_audit(jobId,databaseName,procedureName, msgText,0,stepCt,'Done');
	stepCt := stepCt + 1;

	--	Delete trial from target tables

	i2b2_delete_all_nodes(ontPath, jobId);

	delete from i2b2metadata.i2b2
	where c_fullname like ontPath || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete from i2b2demodata.concept_dimension
	where concept_path like ontPath || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete from i2b2demodata.observation_fact
	where modifier_cd = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	commit;


	delete from i2b2demodata.observation_fact
	where modifier_cd = TrialId
	  and concept_cd = 'SECURITY';

	cz_write_audit(jobId,databaseName,procedureName,'Deleted SECURITY for trial from I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
	  
	delete from i2b2demodata.patient_dimension
	where sourcesystem_cd like TrialId || '%';

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from I2B2DEMODATA patient_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.de_subject_sample_mapping
	where trial_name = TrialId;
	
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_subject_sample_mapping',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;







	--	create or truncate partition in de_subject_microarray_data

	tExists := 0;
	
	select count(*) 
	into tExists
	from all_tab_partitions
	where table_owner = 'DEAPP'
	  and table_name = 'DE_SUBJECT_MICROARRAY_DATA'
	  and partition_name = TrialId || ':STD';


	if tExists = 0 then

--	needed to add partition to deapp.de_subject_microarray_data

		sqlText := 'alter table deapp.DE_SUBJECT_MICROARRAY_DATA add PARTITION "' || TrialId || ':' || 'STD' || 
						'"  VALUES (' || '''' || TrialId || ':' || 'STD' || '''' || ') ' ||
						   'NOLOGGING COMPRESS TABLESPACE "DEAPP" ';
		execute immediate(sqlText);
       
	    cz_write_audit(jobId,databaseName,procedureName,'Adding partition to DEAPP de_subject_microarray_data',0,stepCt,'Done');
		stepCt := stepCt + 1;

	else
		sqlText := 'alter table deapp.de_subject_microarray_data truncate partition ' || TrialID;
		execute immediate(sqlText);
		
	    cz_write_audit(jobId,databaseName,procedureName,'Truncate partition in DEAPP de_subject_microarray_data',0,stepCt,'Done');
		stepCt := stepCt + 1;

	end if;
  
  
  





	delete from deapp.de_subject_rbm_data
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.de_subject_protein_data
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.haploview_data
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP haploview',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from i2b2_tags
	where path like ontPath || '%';

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from I2B2METADATA i2b2_tags',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from biomart.bio_data_compound t
	where t.bio_data_id =
	     (select distinct x.bio_experiment_id from bio_experiment_release x
		  where x.accession = Trialid);

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from BIOMART bio_data_compound',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.de_subject_snp_dataset
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_subject_snp_dataset',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.de_snp_data_by_patient
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_snp_data_by_patient',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.de_snp_data_dataset_loc
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_snp_data_dataset_loc',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	delete from deapp.de_snp_data_by_probe
	where trial_name = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from DEAPP de_snp_data_by_probe',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
  
	select count(*) into gotSNP
	from deapp.de_snp_data_by_patient;
	
	if gotSNP > 0 then 
		-- Remove constraints before truncating data
		execute immediate('alter table DE_SNP_INFO DISABLE constraint U_SNP_INFO_NAME;');
		execute immediate('alter table DE_SNP_PROBE DISABLE constraint U_SNP_PROBE_NAME;');
		execute immediate('alter table DE_SNP_GENE_MAP DISABLE constraint FK_SNP_GENE_MAP_SNP_ID;');
		execute immediate('alter table DE_SNP_DATA_BY_PROBE DISABLE constraint FK_SNP_BY_PROBE_SNP_ID;');
		execute immediate('alter table DE_SNP_PROBE DISABLE constraint FK_SNP_PROBE_SNP_ID;');
		execute immediate('alter table DE_SNP_INFO DISABLE constraint SYS_C0045667;');

		cz_write_audit(jobId,databaseName,procedureName,'Disabled constraints from SNP tables',SQL%ROWCOUNT,stepCt,'Done');
		commit;
		stepCt := stepCt + 1;
		
		execute immediate('truncate table deapp.de_snp_info');

		cz_write_audit(jobId,databaseName,procedureName,'Truncate table DEAPP de_snp_info',SQL%ROWCOUNT,stepCt,'Done');
		stepCt := stepCt + 1;
	
		execute immediate('truncate table deapp.de_snp_probe');

		cz_write_audit(jobId,databaseName,procedureName,'Truncate table DEAPP de_snp_probe',SQL%ROWCOUNT,stepCt,'Done');
		stepCt := stepCt + 1;
	
		execute immediate('truncate table deapp.de_snp_gene_map');

		cz_write_audit(jobId,databaseName,procedureName,'Truncate table DEAPP de_snp_gene_map',SQL%ROWCOUNT,stepCt,'Done');
		stepCt := stepCt + 1;
	
		execute immediate('truncate table deapp.de_snp_probe_sorted_def');

		cz_write_audit(jobId,databaseName,procedureName,'Truncate table DEAPP de_snp_probe_sorted_def',SQL%ROWCOUNT,stepCt,'Done');
		end if;

	--execute immediate('truncate table deapp.de_mrna_annotation');

	--cz_write_audit(jobId,databaseName,procedureName,'Truncate table DEAPP de_mrna_annotation',SQL%ROWCOUNT,stepCt,'Done');
	--stepCt := stepCt + 1;
	
	execute immediate('truncate table deapp.de_gpl_info');

	cz_write_audit(jobId,databaseName,procedureName,'Truncate table DEAPP de_gpl_info',SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;
	
	execute immediate('truncate table i2b2demodata.sample_categories');

	cz_write_audit(jobId,databaseName,procedureName,'Truncate table I2B2DEMODATA sample_categories',SQL%ROWCOUNT,stepCt,'Done');
	stepCt := stepCt + 1;
		
	--	bio_experiment, bio_clinical_trial: only insert or update columns
	--	bio_data_uid: only insert new
	--	search_secure_object: insert new

	--	Insert release trial into target tables

	insert into i2b2metadata.i2b2
	(c_hlevel
	,c_fullname
	,c_name
	,c_synonym_cd
	,c_visualattributes
	,c_totalnum
	,c_basecode
	,c_metadataxml
	,c_facttablecolumn
	,c_tablename
	,c_columnname
	,c_columndatatype
	,c_operator
	,c_dimcode
	,c_comment
	,c_tooltip
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,valuetype_cd
	,i2b2_id
	)
	select c_hlevel
		  ,c_fullname
		  ,c_name
		  ,c_synonym_cd
		  ,c_visualattributes
		  ,c_totalnum
		  ,c_basecode
		  ,c_metadataxml
		  ,c_facttablecolumn
		  ,c_tablename
		  ,c_columnname
		  ,c_columndatatype
		  ,c_operator
		  ,c_dimcode
		  ,c_comment
		  ,c_tooltip
		  ,update_date
		  ,download_date
		  ,import_date
		  ,sourcesystem_cd
		  ,valuetype_cd
		  ,i2b2_id
	from i2b2_release
	where release_study = TrialId;
	
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into i2b2demodata.concept_dimension
	(concept_cd
	,concept_path
	,name_char
	,concept_blob
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,upload_id
	,table_name
	)
	select concept_cd
		  ,concept_path
		  ,name_char
		  ,concept_blob
		 ,update_date
		  ,download_date
		  ,import_date
		  ,sourcesystem_cd
		  ,upload_id
		  ,table_name
	from concept_dimension_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into i2b2demodata.patient_dimension
	(patient_num
	,vital_status_cd
	,birth_date
	,death_date
	,sex_cd
	,age_in_years_num
	,language_cd
	,race_cd
	,marital_status_cd
	,religion_cd
	,zip_cd
	,statecityzip_path
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,upload_id
	,patient_blob
	)
	select patient_num
		  ,vital_status_cd
		  ,birth_date
		  ,death_date
		  ,sex_cd
		  ,age_in_years_num
		  ,language_cd
		  ,race_cd
		  ,marital_status_cd
		  ,religion_cd
		  ,zip_cd
		  ,statecityzip_path
		  ,update_date
		  ,download_date
		  ,import_date
		  ,sourcesystem_cd
		  ,upload_id
		  ,patient_blob
	from patient_dimension_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into I2B2DEMODATA patient_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into i2b2demodata.observation_fact
	(encounter_num
	,patient_num
	,concept_cd
	,provider_id
	,start_date
	,modifier_cd
	,valtype_cd
	,tval_char
	,nval_num
	,valueflag_cd
	,quantity_num
	,units_cd
	,end_date
	,location_cd
	,confidence_num
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,upload_id
	,observation_blob
	)
	select encounter_num
		  ,patient_num
		  ,concept_cd
		  ,provider_id
		  ,start_date
		  ,modifier_cd
		  ,valtype_cd
		  ,tval_char
		  ,nval_num
		  ,valueflag_cd
		  ,quantity_num
		  ,units_cd
		  ,end_date
		  ,location_cd
		  ,confidence_num
		  ,update_date
		  ,download_date
		  ,import_date
		  ,sourcesystem_cd
		  ,upload_id
		  ,observation_blob
	from observation_fact_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into i2b2metadata.i2b2_tags
	(path
	,tag
	,tag_type
  ,tags_idx
	)
	select path
		  ,tag
		  ,tag_type
      ,0
	from i2b2_tags_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into I2B2METADATA i2b2_tags',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
	
	insert into tm_lz.lz_src_sample_categories
	(trial_cd
	,site_cd
	,subject_cd
	,sample_cd
	,category_cd
	,category_value)
	select trial_cd
		  ,site_cd
		  ,subject_cd
		  ,sample_cd
		  ,category_cd
		  ,category_value
	from sample_categories_release
	where release_study = Trialid;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into I2B2DEMODATA sample_categories',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
		
	insert into deapp.de_subject_sample_mapping
	(patient_id
	,site_id
	,subject_id
	,subject_type
	,concept_code
	,assay_id
	,patient_uid
	,sample_type
	,assay_uid
	,trial_name
	,timepoint
	,timepoint_cd
	,sample_type_cd
	,tissue_type_cd
	,platform
	,platform_cd
	,tissue_type
	,data_uid
	,gpl_id
	,rbm_panel
	)
	select patient_id
		  ,site_id
		  ,subject_id
		  ,subject_type
		  ,concept_code
		  ,assay_id
		  ,patient_uid
		  ,sample_type
		  ,assay_uid
		  ,trial_name
		  ,timepoint
		  ,timepoint_cd
		  ,sample_type_cd
		  ,tissue_type_cd
		  ,platform
		  ,platform_cd
		  ,tissue_type
		  ,data_uid
		  ,gpl_id
		  ,rbm_panel
	from de_subj_sample_map_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP de_subject_sample_mapping',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	select count(*) into tExists
	from de_subject_mrna_data_release
	where release_study = TrialId;

	if tExists > 20000000 then
		i2b2_mrna_index_maint('DROP',jobId);

		cz_write_audit(jobId,databaseName,procedureName,'Drop indexes on DEAPP de_subject_microarray_data',0,stepCt,'Done');
		stepCt := stepCt + 1;
	else
		
		cz_write_audit(jobId,databaseName,procedureName,'Less than 20M records, index drop bypassed',0,stepCt,'Done');
		stepCt := stepCt + 1;
	end if;
  
  
  


		
		insert into deapp.DE_SUBJECT_MICROARRAY_DATA
		(trial_source
		,trial_name
		,probeset_id
		,assay_id
		,patient_id
		,raw_intensity
		,log_intensity
		,zscore
		)

		select sm.trial_name || ':' || 'STD'
			  ,sm.trial_name
			  ,sd.probeset_id
			  ,sm.assay_id
			  ,sm.patient_id
			  ,sd.raw_intensity
			  ,sd.log_intensity
			  ,sd.zscore
		from de_subj_sample_map_release sm
			,de_subject_mrna_data_release sd
		where sm.trial_name = TrialId
		  and sm.platform = 'MRNA_AFFYMETRIX'
		  and sm.assay_id = sd.assay_id;
  

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP de_subject_microarray_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	if tExists > 20000000 then
		i2b2_mrna_index_maint('Add',jobId);
	
		cz_write_audit(jobId,databaseName,procedureName,'Add indexes on DEAPP de_subject_microarray_data',0,stepCt,'Done');
		stepCt := stepCt + 1;
	end if;

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
	,data_uid
	,value
	,log_intensity
	,mean_intensity
	,stddev_intensity
	,median_intensity
	,zscore
	,rbm_panel
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
		  ,data_uid
		  ,value
		  ,log_intensity
		  ,mean_intensity
		  ,stddev_intensity
		  ,median_intensity
		  ,zscore
		  ,rbm_panel
	from de_subject_rbm_data_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into deapp.de_subject_protein_data
	(trial_name
	,component
	,intensity
	,patient_id
	,subject_id
	,gene_symbol
	,gene_id
	,assay_id
	,timepoint
	,n_value
	,mean_intensity
	,stddev_intensity
	,median_intensity
	,zscore
	)
	select trial_name
		  ,component
		  ,intensity
		  ,patient_id
		  ,subject_id
		  ,gene_symbol
		  ,gene_id
		  ,assay_id
		  ,timepoint
		  ,n_value
		  ,mean_intensity
		  ,stddev_intensity
		  ,median_intensity
		  ,zscore
	from de_subj_protein_data_release
	where release_study = TrialId;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into deapp.haploview_data
	(i2b2_id
	,jnj_id
	,father_id
	,mother_id
	,sex
	,affection_status
	,chromosome
	,gene
	,release
	,release_date
	,trial_name
	,snp_data
	)
	select i2b2_id
	,jnj_id
	,father_id
	,mother_id
	,sex
	,affection_status
	,chromosome
	,gene
	,release
	,release_date
	,trial_name
	,snp_data
	from haploview_data_release
	where release_study = TrialId;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into DEAPP haploview_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into biomart.bio_experiment
	(bio_experiment_id
	,bio_experiment_type
	,title
	,description
	,design
	,start_date
	,completion_date
	,primary_investigator
	,contact_field
	,etl_id
	,status
	,overall_design
	,accession)
	select m.bio_experiment_id
		  ,m.bio_experiment_type
	      ,m.title
		  ,m.description
		  ,m.design
		  ,m.start_date
		  ,m.completion_date
		  ,m.primary_investigator
		  ,m.contact_field
		  ,m.etl_id
		  ,m.status
		  ,m.overall_design
		  ,m.accession
	from bio_experiment_release m
	    ,i2b2metadata.i2b2 md
	where m.release_study = TrialId
	  and not exists
	      (select 1 from biomart.bio_experiment x
		   where x.accession = TrialId)
	  and not exists
	      (select 1 from biomart.bio_experiment x
		   where x.bio_experiment_id = m.bio_experiment_id)
	  and m.accession = md.sourcesystem_cd
	  and md.c_hlevel = 0;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial data in BIOMART bio_experiment',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	update biomart.bio_experiment b
	set (bio_experiment_type
	    ,title
	    ,description
		,design
		,start_date
		,completion_date
		,primary_investigator
		,contact_field
		,etl_id
		,status
		,overall_design) =
	    (select distinct m.bio_experiment_type
		       ,m.title
		       ,m.description
			   ,m.design
			   ,m.start_date
			   ,m.completion_date
			   ,m.primary_investigator
			   ,m.contact_field
			   ,m.etl_id
			   ,m.status
			   ,m.overall_design
		 from bio_experiment_release m
			 ,i2b2metadata.i2b2 md
		 where m.release_study = TrialId
		   and b.accession = m.accession
		   and md.sourcesystem_cd = TrialId
		   and md.c_hlevel = 0)
	where b.accession = TrialId
	  and exists
	      (select 1 from bio_experiment_release x
		   where x.release_study = TrialId);

	cz_write_audit(jobId,databaseName,procedureName,'Updated trial data in BIOMART bio_experiment',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into biomart.bio_clinical_trial
	(trial_number
	,study_owner
	,study_phase
	,blinding_procedure
	,studytype
	,duration_of_study_weeks
	,number_of_patients
	,number_of_sites
	,route_of_administration
	,dosing_regimen
	,group_assignment
	,type_of_control
	,completion_date
	,primary_end_points
	,secondary_end_points
	,inclusion_criteria
	,exclusion_criteria
	,subjects
	,gender_restriction_mfb
	,min_age
	,max_age
	,secondary_ids
	,bio_experiment_id
	,development_partner
	,main_findings
	,geo_platform
	,platform_name
	,search_area
	)
	select m.trial_number
          ,m.study_owner
          ,m.study_phase
          ,m.blinding_procedure
          ,m.studytype
		  ,m.duration_of_study_weeks
		  ,m.number_of_patients
		  ,m.number_of_sites
          ,m.route_of_administration
          ,m.dosing_regimen
          ,m.group_assignment
          ,m.type_of_control
          ,m.completion_date
          ,m.primary_end_points
          ,m.secondary_end_points
          ,m.inclusion_criteria
          ,m.exclusion_criteria
          ,m.subjects
          ,m.gender_restriction_mfb
		  ,m.min_age
		  ,m.max_age
          ,m.secondary_ids
          ,m.bio_experiment_id
		  ,m.development_partner
		  ,m.main_findings
		  ,m.geo_platform
		  ,m.platform_name
		  ,m.search_area
	from bio_clinical_trial_release m
		,i2b2metadata.i2b2 md
	where m.release_study = TrialId
	  and not exists
	      (select 1 from biomart.bio_clinical_trial x
		   where x.trial_number = TrialId)
	  and md.sourcesystem_cd = TrialId
	  and md.c_hlevel = 0
	  and (parse_nth_value(md.c_fullname,2,'\') = 'Clinical Trials' or
		   (parse_nth_value(md.c_fullname,2,'\') = 'Experimental Medicine Study' and substr(m.release_study,1,1) = 'C')
          );
	
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial data in BIOMART bio_clinical_trial',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	update biomart.bio_clinical_trial b
	set (study_owner
	    ,study_phase
		,blinding_procedure
		,studytype
		,duration_of_study_weeks
		,number_of_patients
		,number_of_sites
		,route_of_administration
		,dosing_regimen
		,group_assignment
		,type_of_control
		,completion_date
		,primary_end_points
		,secondary_end_points
		,inclusion_criteria
		,exclusion_criteria
		,subjects
		,gender_restriction_mfb
		,min_age
		,max_age
		,secondary_ids
		,development_partner
		,main_findings
		,geo_platform
		,platform_name
		,search_area
        ) =
		(select m.study_owner
			   ,m.study_phase
			   ,m.blinding_procedure
			   ,m.studytype
			   ,m.duration_of_study_weeks
			   ,m.number_of_patients
			   ,m.number_of_sites
			   ,m.route_of_administration
			   ,m.dosing_regimen
			   ,m.group_assignment
			   ,m.type_of_control
			   ,m.completion_date
			   ,m.primary_end_points
			   ,m.secondary_end_points
			   ,m.inclusion_criteria
			   ,m.exclusion_criteria
			   ,m.subjects
			   ,m.gender_restriction_mfb
			   ,m.min_age
			   ,m.max_age
			   ,m.secondary_ids
			   ,m.development_partner
			   ,m.main_findings
			   ,m.geo_platform
			   ,m.platform_name
			   ,m.search_area
		 from bio_clinical_trial_release m
		 where m.release_study = TrialId
		)
	where b.trial_number = TrialId
	  and exists
		  (select 1 from bio_clinical_trial_release x
		   where x.release_study = TrialId);

	cz_write_audit(jobId,databaseName,procedureName,'Updated trial data in BIOMART bio_clinical_trial',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into biomart.bio_data_uid
	(bio_data_id
	,unique_id
	,bio_data_type
	)
	select b.bio_data_id
	      ,b.unique_id
		  ,b.bio_data_type
	from bio_data_uid_release b
	where b.release_study = TrialId
	  and not exists
	      (select 1 from biomart.bio_data_uid x
		   where b.bio_data_id = x.bio_data_id);
	
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial data into BIOMART bio_data_uid',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into biomart.bio_data_compound
	(bio_data_id
	,bio_compound_id
	,etl_source
	)
	select b.bio_data_id
	      ,b.bio_compound_id
		  ,b.etl_source
	from bio_data_compound_release b
	where b.release_study = TrialId
	  and exists
	      (select 1 from biomart.bio_data_compound x
		   where b.bio_compound_id = x.bio_compound_id);

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial data into BIOMART bio_data_compound',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	stepCt := stepCt + 1;
/*
	insert into searchapp.search_secure_object
	(search_secure_object_id
	,bio_data_id
	,display_name
	,data_type
	,bio_data_unique_id
	)
	select b.search_secure_object_id
	      ,b.bio_data_id
		  ,b.display_name
		  ,b.data_type
		  ,b.bio_data_unique_id
	from search_secure_object_release b
	where b.release_study = TrialId
	  and exists
	      (select 1 from biomart.bio_experiment x
		   where b.bio_data_id = x.bio_experiment_id)
	  and not exists
	      (select 1 from searchapp.search_secure_object y
		   where b.search_secure_object_id = y.search_secure_object_id);

	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial data into SEARCHAPP search_secure_object',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
	
	--	check gotSNP and reload tables if > 0
	
	if gotSNP > 0 then

		insert into deapp.de_snp_info
		select * from de_snp_info_release;
		cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_info',SQL%ROWCOUNT,stepCt,'Done');
		commit;
		stepCt := stepCt + 1;
	
		insert into deapp.de_snp_probe
		select * from de_snp_probe_release;
		cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_probe',SQL%ROWCOUNT,stepCt,'Done');
		commit;
		stepCt := stepCt + 1;
		
		insert into deapp.de_snp_gene_map
		select * from de_snp_gene_map_release;
		cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_gene_map',SQL%ROWCOUNT,stepCt,'Done');
		commit;
		stepCt := stepCt + 1;
		
		insert into deapp.de_snp_probe_sorted_def
		select * from de_snp_probe_sort_def_release;
		cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_probe_sorted_def',SQL%ROWCOUNT,stepCt,'Done');
		commit;
		stepCt := stepCt + 1;
		
	end if;

	
	insert into deapp.de_subject_snp_dataset
	(subject_snp_dataset_id
	,dataset_name
	,concept_cd
	,platform_name
	,trial_name
	,patient_num
	,timepoint
	,subject_id
	,sample_type
	,paired_dataset_id
	,patient_gender)
	select subject_snp_dataset_id
		  ,dataset_name
		  ,concept_cd
		  ,platform_name
		  ,trial_name
		  ,patient_num
		  ,timepoint
		  ,subject_id
		  ,sample_type
		  ,paired_dataset_id
		  ,patient_gender
	from de_subject_snp_dataset_release
	where trial_name = TrialId;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_subject_snp_dataset',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
	
	insert into deapp.de_snp_data_by_patient
	(snp_data_by_patient_id
	,snp_dataset_id
	,trial_name
	,patient_num
	,chrom
	,data_by_patient_chr
	)
	select snp_data_by_patient_id
		  ,snp_dataset_id
		  ,trial_name
		  ,patient_num
		  ,chrom
		  ,data_by_patient_chr
	from de_snp_data_by_patient_release
	where trial_name = TrialId;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_data_by_patient',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into deapp.de_snp_data_dataset_loc
	(snp_data_dataset_loc_id
	,trial_name
	,snp_dataset_id
	,location)
	select snp_data_dataset_loc_id
		  ,trial_name
		  ,snp_dataset_id
		  ,location
	from de_snp_data_ds_loc_release
	where trial_name = TrialId;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_data_dataset_loc',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	insert into deapp.de_snp_data_by_probe
	(snp_data_by_probe_id
	,probe_id
	,probe_name
	,snp_id
	,snp_name
	,trial_name
	,data_by_probe
	)
	select snp_data_by_probe_id
		  ,probe_id
		  ,probe_name
		  ,snp_id
		  ,snp_name
		  ,trial_name
		  ,data_by_probe
	from de_snp_data_by_probe_release
	where trial_name = TrialId;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_snp_data_by_probe',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;	
	
	--	Load de_mrna_annotation
	
	insert into deapp.de_mrna_annotation
	select * from de_mrna_annotation_release;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_mrna_annotation',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;

	--	Load de_gpl_info
	
	insert into deapp.de_gpl_info
	select * from de_gpl_info_release;

	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into DEAPP de_gpl_info',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	stepCt := stepCt + 1;
	
	if gotSNP > 0 then
		-- Enable the SNP table constraints that were disabled prior to truncate
		execute immediate('alter table DE_SNP_INFO ENABLE constraint U_SNP_INFO_NAME;');
		execute immediate('alter table DE_SNP_PROBE ENABLE constraint U_SNP_PROBE_NAME;');
		execute immediate('alter table DE_SNP_INFO ENABLE constraint SYS_C0045667;  ');
		execute immediate('alter table DE_SNP_PROBE ENABLE constraint FK_SNP_PROBE_SNP_ID;');
		execute immediate('alter table DE_SNP_GENE_MAP ENABLE constraint FK_SNP_GENE_MAP_SNP_ID;');
		execute immediate('alter table DE_SNP_DATA_BY_PROBE ENABLE constraint FK_SNP_BY_PROBE_PROBE_ID;');
	  
		cz_write_audit(jobId,databaseName,procedureName,'Constrants enabled for SNP tables',SQL%ROWCOUNT,stepCt,'Done');
		commit;
		stepCt := stepCt + 1;
	end if;
*/     
	--	Create patient-trial, concept counts, and load security data

	i2b2_create_patient_trial(TrialId, StudyType, jobId, returnCode);
	i2b2_create_concept_counts(ontPath, jobId);
	i2b2_load_security_data(jobId);
	
	cz_write_audit(jobId,databaseName,procedureName,'End i2b2_load_from_release',0,stepCt,'Done');
	
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
 
