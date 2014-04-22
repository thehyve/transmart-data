--
-- Type: PROCEDURE; Owner: TM_CZ; Name: RWG_LOAD_FROM_DEV
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."RWG_LOAD_FROM_DEV" 
(
  trialID varchar2,
  updateRefData integer := 0,
  currentJobID NUMBER := null
)
AS
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  
  sqlText varchar(500);
  partExists integer(1);
  EXPERIMENT_ID_MISSING EXCEPTION;
  
  V_BIO_EXP_ID number(18,0);
   
  
    cursor cInsert is 
 select distinct(dev.bio_assay_analysis_id) 
 from   BIOMART.bio_analysis_cohort_xref@DEVLINK dev
 where upper(dev.study_id) = upper(trialID);    

 cInsertRow cInsert%rowtype;
  
    
BEGIN


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
  
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Start Procedure',SQL%ROWCOUNT,stepCt,'Done');
  Stepct := Stepct + 1;	




select bio_experiment_id into V_BIO_EXP_ID from biomart.bio_experiment@DEVLINK
where upper(accession) like upper(trialID);

tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Retreived exp id ' ||V_BIO_EXP_ID || ' for trial ' || upper(trialID),Sql%Rowcount,Stepct,'Done');
Stepct := Stepct + 1;	


--check that the experiment id exists
if (V_BIO_EXP_ID < 0)
THEN
 RAISE EXPERIMENT_ID_MISSING;
END IF;
 



/************* Delete existing records for study ******************/

    
    delete from biomart.bio_analysis_attribute_lineage baal 
    where baal.bio_analysis_attribute_id in (select baa.bio_analysis_attribute_id 
    from biomart.bio_analysis_attribute baa
  where upper(baa.study_id) = upper(trialID)) ;
  
    tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_analysis_attribute_lineage',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
   
  delete from biomart.bio_analysis_attribute baa
  where upper(baa.study_id) = upper(trialID);
  
    tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_analysis_attribute',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
  
    delete from biomart.bio_analysis_cohort_xref bacx
  where upper(bacx.study_id) = upper(trialID);
  
    tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_analysis_cohort_xref',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
  
    delete from biomart.bio_cohort_exp_xref bcex
  where upper(bcex.study_id) = upper(trialID);
  
    tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_cohort_exp_xref',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
  
    delete from biomart.bio_assay_cohort bac
  where upper(bac.study_id) = upper(trialID);
  
    tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_assay_cohort',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
 
  
  delete from biomart.bio_assay_analysis_data baad
  where baad.bio_experiment_id = V_BIO_EXP_ID;
  
      tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_assay_analysis_data',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
  
  /* because the data from bio_assay_analysis_data is deleted first, need to find the
  bio_assay_analysis_ids to delete by referring back to dev */
  delete from biomart.bio_assay_analysis baa
  where baa.bio_assay_analysis_id in (select devbaa.bio_assay_analysis_id 
  from biomart.bio_assay_analysis@DEVLINK devbaa, biomart.bio_assay_analysis_data@DEVLINK devbaad
  where devbaa.bio_assay_analysis_id = devbaad.bio_assay_analysis_id
  and devbaad.bio_experiment_id =V_BIO_EXP_ID);
  
      tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_assay_analysis',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
  
  
/*************************************************/
  


/************   Update Reference data ***************/

if (updateRefData = 1)
THEN


  insert into biomart.bio_assay_feature_group 
  select * from biomart.bio_assay_feature_group@DEVLINK dev
  where dev.bio_assay_feature_group_id not in 
  (select bafg.bio_assay_feature_group_id 
  from biomart.bio_assay_feature_group bafg);
  
        Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_assay_feature_group',SQL%ROWCOUNT,stepCt,'Done');
        commit;					
  
  
  insert into biomart.bio_marker
  select * from biomart.bio_marker@DEVLINK dev 
  where dev.bio_marker_id not in
  (select bm.bio_marker_id from biomart.bio_marker bm);
  
        Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_marker',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
        

