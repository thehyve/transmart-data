--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_PROTEIN_ZSCORE_CALC
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_PROTEIN_ZSCORE_CALC" 
(
  trial_id VARCHAR2
 ,currentJobID NUMBER := null
)
AS

--	JEA@20100129	Calculate ZScore for a single trial using deapp_wz.de_subject_protein_data, delete the trial if found from deapp.de_subject_protein_data,
--					and insert the data from deapp_wz.de_subject_protein_data to deapp.de_subject_protein_data

-- Copyright ? 2010 Recombinant Data Corp.

  TrialID varchar2(100);
  sql_txt varchar2(2000);
  tExists number;		--	used to check if tmp_ tables exists.  If yes, then drop table
    
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  
BEGIN

  TrialID := upper(trial_id);
  
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
	control.cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_protein_zscore_calc',0,stepCt,'Done');

	--	truncate work tables
	
	execute immediate('truncate table deapp_wz.tmp_subject_protein_logs');
	execute immediate('truncate table deapp_wz.tmp_subject_protein_calcs');
	execute immediate('truncate table deapp_wz.tmp_subject_protein_med');
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Truncate DEAPP_WZ tmp_subject_protein work tables',0,stepCt,'Done');

--	insert trial with protein data and log2 of intensity

	insert into deapp_wz.tmp_subject_protein_logs 
	(trial_name
	,component
	,intensity
    ,n_value
    ,patient_id
    ,gene_symbol
    ,gene_id
    ,assay_id
    ,timepoint
    ,log_intensity
	)
     select trial_name
            ,component
			,intensity
            ,n_value
            ,patient_id
            ,gene_symbol
            ,gene_id
            ,assay_id
            ,timepoint
            ,log(2,intensity) as log_intensity
     from deapp_wz.de_subject_protein_data
     where trial_name =  TrialId 
	   and intensity > 0;
	 stepCt := stepCt + 1;
	 control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial data into DEAPP_WZ tmp_subject_protein_logs',SQL%ROWCOUNT,stepCt,'Done');
	commit;
    
--	calculate mean_intensity, median_intensity, and stddev_intensity for gene/antigen

	insert into deapp_wz.tmp_subject_protein_calcs
	(trial_name
	,gene_symbol
	,component
	,mean_intensity
	,median_intensity
	,stddev_intensity
	)
    select d.trial_name
            ,NVL(d.gene_symbol,'**NULL**') as gene_symbol
            ,d.component
            ,avg(d.log_intensity)    as mean_intensity
            ,median(d.log_intensity) as median_intensity
            ,stddev(d.log_intensity) as stddev_intensity
            from deapp_wz.tmp_subject_protein_logs d
            group by d.trial_name, d.component, NVL(d.gene_symbol,'**NULL**');
	 stepCt := stepCt + 1;
	 control.cz_write_audit(jobId,databaseName,procedureName,'Insert intensities into DEAPP_WZ tmp_subject_protein_calcs',SQL%ROWCOUNT,stepCt,'Done');
	commit;

-- calculate zscore

	insert into deapp_wz.tmp_subject_protein_med 
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
	select d.trial_name
          ,d.component
		  ,d.intensity
	      ,d.n_value
	      ,d.patient_id
          ,case when d.gene_symbol='**null**' then null else d.gene_symbol end as gene_symbol
          ,d.gene_id
	      ,d.assay_id
	      ,d.timepoint
          ,case when c.stddev_intensity=0
          then 0 
          else (d.log_intensity - c.median_intensity ) / c.stddev_intensity 
          end as zscore
    from deapp_wz.tmp_subject_protein_logs d 
    inner join deapp_wz.tmp_subject_protein_calcs c
          on d.trial_name=c.trial_name 
          and nvl(d.component,'**null**') = nvl(c.component,'**null**') 
          and nvl(d.gene_symbol,'**null**') = nvl(c.gene_symbol,'**null**');
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert uncapped zscore data into DEAPP_WZ tmp_subject_protein_med',SQL%ROWCOUNT,stepCt,'Done');
    commit;
  
	--	delete existing data from deapp_wz.de_subject_protein_data
	
	delete from deapp_wz.de_subject_protein_data
	where trial_name = Trialid;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete trial from DEAPP_WZ de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
    commit;
	
	--	insert data into deapp_wz.de_subject_protein_data
	
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
	select trial_name
		  ,component
		  ,intensity
		  ,n_value
		  ,patient_id
		  ,gene_symbol
		  ,gene_id
		  ,assay_id
		  ,timepoint
		  ,case when zscore < -2.5 then -2.5
		        when zscore > 2.5 then 2.5
			    else round(zscore,5)
		   end
	from deapp_wz.tmp_subject_protein_med;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into DEAPP_WZ de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
    commit;	
	
--	delete any data from deapp.de_subject_protein_data for trial

	delete deapp.de_subject_protein_data
	where trial_name = TrialID;
	
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete trial from DEAPP de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

--	insert data for trial into deapp.de_subject_protein_data

	insert into deapp.de_subject_protein_data
	(trial_name
	,component
	,intensity
	,n_value
	,patient_id
	,gene_symbol
	,gene_id
	,assay_id
	,timepoint
	,mean_intensity
	,stddev_intensity
	,median_intensity
	,zscore
	)
	select r.trial_name
      ,r.component
	  ,r.intensity
	  ,r.n_value
	  ,r.patient_id
	  ,r.gene_symbol
	  ,r.gene_id
	  ,r.assay_id
	  ,r.timepoint
	  ,m.mean_intensity
	  ,m.stddev_intensity
	  ,m.median_intensity
	  ,r.zscore
	from deapp_wz.de_subject_protein_data r
		,deapp_wz.tmp_subject_protein_calcs m
	where r.trial_name = TrialId
	  and r.trial_name = m.trial_name
	  and nvl(r.component,'**NULL**') = nvl(m.component,'**NULL**')
	  and nvl(r.gene_symbol,'**NULL**') = nvl(m.gene_symbol,'**NULL**')
	;
	 stepCt := stepCt + 1;
	 control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into DEAPP de_subject_protein_data',SQL%ROWCOUNT,stepCt,'Done');
	 commit;

--	cleanup tmp_ files

	execute immediate('truncate table deapp_wz.tmp_subject_protein_logs');
	execute immediate('truncate table deapp_wz.tmp_subject_protein_calcs');
	execute immediate('truncate table deapp_wz.tmp_subject_protein_med');
   
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

/*	--	recreate work tables

create table deapp_wz.tmp_subject_protein_logs as 
select trial_name
	  ,component
	  ,intensity
	  ,n_value
	  ,patient_id
	  ,gene_symbol
	  ,gene_id
	  ,assay_id
	  ,timepoint
	  ,intensity as log_intensity
from deapp_wz.de_subject_protein_data
where 1=2;

create table deapp_wz.tmp_subject_protein_calcs as
select trial_name
	  ,gene_symbol
	  ,component
	  ,log_intensity as mean_intensity
	  ,log_intensity as median_intensity
	  ,log_intensity as stddev_intensity
from deapp_wz.tmp_subject_protein_logs 
where 1=2;

create table deapp_wz.tmp_subject_protein_med as
select trial_name
	  ,component
	  ,intensity
	  ,n_value
	  ,patient_id
	  ,gene_symbol
	  ,gene_id
	  ,assay_id
	  ,timepoint
	  ,log_intensity
	  ,log_intensity as zscore
from deapp_wz.tmp_subject_protein_logs
where 1=2;

*/

 
 
 
 
/
