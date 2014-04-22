--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_COPY_TO_RELEASE
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_COPY_TO_RELEASE" 
(
  trial_id IN VARCHAR2
 ,ont_Path IN VARCHAR2	--	Use this parameter if TrialID is not contained in the i2b2/concept_dimension paths.  This will specify the string to use in filters
 ,currentJobID NUMBER := null
 )
AS

	TrialId varchar2(200);
	ontPath varchar2(200);
	msgText	varchar2(2000);

	sql_txt varchar2(2000);
	tExists number;
  vSNP number;

	--Audit variables
	newJobFlag INTEGER(1);
	databaseName VARCHAR(100);
	procedureName VARCHAR(100);
	jobID number(18,0);
	stepCt number(18,0);
  

	--	JEA@20100624	Removed gene_symbol, renamed probeset to probeset_id in de_subject_mrna_data_release
	--					added de_mrna_annotation_release
	--	JEA@20100903	Added haploview_data_release
	--	JEA@2010099		Added trial/path logging to audit log
	--	JEA@20101013	Added de_gpl_info_release table
	--	JEA@20110125	Added deapp SNP tables
	
BEGIN

	TrialID := upper(trial_id);
	ontPath := ont_path;
	
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
	cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_promote_to_stg',0,stepCt,'Done');
	
	stepCt := stepCt + 1;
	msgText := 'Extracting trial: ' || TrialId || ' path: ' || ontPath;
	cz_write_audit(jobId,databaseName,procedureName, msgText,0,stepCt,'Done');

	if TrialId = null then
		stepCt := stepCt + 1;
		cz_write_audit(jobId,databaseName,procedureName,'TrialID missing',0,stepCt,'Done');
		Return;
	end if;

	if ontPath = null or ontPath = '' or ontPath = '%'then
		stepCt := stepCt + 1;
		cz_write_audit(jobId,databaseName,procedureName,'ontPath invalid',0,stepCt,'Done');
		Return;
	End if;

	--	Delete existing data for trial
	
	delete i2b2_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  i2b2_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete observation_fact_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  observation_fact_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete patient_dimension_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  patient_dimension_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete concept_dimension_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  concept_dimension_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete de_subj_sample_map_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_subj_sample_map_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete de_subject_mrna_data_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_subject_mrna_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete de_subject_rbm_data_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_subject_rbm_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete de_subj_protein_data_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_subj_protein_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete haploview_data_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  haploview_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete i2b2_tags_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  i2b2_tags_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete bio_experiment_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  bio_experiment_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	delete bio_clinical_trial_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  bio_clinical_trial_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	delete bio_data_uid_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  bio_data_uid_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	delete bio_data_compound_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  bio_data_compound_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	delete search_secure_object_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  search_secure_object_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	--delete de_subject_snp_dataset_release
	--where release_study = TrialID;
	--stepCt := stepCt + 1;
	--cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_subject_snp_dataset_release',SQL%ROWCOUNT,stepCt,'Done');
	--commit;	
	
	delete de_snp_data_by_patient_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_snp_data_by_patient_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
		
	delete de_snp_data_ds_loc_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_snp_data_ds_loc_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	delete de_snp_data_by_probe_release
	where release_study = TrialID;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from  de_snp_data_by_probe_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	delete sample_categories_release
	where release_study = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Deleted trial from sample_categories_release',SQL%ROWCOUNT,stepCt,'Done');
	
	execute immediate('truncate table de_mrna_annotation_release');
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Truncated table  de_mrna_annotation_release',SQL%ROWCOUNT,stepCt,'Done');
	
	execute immediate('truncate table de_gpl_info_release');
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Truncated table  de_gpl_info_release',SQL%ROWCOUNT,stepCt,'Done');

		
	--	insert i2b2 records into release table

	insert into i2b2_release
	select mf.*, TrialId as release_study 
	from i2b2 mf
	where mf.c_fullname like '%' || ontPath || '%'
    and mf.c_fullname not like '%Across Trials%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  i2b2_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	insert into observation_fact_release
	select mf.*, mf.modifier_cd as release_study
	from observation_fact mf
	where mf.modifier_cd = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  observation_fact_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	insert into patient_dimension_release
	select mf.*, TrialId as release_study
	from patient_dimension mf
	where mf.sourcesystem_cd like TrialId || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  patient_dimension_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	insert into concept_dimension_release
	select mf.*, mf.sourcesystem_cd as release_study
	from concept_dimension mf
	where mf.sourcesystem_cd = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  concept_dimension_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	insert into de_subj_sample_map_release 
	select mf.*, mf.trial_name as release_study
	from deapp.de_subject_sample_mapping mf
	where mf.trial_name = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_subj_sample_map_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	

	insert into de_subject_mrna_data_release
	select mf.*, mf.trial_name as release_study
	from deapp.de_subject_microarray_data mf
	where mf.trial_name = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_subject_mrna_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;



