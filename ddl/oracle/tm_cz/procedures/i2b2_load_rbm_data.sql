--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_LOAD_RBM_DATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_LOAD_RBM_DATA" 
(
  trial_id VARCHAR2
 ,rbm_type CHAR --Z or O (Z for Zscore, O for Observed value)
 ,currentJobID NUMBER := null
)
AS
--PROCEDURE TO LOAD THE DEAPP SAMPLE MAPPING TABLE AND I2B2 TREE WITH RBM DATA
--KCR: 06-25-2009
--RBM DATA SHOULD HAVE A ZSCORE AND OBSERVER VALUE. THESE SHOULD BOTH APPEAR.
--IN GENERAL THE SAMPLE MAPPING TABLE WILL HAVE 2 RECORDS FOR EACH RECORD ON THE RBM TABLE.
--1 FOR ZSCORE, 1 FOR OBSERVED.
--JOIN IS ON THE DATA_UID (UNIQUE ON RBM DATA, BUT NOT ON THE SAMPLE MAPPING)
--THE FOLLOWING FIELDS SHOULD MAKE THE RBM RECORDS UNIQUE:
  --TRIAL NAME, TIMEPOINT, ANTIGEN NAME, PATIENT ID
--FOR I2B2, DATA IS GROUPED BY CATEOGRY, SO PATIENT ID IS NOT USED WHEN GENERATING THE CONCEPT CODE.
  --Key: TRIAL NAME, TIMEPOINT, ANTIGEN NAME
  --The concept codes will also be differentiated by Zscore or Observed Value
  
  --	JEA@20090908	Changed data_uid to trial_name || '-RBM-' || timepoint || '-' || substr(antigen_name,1, 20) || '-' || patient_id so that it remains the same
  --					regardless of Observed/Z Score, concept_cd still has RBMType as part of string
  --	JEA@20091118	Added auditing
  --	JEA@20100201	Renamed to I2B2_LOAD_RBM_DATA from I2B2_PROCESS_RBM_DATA for consistency amoung mRNA, RBM, and protein load procedures

  TrialID varchar2(100);
  RBMType char(1);
  RootNode VARCHAR2(100);
  pExists number;
  rbmName varchar2(20);
    
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);