insert into biomart.bio_data_correl_descr
select * from biomart.bio_data_correl_descr@DEVLINK dev 
where dev.bio_data_correl_descr_id not in (
select bdcd.bio_data_correl_descr_id 
from biomart.bio_data_correl_descr bdcd);
        
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_data_correl_descr',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
        
                
    insert into biomart.bio_data_correlation
  select * from biomart.bio_data_correlation@DEVLINK dev
  where dev.bio_data_id > 
  (select max(bdc.bio_data_id) 
  from biomart.bio_data_correlation bdc);
  
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_data_correlation',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
        
        
  /* NOTE: This statement will not update changes to existing bio_assay_feature_group_ids, only new IDs */
  insert into biomart.bio_assay_data_annotation
  select * from biomart.bio_assay_data_annotation@DEVLINK dev
  where dev.bio_assay_feature_group_id > 
  (select max(bada1.bio_assay_feature_group_id) from biomart.bio_assay_data_annotation bada1);
  
        Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_assay_data_annotation',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
        

   insert into biomart.bio_asy_analysis_pltfm
   select * from biomart.bio_asy_analysis_pltfm@DEVLINK dev
  where dev.bio_asy_analysis_pltfm_id not in 
  (select baap.bio_asy_analysis_pltfm_id from  biomart.bio_asy_analysis_pltfm baap);
  
        Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_asy_analysis_pltfm',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
        
  
END IF;

/*** End Update Reference data ***/

 
  
  insert into searchapp.search_keyword
  select * from searchapp.search_keyword@DEVLINK dev
  where dev.SEARCH_KEYWORD_ID not in (
  select sk.SEARCH_KEYWORD_ID from searchapp.search_keyword sk)
  and dev.UNIQUE_ID || dev.DATA_CATEGORY not in 
  ( select sk2.UNIQUE_ID || sk2.DATA_CATEGORY from searchapp.search_keyword sk2);
           
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into searchapp.search_keyword',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
  
  
  /* This should be revised later - the second "in" clause should not be needed
   but has been added due to data issues between dev/qa */
  insert into searchapp.search_keyword_term 
    select * from searchapp.search_keyword_term@DEVLINK dev
  where dev.search_keyword_term_id not in (
  select skt.search_keyword_term_id 
  from searchapp.search_keyword_term skt)
  and dev.search_keyword_id  in (select sk.search_keyword_id from searchapp.search_keyword sk);
  
  Stepct := Stepct + 1;
  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into searchapp.search_keyword_term',SQL%ROWCOUNT,stepCt,'Done');
  commit;	
  
  
  


  For cInsertRow In cInsert Loop 
      
      insert into biomart.bio_assay_analysis (ANALYSIS_NAME,SHORT_DESCRIPTION,ANALYSIS_CREATE_DATE,ANALYST_ID,BIO_ASSAY_ANALYSIS_ID,ANALYSIS_VERSION,
      FOLD_CHANGE_CUTOFF,PVALUE_CUTOFF,RVALUE_CUTOFF,BIO_ASY_ANALYSIS_PLTFM_ID,BIO_SOURCE_IMPORT_ID,
      ANALYSIS_TYPE,ANALYST_NAME,ANALYSIS_METHOD_CD,BIO_ASSAY_DATA_TYPE,ETL_ID,LONG_DESCRIPTION,QA_CRITERIA,
      DATA_COUNT,TEA_DATA_COUNT,ANALYSIS_UPDATE_DATE,LSMEAN_CUTOFF)
      
      select ANALYSIS_NAME,SHORT_DESCRIPTION,ANALYSIS_CREATE_DATE,ANALYST_ID,BIO_ASSAY_ANALYSIS_ID,ANALYSIS_VERSION,
      FOLD_CHANGE_CUTOFF,PVALUE_CUTOFF,RVALUE_CUTOFF,BIO_ASY_ANALYSIS_PLTFM_ID,BIO_SOURCE_IMPORT_ID,
      ANALYSIS_TYPE,ANALYST_NAME,ANALYSIS_METHOD_CD,BIO_ASSAY_DATA_TYPE,ETL_ID,LONG_DESCRIPTION,QA_CRITERIA,
      DATA_COUNT,TEA_DATA_COUNT,sysdate,LSMEAN_CUTOFF
      from biomart.bio_assay_analysis@DEVLINK dev2
      where dev2.bio_assay_analysis_id = cInsertRow.bio_assay_analysis_id;   
      
      tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Insert bio_assay_analysis records for  ' || cInsertRow.bio_assay_analysis_id,Sql%Rowcount,Stepct,'Done');
      stepCt := stepCt + 1;	
         
      commit;
    

      insert into biomart.bio_assay_analysis_data
      select * 
      from biomart.bio_assay_analysis_data@DEVLINK dev
      where dev.bio_assay_analysis_id = cInsertRow.bio_assay_analysis_id;  
      
      Stepct := Stepct + 1;
           tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Insert bio_assay_analysis_data records for  ' || cInsertRow.bio_assay_analysis_id,Sql%Rowcount,Stepct,'Done');
      commit;			

  end loop;