/*
	insert into de_subject_rbm_data_release
	select mf.*, mf.trial_name as release_study
	from deapp.de_subject_rbm_data mf
	where mf.trial_name = TrialId;
	*/
  
  insert into de_subject_rbm_data_release 
        (ANTIGEN_NAME, ASSAY_ID, CONCEPT_CD, DATA_UID, GENE_ID, GENE_SYMBOL, LOG_INTENSITY, MEAN_INTENSITY, MEDIAN_INTENSITY, N_VALUE, NORMALIZED_VALUE, PATIENT_ID, RBM_PANEL, STDDEV_INTENSITY, TIMEPOINT, TRIAL_NAME, VALUE, ZSCORE, release_study)
	select ANTIGEN_NAME, ASSAY_ID, CONCEPT_CD, DATA_UID, GENE_ID, GENE_SYMBOL, LOG_INTENSITY, MEAN_INTENSITY, MEDIAN_INTENSITY, N_VALUE, NORMALIZED_VALUE, PATIENT_ID, RBM_PANEL, STDDEV_INTENSITY, TIMEPOINT, TRIAL_NAME, VALUE, ZSCORE, TrialId
	from deapp.de_subject_rbm_data mf
	where mf.trial_name = TrialId;
  
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_subject_rbm_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	insert into de_subj_protein_data_release
	select mf.*, mf.trial_name as release_study
	from deapp.de_subject_protein_data mf
	where mf.trial_name = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_subj_protein_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	insert into haploview_data_release
	select mf.*, mf.trial_name as release_study
	from deapp.haploview_data mf
	where mf.trial_name = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  haploview_data_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
		
	insert into i2b2_tags_release
	select mf.*, TrialId as release_study
	from i2b2_tags mf
	where mf.path like '%' || ontPath || '%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  i2b2_tags_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	insert into bio_experiment_release
	select mf.*, mf.accession as release_study
	from biomart.bio_experiment mf
	where mf.accession = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  bio_experiment_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	insert into bio_clinical_trial_release
	select mf.*, TrialId as release_study
	from biomart.bio_clinical_trial mf
	where mf.trial_number = TrialId;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  bio_clinical_trial_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	insert into bio_data_uid_release
	select mf.*, TrialId as release_study
	from biomart.bio_data_uid mf
	    ,biomart.bio_experiment mx
	where mx.accession = Trialid
	  and mx.bio_experiment_id = mf.bio_data_id;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  bio_data_uid_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	insert into bio_data_compound_release
	select mf.*, TrialId as release_study
	from biomart.bio_data_compound mf
	    ,biomart.bio_experiment mx
	where mx.accession = Trialid
	  and mx.bio_experiment_id = mf.bio_data_id;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  bio_data_compound_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	insert into search_secure_object_release
	select mf.*, TrialId as release_study
	from searchapp.search_secure_object mf
	    ,biomart.bio_experiment mx
	where mx.accession = Trialid
	  and mx.bio_experiment_id = mf.bio_data_id;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  search_secure_object_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--insert into de_subject_snp_dataset_release
	--select snp.*, TrialId as release_study
	--from deapp.de_subject_snp_dataset snp
	--where snp.trial_name = Trialid;
	--stepCt := stepCt + 1;
	--cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_subject_snp_dataset_release',SQL%ROWCOUNT,stepCt,'Done');
		

	insert into de_snp_data_by_patient_release
	select snp.*, TrialId as release_study
	from deapp.de_snp_data_by_patient snp
	where snp.trial_name = Trialid;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_snp_data_by_patient_release',SQL%ROWCOUNT,stepCt,'Done');



	insert into de_snp_data_ds_loc_release
	select snp.*, TrialId as release_study
	from deapp.de_snp_data_dataset_loc snp
	where snp.trial_name = Trialid;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_snp_data_ds_loc_release',SQL%ROWCOUNT,stepCt,'Done');
	
	insert into de_snp_data_by_probe_release
	select snp.*, TrialId as release_study
	from deapp.de_snp_data_by_probe snp
	where snp.trial_name = Trialid;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted trial into  de_snp_data_by_probe_release',SQL%ROWCOUNT,stepCt,'Done');