BEGIN
  TrialID := upper(trial_id);
  RBMType := upper(rbm_type);
  
 
  
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
  control.cz_write_audit(jobId,databaseName,procedureName,'Start i2b2_load_rbm_data',0,stepCt,'Done');
  
    --Quit if no valid type
  if RBMType NOT IN ('Z', 'O') then
    stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Invalid rbmType, must be O or Z',0,stepCt,'Done');
    RETURN;
  end if;  
  
  if RBMType = 'O' then
     rbmName := 'Observed';
  else
	  rbmName := 'Z Score';
  end if;
  
  --Determine root value of I2B2: Could be Clinical or Experimental
  select parse_nth_value(c_fullname, 2, '\') into RootNode
  from i2b2
  where c_name = TrialID;

  --if Root Node is null, then add a root node as a clinical trial as a default.
  if RootNode is null then  
    i2b2_add_node(TrialID, '\Clinical Trials\' || TrialID || '\', TrialID, jobID);
    RootNode := 'Clinical Trials';
  end if;

  --Cleanup any existing data
  delete 
    from DE_SUBJECT_SAMPLE_MAPPING 
    where trial_name = TrialID 
      and concept_code like '%' || TrialID || '%-' || RBMType  || '-%'; --Making sure only The ZScore or Observed gets deleted for RBM Data
  stepCt := stepCt + 1;
  control.cz_write_audit(jobId,databaseName,procedureName,'Delete data for trial from DEAPP de_subject_sample_mapping',SQL%ROWCOUNT,stepCt,'Done');
	
  commit;

  --	check if RBM node exists, if not add (first time adding RBM data)
  
  select count(*) into pExists
  from i2b2
  where c_fullname = '\' || RootNode || '\'|| TrialID || '\Biomarker Data\Protein\RBM\';
  
  if pexists = 0 then
	 i2b2_add_node(trialID, '\' || RootNode || '\' || trialID || '\Biomarker Data\Protein\RBM\', 'RBM', jobID);
     stepCt := stepCt + 1;
     control.cz_write_audit(jobId,databaseName,procedureName,'Added RBM node for trial in I2B2METADATA i2b2',0,stepCt,'Done');
	 i2b2_fill_in_tree(TrialId, trialID, '\' || RootNode || '\' || trialID || '\Biomarker Data\');
  end if;

    --	check if RBMType node exists, if yes, then delete existing data
	
  select count(*) into pExists
  from i2b2
  where c_fullname = '\' || RootNode || '\'|| TrialID || '\Biomarker Data\Protein\RBM\' || rbmName || '\';
  
  if pExists != 0 then
  --This deletes all i2b2, concept_dimension, and observation_fact records wher the path starts with the passed paramenter
	i2b2_delete_all_nodes('\' || RootNode || '\'|| TrialID || '\Biomarker Data\Protein\RBM\' || rbmName || '\', jobID);
	stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Delete existing RBMType data for trial in I2B2METADATA i2b2',0,stepCt,'Done');
  end if;

  --Create value for DATA_UID and concept_cd
  --Only taking first 20 Characters for ANTIGEN NAME because I2B2 has a 50 char limit on concept_cd
  --MUST BE Distinct on this table.
  
  update de_subject_rbm_data
    set data_uid = replace(trial_name || '-RBM-' || timepoint || '-' || substr(antigen_name,1, 20) || '-' || patient_id,' ','')
	   ,concept_cd = replace(trial_name || '-' || RBMType || '-' || timepoint || '-' || substr(antigen_name,1, 20),' ','')
    where trial_name = TrialID;
  stepCt := stepCt + 1;
  control.cz_write_audit(jobId,databaseName,procedureName,'Update data_uid and concept_cd in de_subject_rbm_data',SQL%ROWCOUNT,stepCt,'Done');

  commit;

/*  combined into single update pass
--Update concept Code with the correct value of data_uid minus the patient info
  update de_subject_rbm_data
    set concept_cd = trial_name || '-' || RBMType || '-' || timepoint || '-' || substr(antigen_name,1, 20)
    where trial_name = TrialID;
  commit;

  --Trim out any spaces
  update de_subject_rbm_data
    set data_uid = replace(data_uid, ' ', ''),
    concept_cd = replace(concept_cd, ' ', '')
    where trial_name = TrialID;
  commit;
*/


  --update RBM SAMPLE MAPPING TABLE FOR TREE NODE ROLLUP
  --NEED TO MAP ALL OF THE CONCEPT CODES INTO THE TABLE
  --HIERARCHY IS:
  --1: --TRIAL\BIOMARKER DATA\PROTEIN\RBM\ = platform_cd
  --3: --TRIAL\BIOMARKER DATA\PROTEIN\RBM\Observered or ZScore\Specific Week\ = timepoint_cd
  --4: --TRIAL\BIOMARKER DATA\PROTEIN\RBM\Observered or ZScore\Specific Week\Antigene\ = concept_code

  --Load the DE_SUBJECT_SAMPLE_MAPPING
  --MAPPING: (1 to 1 relationship for RBM)
  --CONCEPT_CODE    = trial_name || 'ZSc-' || timepoint || '-' || antigen_name  (Group patient for I2B2)
                      --NOTE: ZSc = Z-score. Would be Obs for Observered
  --PATIENT_ID      = RBM.PATIENT_ID (SAME AS ID ON THE PATIENT_DIMENSION)
  --TRIAL_NAME      = RBM.TRIAL_NAME
  --TIMEPOINT       = RBM.TIMEPOINT
  --ASSAY_ID        = RBM.ASSAY_ID
  --PLATFORM        = "RBM"
  --PLATFORM_CD     = trial_name || 'RBM' 
  --TISSUE_TYPE     = "Serum"
  --SITE_ID         = NULL
  --SUBJECT_ID      = NULL
  --SUBJECT_TYPE    = NULL
  --PATIENT_UID     = NULL
  --SAMPLE_TYPE     = NULL
  --ASSAY_UID       = NULL
  --TIMEPOINT_CD    = trial_name || 'RBM' || '-' || RBMType || '-' || timepoint
  --SAMPLE_TYPE_CD  = trial_name || 'RBM' || '-' || RBMType
  --TISSUE_TYPE_CD  = NULL
  
  INSERT
  INTO DE_SUBJECT_SAMPLE_MAPPING
    (
      DATA_UID,  
      CONCEPT_CODE,
      PATIENT_ID,
      TRIAL_NAME,
      TIMEPOINT,
      ASSAY_ID,
      PLATFORM,
      PLATFORM_CD,
      timepoint_cd,
      TISSUE_TYPE
    )
  select distinct 
    a.data_uid,
    a.concept_cd,
    a.patient_id,
    a.trial_name,
    a.timepoint,
    a.assay_id,
    'RBM',  
    a.trial_name || ':RBM',
    a.trial_name || ':RBM:' || RBMType || ':' || a.timepoint,
    'Serum'
  from
    de_subject_rbm_data a
    --Joining to Pat_dim to ensure the ID's match. If not I2B2 won't work.
  join
    patient_dimension b
  on
    a.patient_id = b.patient_num
    where a.trial_name = TrialID; 
  stepCt := stepCt + 1;
  control.cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial into DEAPP de_subject_sample_mapping',SQL%ROWCOUNT,stepCt,'Done');

  commit;

  --Build Dataset Explorer Records:
    --need to build out specific levels of the tree individually
    --because the concept_cd must be specifically assigned at each level

/*	RBM node done at start of procedure

    --RBM NODE
    --CONCEPT_DIMENSION
    INSERT INTO CONCEPT_DIMENSION
      (CONCEPT_CD, CONCEPT_PATH, NAME_CHAR,  UPDATE_DATE,  DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, TABLE_NAME)
    select distinct
      a.platform_cd,
      '\' || RootNode || '\' || a.trial_name || '\Biomarker Data\Protein\RBM\',
      'RBM',
      sysdate,
      sysdate,
      sysdate,
      a.Trial_name,
      'CONCEPT_DIMENSION'
    from 
      de_subject_sample_mapping a
    where a.trial_name = TrialID 
      and a.platform = 'RBM';
    Commit;
*/
        
    --TIME POINTS
    --CONCEPT_DIMENSION
    INSERT INTO CONCEPT_DIMENSION
      (CONCEPT_CD, CONCEPT_PATH, NAME_CHAR,  UPDATE_DATE,  DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, TABLE_NAME)
    select distinct
      a.timepoint_cd,
      case 
        when RBMType = 'Z' then
          '\' || RootNode || '\' || a.trial_name || '\Biomarker Data\Protein\RBM\Z Score\' || timepoint || '\'
        when RBMType = 'O' then
          '\' || RootNode || '\' || a.trial_name || '\Biomarker Data\Protein\RBM\Observed\' || timepoint || '\'
      end,
      timepoint,
      sysdate,
      sysdate,
      sysdate,
      a.Trial_name,
      'CONCEPT_DIMENSION'
    from 
      de_subject_sample_mapping a
    where a.trial_name = TrialID 
      and a.platform = 'RBM'
      and a.concept_code like '%-' || RBMType || '-%';
    stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Insert data for RBMType and timepoint into I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');

    Commit;

  --Node Path will be: 
  --Clinical Trial + Trial_name + Biomarker Data + Protein-RBM + timepoint + antigen_name
    INSERT INTO CONCEPT_DIMENSION
      (CONCEPT_CD, CONCEPT_PATH, NAME_CHAR,  UPDATE_DATE,  DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, TABLE_NAME)
    select distinct
      a.concept_cd,
      case 
        when RBMType = 'Z' then
          '\' || RootNode || '\' || a.trial_name || '\Biomarker Data\Protein\RBM\Z Score\' || a.timepoint || '\' || a.antigen_name || '\'
        when RBMType = 'O' then
          '\' || RootNode || '\' || a.trial_name || '\Biomarker Data\Protein\RBM\Observed\' || a.timepoint || '\' || a.antigen_name || '\'
      end,
      a.antigen_name,
      sysdate,
      sysdate,
      sysdate,
      a.Trial_name,
      'CONCEPT_DIMENSION'
    from 
      de_subject_rbm_data a
    where a.trial_name = TrialID 
      and a.concept_cd like '%' || a.trial_name || '%-' || RBMType  || '-%'; --Making sure only The ZScore or Observed gets added for RBM Data
    stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Insert data for RBMType, timepoint and antigen into I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');

    Commit;
         
  --OBSERVATION_FACT
  INSERT
  INTO OBSERVATION_FACT
    (
      PATIENT_NUM,
      CONCEPT_CD,
      MODIFIER_CD,
      VALTYPE_CD,
      TVAL_CHAR,
      NVAL_NUM,
      SOURCESYSTEM_CD,
      IMPORT_DATE,
      VALUEFLAG_CD,
      PROVIDER_ID,
      LOCATION_CD,
      UNITS_CD
    )
/*
    select distinct
      a.patient_id,
      a.concept_cd,
      a.trial_name,
      'N', -- Numeric data type
      'E',  --Stands for Equals for numeric types
      case 
        when RBMType = 'Z' then
          a.zscore
        when RBMType = 'O' then
          a.value
      end,
      a.trial_name, 
      sysdate, 
      '@',
      '@',
      '@',
      '' -- no units available
    from de_subject_rbm_data a
    where a.trial_name = TrialID 
      and a.concept_cd like '%' || TrialID || '%-' || RBMType  || '-%' --Making sure only The ZScore or Observed gets deleted for RBM Data
      and a.value is not null
      and a.zscore is not null;
  */
    --WORKAROUND TO TAKE AVERAGE SCORE
    select
      a.patient_id,
      a.concept_cd,
      a.trial_name,
      'N', -- Numeric data type
      'E',  --Stands for Equals for numeric types
      case 
        when RBMType = 'Z' then
          AVG(a.zscore)
        when RBMType = 'O' then
          AVG(a.value)
      end,
      a.trial_name, 
      sysdate, 
      '@',
      '@',
      '@',
      '' -- no units available
    from deapp.de_subject_rbm_data a
    where a.trial_name = TrialID 
      and a.concept_cd like '%' || TrialID || '%-' || RBMType  || '-%' --Making sure only The ZScore or Observed gets deleted for RBM Data
      and a.value is not null
      and a.zscore is not null
    group by 
      a.patient_id,
      a.concept_cd,
      a.trial_name;
    stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Insert data for trial into I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');

    commit;

    --I2B2: Build all paths at once
   INSERT
     INTO I2B2
      (c_hlevel, C_FULLNAME, C_NAME, C_VISUALATTRIBUTES, c_synonym_cd, C_FACTTABLECOLUMN, C_TABLENAME, C_COLUMNNAME,
      C_DIMCODE, C_TOOLTIP, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, c_basecode, C_OPERATOR, c_columndatatype, c_metadataxml, c_comment)
    SELECT 
      (length(concept_path) - nvl(length(replace(concept_path, '\')),0)) / length('\') - 3,
      CONCEPT_PATH,
      NAME_CHAR,
      'LA',
      'N',
      'concept_cd',
      'concept_dimension',
      'concept_path',
      CONCEPT_PATH,
      CONCEPT_PATH,
      sysdate,
      sysdate,
      sysdate,
      SOURCESYSTEM_CD,
      CONCEPT_CD,
      'LIKE',
      'N',
      '<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis></ValueMetadata>' ,
      'trial:' ||  TrialID
    FROM
      CONCEPT_DIMENSION
    WHERE 
      CONCEPT_PATH LIKE '\' || RootNode || '\' || TrialID || '\Biomarker Data\Protein\RBM\' || rbmName || '%';
    stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Insert nodes for trial into I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');

    COMMIT;
	
    --Adding rbm type node. dont care about Concept_cd. User cannot drag it.
	
    if RBMType = 'Z' then
      i2b2_add_node(trialID, '\' || RootNode || '\' || trialID || '\Biomarker Data\Protein\RBM\Z Score\', 'Z Score',jobID);
    else
      i2b2_add_node(trialID, '\' || RootNode || '\' || trialID || '\Biomarker Data\Protein\RBM\Observed\', 'Observed',jobID);
    end if;
	stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Add RBMType node in I2B2METADATA i2b2',0,stepCt,'Done');

    --need to set folders correctly.
    update i2b2
      set c_visualattributes = 'FA',
      c_columndatatype = 'T',
      c_metadataxml = ''
        where c_fullname like '\' || RootNode || '\' || TrialID || '\Biomarker Data\Protein\RBM\' || rbmName || '\%'
          and c_hlevel < 6;
	stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Update visual attributes for folders nodes in I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');

    commit;
	
  --Build concept Counts
  --Also marks any i2B2 records with no underlying data as Hidden, need to do this at the RBM level because patient counts may have changed
	i2b2_create_concept_counts('\' || RootNode || '\' || TrialID || '\Biomarker Data\Protein\RBM\',jobID);
	stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Update patient counts for trial in I2B2DEMODATA concept_counts',0,stepCt,'Done');

  --Reload Security: Inserts one record for every I2B2 record into the security table
	i2b2_load_security_data(jobID);
	stepCt := stepCt + 1;
    control.cz_write_audit(jobId,databaseName,procedureName,'Reload security for trial in I2B2METADATA i2b2_secure',0,stepCt,'Done');
    
  stepCt := stepCt + 1;
  control.cz_write_audit(jobId,databaseName,procedureName,'End i2b2_load_rbm_data',0,stepCt,'Done');
  
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