insert into biomart.bio_analysis_attribute
   select * from biomart.bio_analysis_attribute@DEVLINK dev
  where upper(dev.study_id) = upper(trialID);
         
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_analysis_attribute',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
  
  
  insert into biomart.bio_analysis_attribute_lineage
   select * from biomart.bio_analysis_attribute_lineage@DEVLINK dev
  where dev.bio_analysis_attribute_id in (
    select dev2.bio_analysis_attribute_id 
    from biomart.bio_analysis_attribute@DEVLINK dev2
    where upper(dev2.study_id) = upper(trialID) );
           
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_analysis_attribute_lineage',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
    

insert into biomart.bio_analysis_cohort_xref
   select * from biomart.bio_analysis_cohort_xref@DEVLINK dev
  where upper(dev.study_id) = upper(trialID);
           
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_analysis_cohort_xref',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
  
  
insert into biomart.bio_cohort_exp_xref
   select * from biomart.bio_cohort_exp_xref@DEVLINK dev
  where upper(dev.study_id) = upper(trialID);
           
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_cohort_exp_xref',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
  
  
  insert into biomart.bio_assay_cohort
   select * from biomart.bio_assay_cohort@DEVLINK dev
  where upper(dev.study_id) = upper(trialID);
           
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_assay_cohort',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
  
   
   
  

insert into searchapp.search_taxonomy
select * from searchapp.search_taxonomy@DEVLINK dev
where dev.term_id not in (
  select st.term_id 
  from searchapp.search_taxonomy st);
           
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into searchapp.search_taxonomy',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
  
  
insert into searchapp.search_taxonomy_rels
select * from searchapp.search_taxonomy_rels@DEVLINK dev
where dev.search_taxonomy_rels_id not in (
  select str.search_taxonomy_rels_id 
  from searchapp.search_taxonomy_rels str);
         
          Stepct := Stepct + 1;
        tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into searchapp.search_taxonomy_rels',SQL%ROWCOUNT,stepCt,'Done');
        commit;	
        
        

