--
-- Type: PROCEDURE; Owner: TM_CZ; Name: RWG_REMOVE_STUDY
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."RWG_REMOVE_STUDY" 
(
  trialID varchar2,
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



select bio_experiment_id into V_BIO_EXP_ID from biomart.bio_experiment
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
  
  
    delete from biomart.bio_assay_analysis baa
    where baa.bio_assay_analysis_id in (
    select distinct(hmr.bio_assay_analysis_id)
  from biomart.heat_map_results hmr
  where hmr.trial_name = upper(trialID)
  );
  
      tm_cz.Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete existing records from Biomart.bio_assay_analysis',Sql%Rowcount,Stepct,'Done');
  Stepct := Stepct + 1;	
  


/***********************************/
/**** Remove Heat_map_resultes ***/
/***********************************/

/* Check if partition exist, truncate if so, create it if not */

	select count(*) into partExists
	from all_tables
	where table_name = 'HEAT_MAP_RESULTS'
	  and owner = 'BIOMART'
	  and partitioned = 'YES';

	if partExists > 0 then 
	
			--truncate partition
			sqlText := 'alter table BIOMART.HEAT_MAP_RESULTS truncate partition ' || upper(trialID);
			execute immediate(sqlText);
      
			cz_write_audit(jobId,databaseName,procedureName,'Truncate partition in BIOMART.HEAT_MAP_RESULTS',0,stepCt,'Done');
			stepCt := stepCt + 1;
      
	else
		-- table is not partitioned so just do regular delete
		
		delete from biomart.heat_map_results
		where upper(trial_name) = upper(trialID);
		cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete records for study from heat_map_results',Sql%Rowcount,Stepct,'Done');
		stepCt := stepCt + 1;	
		commit;
	end if;


        
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
 
