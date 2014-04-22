--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_LOAD_ACROSS_TRIALS
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_LOAD_ACROSS_TRIALS" 
(
 currentJobID NUMBER := null
)
AS
  
    --Audit variables
	newJobFlag INTEGER(1);
	databaseName VARCHAR(100);
	procedureName VARCHAR(100);
	jobID number(18,0);
	stepCt number(18,0);
  
	pCount		number;
  
	mixed_datatypes	exception;
	no_table_access	exception;
	
  
  -- JEA@20111104	New
  
  
  root_node 	varchar2(1000);
  root_level	number;
  node_name 	varchar(1000);
  
BEGIN
  
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
	cz_write_audit(jobId,databaseName,procedureName,'Start i2b2_load_across_trials',0,stepCt,'Done');
	
	--	Get level for \Across Trials\  could be 0 or -1
	
	select count(*)
	into root_level
	from table_access
	where c_fullname = '\Across Trials\';
	
	if root_level = 0 then
		raise no_table_access;
	end if;

	select c_hlevel
	into root_level
	from table_access
	where c_fullname = '\Across Trials\';
	
	--	truncate work table
	
	execute immediate('truncate table tm_wz.wt_xtrial_nodes');
 
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Truncate tm_wz.wt_xtrial_nodes',0,stepCt,'Done');
		
	--	Insert folder-level data
	
	insert into wt_xtrial_nodes
	(xtrial_cd
	,trial_name
	,leaf_name
	,data_type
	,concept_cd
	,leaf_node
	)
	select distinct t.xtrial_cd
		  ,base.c_name as trial_name
		  ,la.c_name as leaf_name
		  ,la.c_columndatatype
		  ,la.c_basecode
		  ,REGEXP_REPLACE('\Across Trials\' || replace(replace(t.xtrial_category_cd,'+','\'),'_',' ')  || '\' || t.xtrial_name || '\' || 
		   decode(la.c_columndatatype,'T',la.c_name,'') || '\' || base.c_name || '\','(\\){2,}', '\')
	from cz_xtrial_codes t
		,i2b2 fa
		,i2b2 la
		,i2b2 base
	where t.xtrial_name = fa.c_name
	  and fa.c_fullname not like '%Across Trials%'
	  and fa.c_visualattributes like 'FA%'
	  and la.c_fullname like fa.c_fullname || '%'
	  and la.c_visualattributes like 'LA%'
	  and to_char(fa.c_comment) = to_char(base.c_comment)
	  and base.c_hlevel = 1
	  and not exists
	      (select 1 from cz_xtrial_exclusion xx
		   where to_char(fa.c_comment) = 'trial:' || trial_id);
	
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Insert folder data into wt_xtrial_nodes',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Insert leaf level data, check for dups
	
	insert into wt_xtrial_nodes
	(xtrial_cd
	,trial_name
	,leaf_name
	,data_type
	,concept_cd
	,leaf_node
	)
	select distinct t.xtrial_cd
		  ,base.c_name as trial_name
		  ,la.c_name as leaf_name
		  ,la.c_columndatatype
		  ,la.c_basecode
		  ,REGEXP_REPLACE('\Across Trials\' || replace(replace(t.xtrial_category_cd,'+','\'),'_',' ')  || '\' || t.xtrial_name || '\' || 
			'\' || base.c_name || '\' ,'(\\){2,}', '\')
	from cz_xtrial_codes t
		,i2b2 la
		,i2b2 base
	where t.xtrial_name = la.c_name
	  and la.c_fullname not like '%Across Trials%'
	  and la.c_visualattributes like 'LA%'
	  and to_char(la.c_comment) = to_char(base.c_comment)
	  and base.c_hlevel = 1
	  and not exists
		 (select 1 from wt_xtrial_nodes x
		  where t.xtrial_cd = x.xtrial_cd
		    and base.c_name = x.trial_name
			and la.c_name = x.leaf_name
			and la.c_basecode = x.concept_cd)
	  and not exists
	      (select 1 from cz_xtrial_exclusion xx
		   where to_char(la.c_comment) = 'trial:' || trial_id);
	
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Insert leaf data into wt_xtrial_nodes',SQL%ROWCOUNT,stepCt,'Done');
	commit;

	--	Determine if any xtrial_cds have more than one datatype (mix of numeric and text).  If yes, raise exception
	
	select count(*)
	into pCount
	from (select xtrial_cd
		  from wt_xtrial_nodes
		  group by xtrial_cd
		  having count(distinct data_type) > 1);
		 
	if pCount > 0 then
		raise mixed_datatypes;
	end if;

	--	delete Across Trials nodes in i2b2
	--	can't use i2b2_delete_all_nodes because the observation_fact data should not be deleted.  It belongs to the trial
	
	--concept dimension
	delete from concept_dimension
	where concept_path like '\Across Trials\%';
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete Across Trials from I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;
    
	--i2b2
	delete from i2b2
	where c_fullname like '\Across Trials\%';
	stepCt := stepCt + 1;
	  cz_write_audit(jobId,databaseName,procedureName,'Delete Across Trials from I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
	commit;
 
	--	delete patient SECURITY nodes for Across Trials
	
	delete from observation_fact
	where modifier_cd = 'Across Trials'
	  and concept_cd = 'SECURITY';
	stepct := stepct + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Delete Across Trials SECURITY from I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	commit;	
	
	--	add top-level Across Trial nodes
	
	i2b2_add_node('Across Trials','\Across Trials\','Across Trials',jobid);
	
	--	create Across Trials i2b2 nodes
	
	insert into i2b2
    (c_hlevel
	,c_fullname
	,c_name
	,c_visualattributes
	,c_synonym_cd
	,c_facttablecolumn
	,c_tablename
	,c_columnname
    ,c_dimcode
	,c_tooltip
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,c_basecode
	,c_operator
	,c_columndatatype
	,c_metadataxml
	,c_comment)
    SELECT (length(leaf_node) - nvl(length(replace(leaf_node, '\')),0)) / length('\') - 2 + root_level 
		  ,leaf_node
		  ,trial_name
		  ,'LA'		--	set to folder for initial insert, will be changed to LA for leaf nodes in later update
		  ,'N'
		  ,'CONCEPT_CD'
		  ,'CONCEPT_DIMENSION'
		  ,'CONCEPT_PATH'
		  ,leaf_node
		  ,leaf_node
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,'Across_Trials'
		  ,concept_cd
		  ,'LIKE'
		  ,data_type
		  ,case when data_type = 'N' 
		        then '<?xml version="1.0"?><ValueMetadata><Version>3.02</Version><CreationDateTime>08/14/2008 01:22:59</CreationDateTime><TestID></TestID><TestName></TestName><DataType>PosFloat</DataType><CodeType></CodeType><Loinc></Loinc><Flagstouse></Flagstouse><Oktousevalues>Y</Oktousevalues><MaxStringLength></MaxStringLength><LowofLowValue>0</LowofLowValue><HighofLowValue>0</HighofLowValue><LowofHighValue>100</LowofHighValue>100<HighofHighValue>100</HighofHighValue><LowofToxicValue></LowofToxicValue><HighofToxicValue></HighofToxicValue><EnumValues></EnumValues><CommentsDeterminingExclusion><Com></Com></CommentsDeterminingExclusion><UnitValues><NormalUnits>ratio</NormalUnits><EqualUnits></EqualUnits><ExcludingUnits></ExcludingUnits><ConvertingUnits><Units></Units><MultiplyingFactor></MultiplyingFactor></ConvertingUnits></UnitValues><Analysis><Enums /><Counts /><New /></Analysis></ValueMetadata>'
				else null end
		  ,'trial:Across_Trials'
	from wt_xtrial_nodes;
	
    stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Add leaf nodes for Across Trials to I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');

	--	Add concept_dimension paths for Across Trials leaf nodes
	
	insert into concept_dimension
    (concept_cd
	,concept_path
	,name_char
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,table_name)
    SELECT distinct concept_cd
		  ,leaf_node
		  ,leaf_name
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,'Across_Trials'
		  ,'CONCEPT_DIMENSION'
    from wt_xtrial_nodes;
	
    stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Add leaf nodes to I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--	add patient SECURITY data to observation fact
	
    insert into i2b2demodata.observation_fact
    (patient_num
	,concept_cd
	,provider_id
	,modifier_cd
	,valtype_cd
	,tval_char
	,valueflag_cd
	,location_cd
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	)
	SELECT distinct pd.patient_num
		  ,'SECURITY'
		  ,'@'
		  ,'Across Trials'
		  ,'T'
		  ,'EXP:PUBLIC'
		  ,'@'
		  ,'@'
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,pd.sourcesystem_cd
	from wt_xtrial_nodes c
		,observation_fact f
		,patient_dimension pd
	WHERE c.concept_cd = f.concept_cd
	  and f.patient_num = pd.patient_num;
	
    stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Add SECURITY records to I2B2DEMODATA observation_fact',SQL%ROWCOUNT,stepCt,'Done');
	commit;
		  
	--	fill in tree
	
	i2b2_fill_in_tree('Across Trials','\Across Trials\', jobID);
  
	--	create concept counts
	
    i2b2_create_concept_counts('\Across Trials\',jobID );
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Create concept counts for Clinical Data',0,stepCt,'Done');

  --Reload Security: Inserts one record for every I2B2 record into the security table

    i2b2_load_security_data(jobId);
	stepCt := stepCt + 1;
	cz_write_audit(jobId,databaseName,procedureName,'Load security data',0,stepCt,'Done');
		
	---Cleanup OVERALL JOB if this proc is being run standalone
	IF newJobFlag = 1
	THEN
		cz_end_audit (jobID, 'SUCCESS');
	END IF;

	EXCEPTION
	when mixed_datatypes then
		stepCt := stepCt + 1;
		cz_write_audit(jobId,databaseName,procedureName,'Check wt_xtrial_nodes for mixed data_types',0,stepCt,'Done');
		cz_error_handler (jobID, procedureName);
		cz_end_audit (jobID, 'FAIL');
	when no_table_access then
		stepCt := stepCt + 1;
		cz_write_audit(jobId,databaseName,procedureName,'No record for \Across Trials\ in table_access',0,stepCt,'Done');
		cz_error_handler (jobID, procedureName);
		cz_end_audit (jobID, 'FAIL');	
	WHEN OTHERS THEN
		--Handle errors.
		cz_error_handler (jobID, procedureName);
		--End Proc
		cz_end_audit (jobID, 'FAIL');
	
END;
/
 
