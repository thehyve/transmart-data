--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_RBM_ZSCORE_CALC
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_RBM_ZSCORE_CALC" 
(
  trial_id VARCHAR2
 ,currentJobID NUMBER := null
)
AS

--	JEA@20090902	Calculate ZScore for a single trial using deapp_wz.de_subject_rbm_data, delete the trial if found from deapp.de_subject_rbm_data,
--					and insert the data from deapp_wz.de_subject_rbm_data to deapp.de_subject_rbm_data
--	JEA@20100111	Added auditing
--	JEA@20100129	Changed update of deapp_wz.de_subject_rbm_data to delete/insert
--	JEA@20100304	Added assay_id to join on insert to de_subject_rbm_data 
--	Copyright ? 2009 Recombinant Data Corp.

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
	control.cz_write_audit(jobId,databaseName,procedureName,'Starting i2b2_rbm_zscore_calc',0,stepCt,'Done');

--	truncate work tables

	execute immediate('truncate table deapp_wz.tmp_subject_rbm_logs');
	execute immediate('truncate table deapp_wz.tmp_subject_rbm_calcs');
	execute immediate('truncate table deapp_wz.tmp_subject_rbm_med');
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Truncate DEAPP_WZ tmp_subject_rbm work tables',0,stepCt,'Done');
	commit;

--	insert trial with rbm data and log2 of value

	insert into deapp_wz.tmp_subject_rbm_logs 
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
	,log_intensity
	)
     select TRIAL_NAME
            ,ANTIGEN_NAME
            ,N_VALUE
            ,PATIENT_ID
            ,GENE_SYMBOL
            ,GENE_ID
            ,ASSAY_ID
            ,NORMALIZED_VALUE
            ,CONCEPT_CD
            ,TIMEPOINT
            ,VALUE
            ,log(2,VALUE) as log_intensity
     from deapp_wz.de_subject_rbm_data
     where trial_name =  TrialId 
	   and value > 0;
	 stepCt := stepCt + 1;
	 control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial data into DEAPP_WZ tmp_subject_rbm_logs',SQL%ROWCOUNT,stepCt,'Done');
	commit;
    
--	calculate mean_intensity, median_intensity, and stddev_intensity for gene/antigen

	insert into deapp_wz.tmp_subject_rbm_calcs
	(trial_name
	,gene_symbol
	,antigen_name
	,mean_intensity
	,median_intensity
	,stddev_intensity
	)
    select d.trial_name
            ,NVL(d.gene_symbol,'**NULL**') as gene_symbol
            ,d.antigen_name
            ,avg(d.log_intensity)    as mean_intensity
            ,median(d.log_intensity) as median_intensity
            ,stddev(d.log_intensity) as stddev_intensity
            from deapp_wz.tmp_subject_rbm_logs d
            group by d.trial_name, d.antigen_name, NVL(d.gene_symbol,'**NULL**');
	 stepCt := stepCt + 1;
	 control.cz_write_audit(jobId,databaseName,procedureName,'Insert intensities into DEAPP_WZ tmp_subject_rbm_calcs',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	-- calculate zscore

	insert into deapp_wz.tmp_subject_rbm_med 
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
	,log_intensity
	,value
	,mean_intensity
	,stddev_intensity
	,median_intensity
	,zscore
	)
	select d.trial_name
          ,d.antigen_name
	      ,d.n_value
	      ,d.patient_id
          ,CASE WHEN d.gene_symbol='**NULL**' THEN NULL ELSE d.gene_symbol END as gene_symbol
          ,d.gene_id
	      ,d.assay_id
	      ,d.normalized_value
	      ,d.concept_cd
	      ,d.timepoint
          ,d.log_intensity
	      ,d.value
          ,c.mean_intensity
	      ,c.stddev_intensity
	      ,c.median_intensity
          ,CASE WHEN c.stddev_intensity=0
          THEN 0 
          ELSE (d.log_intensity - c.median_intensity ) / c.stddev_intensity 
          END as zscore
          from deapp_wz.tmp_subject_rbm_logs d 
          inner join deapp_wz.tmp_subject_rbm_calcs c
          on d.trial_name=c.trial_name 
          and d.antigen_name=c.antigen_name 
          and NVL(d.gene_symbol,'**NULL**')=c.gene_symbol;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert uncapped zscore data into DEAPP_WZ tmp_subject_rbm_med',SQL%ROWCOUNT,stepCt,'Done');
    commit;
  
	--	delete trial from deapp_wz.de_subject_rbm_data
	
	delete from deapp_wz.de_subject_rbm_data
	where trial_name = TrialId;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete trial from DEAPP_WZ de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
    commit;	
	
	--	insert trial into deapp_wz.de_subject_rbm_data
	
	insert into deapp_wz.de_subject_rbm_data
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
	,case when zscore < -2.5 then -2.5
	      when zscore > 2.5 then 2.5
		  else round(zscore,5)
	 end
	from deapp_wz.tmp_subject_rbm_med;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into DEAPP_WZ de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;

