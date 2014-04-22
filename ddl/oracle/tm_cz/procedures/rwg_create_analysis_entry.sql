--
-- Type: PROCEDURE; Owner: TM_CZ; Name: RWG_CREATE_ANALYSIS_ENTRY
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."RWG_CREATE_ANALYSIS_ENTRY" 
(
  trialID varchar2,
  delete_flag varchar2:=null,
 currentJobID NUMBER := null
)
AS
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  
  
     Cursor Cdelete Is 
   select distinct(baa.bio_assay_analysis_id)
   from Biomart.bio_assay_analysis baa 
   where upper(baa.etl_id) like upper(trialID) || ':%' ;

    cDeleteRow cDelete%rowtype;
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
  
  cz_write_audit(jobId,databaseName,procedureName,'Start Procedure',SQL%ROWCOUNT,stepCt,'Done');
  Stepct := Stepct + 1;	
  
  -- If this flag is set to 'D', all study data from biomart.bio_assay_analysis and biomart.bio_assay_analysis_data
  if(upper(delete_flag) = 'D')
    THEN
    
    
     cz_write_audit(jobId,databaseName,procedureName,'Start Delete bio_assay_analysis_data Loop',SQL%ROWCOUNT,stepCt,'Done');
     stepCt := stepCt + 1;	
    
    For Cdeleterow In Cdelete Loop
      Delete From  biomart.bio_assay_analysis_data baad
      where baad.bio_assay_analysis_id = cDeleteRow.bio_assay_analysis_id;
      
        dbms_output.put_line('Delete count for ' || cDeleteRow.bio_assay_analysis_id || '=' || SQL%ROWCOUNT);
        
      Cz_Write_Audit(Jobid,Databasename,Procedurename,'Delete records for analysis:  ' || cDeleteRow.bio_assay_analysis_id,Sql%Rowcount,Stepct,'Done');
      stepCt := stepCt + 1;	
        
      commit;
    end loop;
    
     delete from Biomart.bio_assay_analysis baa 
     where upper(baa.etl_id) like upper(trialID) || ':%';
     
      cz_write_audit(jobId,databaseName,procedureName,'Delete existing records from Biomart.bio_assay_analysis',SQL%ROWCOUNT,stepCt,'Done');
      stepCt := stepCt + 1;	
    
  END IF;
  
  
Insert Into Biomart.Bio_Assay_Analysis 
(ANALYSIS_NAME, Short_Description,Long_Description, 
Fold_Change_Cutoff, Pvalue_Cutoff, lsmean_cutoff, 
Analysis_Method_Cd, Bio_Assay_Data_Type, 
Etl_Id, Qa_Criteria, analysis_create_date, analysis_update_date)

Select 
rwg.analysis_id,
rwg.Short_Desc,
rwg.Long_Desc,
rwg.foldchange_cutoff, pvalue_cutoff, lsmean_cutoff, --fold_chage, pvalue, lsmean cutoffs
rwg.Analysis_Type,
rwg.Data_Type,
rwg.study_id || ':RWG',
'(Abs(fold Change) > '||rwg.foldchange_cutoff ||
' OR fold_chage is null)'||
' AND pvalue < '||pvalue_cutoff||
' AND Max(LSMean) >' ||lsmean_cutoff,
sysdate,sysdate
From tm_lz.rwg_analysis rwg
where upper(rwg.study_id)=upper(trialID);
  
  
  cz_write_audit(jobId,databaseName,procedureName,'Insert records into Biomart.Bio_Assay_Analysis',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  commit;
  
  /* Update tm_lz.Rwg_Analysis with the newly created bio_assay_analysis_Id */
  update tm_lz.Rwg_Analysis rwg
set rwg.bio_assay_analysis_id = 
(select baa.bio_assay_analysis_id from Biomart.Bio_Assay_Analysis baa
where baa.analysis_name = rwg.analysis_id
and upper(baa.etl_id) like upper(trialID||':%')
and upper(rwg.study_id) like upper(trialID))
where upper(rwg.study_id) like upper(trialID);
  
  cz_write_audit(jobId,databaseName,procedureName,'Update records in tm_lz.Rwg_Analysis with bio_assay_analysis_id ',SQL%ROWCOUNT,stepCt,'Done');
  stepCt := stepCt + 1;	
  
  commit;
  
 
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
 
