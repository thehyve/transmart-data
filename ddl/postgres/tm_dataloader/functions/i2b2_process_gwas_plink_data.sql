--
-- Name: i2b2_process_gwas_plink_data(character varying, character varying, character varying, numeric); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION i2b2_process_gwas_plink_data(trial_id character varying, top_node character varying, secure_study character varying DEFAULT 'N'::character varying, currentjobid numeric DEFAULT '-1'::integer) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  --Audit variables
  newJobFlag		integer;
  databaseName 	VARCHAR(100);
  procedureName 	VARCHAR(100);
  jobID 			numeric(18,0);
  stepCt 			numeric(18,0);
  rowCt			numeric(18,0);
  errorNumber		character varying;
  errorMessage	character varying;
  rtnCd			integer;

  TrialID			varchar(100);
  sourceCd		varchar(50);
  datasetId		varchar(160);

  res numeric;
  i record;
BEGIN
  TrialID := upper(trial_id);
  sourceCd := 'STD';
  datasetId := trial_id || ':' || sourceCd;

  --Set Audit Parameters
  newJobFlag := 0; -- False (Default)
  jobID := currentJobID;
  databaseName := current_schema();
  procedureName := 'i2b2_process_gwas_plink_data';


  --Audit JOB Initialization
  --If Job ID does not exist, then this is a single procedure run and we need to create it

  IF(jobID IS NULL or jobID < 1)
  THEN
    newJobFlag := 1; -- True
    select cz_start_audit (procedureName, databaseName) into jobID;
  END IF;

  stepCt := 0;
  stepCt := stepCt + 1;
  select cz_write_audit(jobId,databaseName,procedureName,'Starting ' || procedureName,0,stepCt,'Done') into rtnCd;

  select I2B2_LOAD_SAMPLES(trial_id, top_node, 'GWAS_PLINK', sourceCd, secure_study, jobID) into res;
  if res < 0 then
    return res;
  end if;

  for i in select bed, bim, fam from gwas_plink.plink_data where study_id=trial_id loop
    execute 'grant select on large object '||i.bed||' to biomart_user';
    execute 'grant select on large object '||i.bim||' to biomart_user';
    execute 'grant select on large object '||i.fam||' to biomart_user';
  end loop;

  stepCt := stepCt + 1;
  select cz_write_audit(jobId,databaseName,procedureName,'End ' || procedureName,0,stepCt,'Done') into rtnCd;

  ---Cleanup OVERALL JOB if this proc is being run standalone
  IF newJobFlag = 1
  THEN
    select cz_end_audit (jobID, 'SUCCESS') into rtnCd;
  END IF;

  return 1;
END;

$$;