/* non-clinical studies (in-vivo/in-vitro) will not get loaded to this table
during the standard ETL process for DSE studies, but this is needed for the 
RWG results view. This might change in future releases, and if so, this will be removed */
insert into biomart.bio_clinical_trial (TRIAL_NUMBER,STUDY_OWNER,STUDY_PHASE,BLINDING_PROCEDURE,
STUDYTYPE,DURATION_OF_STUDY_WEEKS,NUMBER_OF_PATIENTS,NUMBER_OF_SITES,
ROUTE_OF_ADMINISTRATION,DOSING_REGIMEN,GROUP_ASSIGNMENT,TYPE_OF_CONTROL,
COMPLETION_DATE,PRIMARY_END_POINTS,SECONDARY_END_POINTS,
SUBJECTS,GENDER_RESTRICTION_MFB,MIN_AGE,MAX_AGE,
SECONDARY_IDS,BIO_EXPERIMENT_ID,DEVELOPMENT_PARTNER,
GEO_PLATFORM,MAIN_FINDINGS,PLATFORM_NAME,SEARCH_AREA)
select TRIAL_NUMBER,STUDY_OWNER,STUDY_PHASE,BLINDING_PROCEDURE,
STUDYTYPE,DURATION_OF_STUDY_WEEKS,NUMBER_OF_PATIENTS,NUMBER_OF_SITES,
ROUTE_OF_ADMINISTRATION,DOSING_REGIMEN,GROUP_ASSIGNMENT,TYPE_OF_CONTROL,
COMPLETION_DATE,PRIMARY_END_POINTS,SECONDARY_END_POINTS,
SUBJECTS,GENDER_RESTRICTION_MFB,MIN_AGE,MAX_AGE,
SECONDARY_IDS,BIO_EXPERIMENT_ID,DEVELOPMENT_PARTNER,
GEO_PLATFORM,MAIN_FINDINGS,PLATFORM_NAME,SEARCH_AREA
 from biomart.bio_clinical_trial@DEVLINK dev
where dev.trial_number not in 
(select bct.trial_number from biomart.bio_clinical_trial bct);

Stepct := Stepct + 1;
tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Insert into biomart.bio_clinical_trial',SQL%ROWCOUNT,stepCt,'Done');
commit;	



/***********************************/
/**** Populate Heat_map_resultes ***/
/***********************************/

/* Check if partition exist, truncate if so, create it if not */

	select count(*) into partExists
	from all_tables
	where table_name = 'HEAT_MAP_RESULTS'
	  and owner = 'BIOMART'
	  and partitioned = 'YES';

	if partExists > 0 then 
	
	--	check if partition exists

		select count(*) 
		into partExists
		from all_tab_partitions
		where table_name = 'HEAT_MAP_RESULTS'
		and table_owner = 'BIOMART'
		and partition_name = upper(trialID);

		if partExists = 0 then
			--	needed to add partition to table
			sqlText := 'alter table BIOMART.HEAT_MAP_RESULTS  add PARTITION "' || upper(trialID) || '"  VALUES (' || '''' || upper(trialID) || '''' || ') ' ||
					'PCTFREE 0 PCTUSED 40 INITRANS 1 MAXTRANS 255  NOLOGGING ' ||
				   'STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 ' ||
				   'PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT) ';

			execute immediate(sqlText);
			cz_write_audit(jobId,databaseName,procedureName,'Adding partition to BIOMART.HEAT_MAP_RESULTS ',0,stepCt,'Done');
			stepCt := stepCt + 1;

		else 
			--truncate partition
			sqlText := 'alter table BIOMART.HEAT_MAP_RESULTS truncate partition ' || upper(trialID);
			execute immediate(sqlText);
      
			cz_write_audit(jobId,databaseName,procedureName,'Truncate partition in BIOMART.HEAT_MAP_RESULTS',0,stepCt,'Done');
			stepCt := stepCt + 1;
      
		end if;
	else
		-- table is not partitioned so just do regular delete
		
		delete from biomart.heat_map_results
		where upper(trial_name) = upper(trialID);
		cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete records for study from heat_map_results',Sql%Rowcount,Stepct,'Done');
		stepCt := stepCt + 1;	
		commit;
	end if;


/* Populate the partition from DEV */
  For cInsertRow In cInsert Loop
    insert into biomart.heat_map_results
    select * from biomart.heat_map_results@DEVLINK dev
    where upper(dev.trial_name) = upper(trialID)
    and dev.bio_assay_analysis_id = cInsertRow.bio_assay_analysis_id;
    
    tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Insert heat_map_results records for  ' || cInsertRow.bio_assay_analysis_id,Sql%Rowcount,Stepct,'Done');
    stepCt := stepCt + 1;	
      
    commit;
  end loop;

        

  tm_cz.cz_write_audit(jobId,databaseName,procedureName,'End Procedure',SQL%ROWCOUNT,stepCt,'Done');
  Stepct := Stepct + 1;	


 
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