/*
	insert into de_mrna_annotation_release
	select * from deapp.de_mrna_annotation;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  de_mrna_annotation_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
  
	insert into de_gpl_info_release
	select * from deapp.de_gpl_info;
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  de_gpl_info_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
  */
    
  /* JDC: Check if the study contains SNP data and only load the following snp tables if needed */
  
  vSNP:=0;  
  select count(*)
	into vSNP
	from de_snp_data_by_probe_release
	where release_study = TrialId;
  
  
	IF vSNP > 0 THEN     
      

    execute immediate('truncate table de_snp_info_release');
	
    insert into de_snp_info_release
    select * from deapp.de_snp_info;
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  de_snp_info_release',SQL%ROWCOUNT,stepCt,'Done');
    commit;
    
	execute immediate('truncate table de_snp_probe_release');
	   
    insert into de_snp_probe_release
    SELECT * FROM DEAPP.DE_SNP_PROBE;
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  de_snp_probe_release',SQL%ROWCOUNT,stepCt,'Done');
    commit;
    
	execute immediate('truncate table de_snp_gene_map_release');
	    
    insert into de_snp_gene_map_release
    select * from deapp.de_snp_gene_map;
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  de_snp_gene_map_release',SQL%ROWCOUNT,stepCt,'Done');
    commit;
    
	execute immediate('truncate table de_snp_probe_sort_def_release');
	    
    insert into de_snp_probe_sort_def_release
    select * from deapp.de_snp_probe_sorted_def;
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  de_snp_probe_sort_def_release',SQL%ROWCOUNT,stepCt,'Done');
    commit;
    
  end if;
  
  
  
	insert into sample_categories_release
	select sc.*, TrialId as release_study
    from lz_src_sample_categories sc
	where trial_cd = TrialId;
	
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Inserted data into  sample_categories_release',SQL%ROWCOUNT,stepCt,'Done');
	commit;
   
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'End i2b2_promote_to_stg',0,stepCt,'Done');

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

/*	Create release tables

	create table i2b2_release as
	select x.*, x.sourcesystem_cd as release_study
	from i2b2 x
	where 1=2'

	create table observation_fact_release as
	select x.*, x.modifier_cd as release_study
	from observation_fact x
	where 1=2	

	create table patient_dimension_release as
	select x.*, x.sourcesystem_cd as release_study 
	from patient_dimension x
	where 1=2

	create table concept_dimension_release as
	select x.*, x.sourcesystem_cd as release_study 
	from concept_dimension x
	where 1=2
	
	create table de_subj_sample_map_release as
	select x.*, x.trial_name as release_study
	from deapp.de_subject_sample_mapping x
	where 1=2
	
	create table de_subject_mrna_data_release as
	select x.*, x.trial_name as release_study 
	from deapp.de_subject_microarray_data x
	where 1=2
	
	create table de_subject_rbm_data_release as
	select x.*, x.trial_name as release_study 
	from deapp.de_subject_rbm_data x
	where 1=2
	
	create table de_subj_protein_data_release as
	select x.*, x.trial_name as release_study
	from deapp.de_subject_protein_data x
	where 1=2
	
	create table i2b2_tags_release as
	select x.*, x.path as release_study 
	from i2b2_tags x
	where 1=2
	
	create table bio_experiment_release as
	select x.*, x.accession as release_study 
	from biomart.bio_experiment x
	where 1=2
	
	create table bio_clinical_trial_release as
	select x.*, x.trial_number as release_study 
	from biomart.bio_clinical_trial x
	where 1=2
	
	create table bio_data_uid_release as
	select x.*, x.unique_id as release_study 
	from biomart.bio_data_uid x
	where 1=2
	
	create table bio_data_compound_release as
	select c.*, b.accession as release_study 
	from biomart.bio_data_compound c
		,biomart.bio_experiment b
	where 1=2
	
	create table search_secure_object_release as
	select c.*, b.accession as release_study
	from searchapp.search_secure_object c
	    ,biomart.bio_experiment b
	where 1=2
	
*/
/