--	delete any data from deapp.de_subject_rbm_data for trial

	delete deapp.de_subject_rbm_data
	where trial_name = TrialID;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Delete trial from DEAPP de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
--	insert data for trial into deapp.de_subject_rbm_data, both concept_cd and data_uid will be recast and timepoints will be curated when i2b2_process_rbm_data is run 

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
	)
	select r.trial_name
      ,r.antigen_name
	  ,r.n_value
	  ,r.patient_id
	  ,r.gene_symbol
	  ,r.gene_id
	  ,r.assay_id
	  ,r.normalized_value
	  ,r.concept_cd
	  ,r.timepoint
	  ,null
	  ,r.value
	  ,m.log_intensity
	  ,m.mean_intensity
	  ,m.stddev_intensity
	  ,m.median_intensity
	  ,r.zscore
	from deapp_wz.de_subject_rbm_data r
    ,deapp_wz.tmp_subject_rbm_med m
	where r.trial_name = TrialId
	  and r.trial_name = m.trial_name
	  and r.antigen_name = m.antigen_name
	  and r.patient_id = m.patient_id
	  and r.assay_id = m.assay_id
	  and nvl(r.gene_symbol,'**NULL**') = nvl(m.gene_symbol,'**NULL**')
	;
	 stepCt := stepCt + 1;
	 control.cz_write_audit(jobId,databaseName,procedureName,'Insert trial into DEAPP de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');
	 commit;


--	cleanup tmp_ files

   sql_txt := 'truncate table deapp_wz.tmp_subject_rbm_logs';
   execute immediate sql_txt;
   
   sql_txt := 'truncate table deapp_wz.tmp_subject_rbm_calcs';
   execute immediate sql_txt;
  
   sql_txt := 'truncate table deapp_wz.tmp_subject_rbm_med';
   execute immediate sql_txt;
   
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

/*	recreate work tables

create table deapp_wz.tmp_subject_rbm_logs as 
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
                  ,n_value as log_intensity
                  from deapp_wz.de_subject_rbm_data
                  where 1=2;

create table deapp_wz.tmp_subject_rbm_calcs as
               select trial_name
				,gene_symbol
				,antigen_name
				,log_intensity as mean_intensity
				,log_intensity as median_intensity
				,log_intensity as stddev_intensity
				from deapp_wz.tmp_subject_rbm_logs 
				where 1=2;


create table deapp_wz.tmp_subject_rbm_med as
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
                    ,log_intensity
	                ,value
                    ,log_intensity as mean_intensity
	                ,log_intensity as stddev_intensity
	                ,log_intensity as median_intensity
                    ,log_intensity as zscore
                   from deapp_wz.tmp_subject_rbm_logs
				   where 1=2;
				   
*/
 
 
 
 
/
