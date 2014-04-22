--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_MRNA_INDEX_MAINT
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_MRNA_INDEX_MAINT" 
(
  run_type 			VARCHAR2 := 'DROP'
 ,tablespace_name	varchar2	:= 'INDX'
 ,currentJobID 		NUMBER := null
)
AS
--	Procedure to either drop or create indexes for deapp.de_subject_microarray_data

--	JEA@20111020	New
--	JEA@20111130	Only do local or bitmap index if de_subject_microarray_data is partitioned
--	JEA@20120226	Added tablespace to indx10, added bitmapCompress to compress indexs if not bitmapped
--	JEA@20120301	Removed indx10, subject_id no longer in de_subject_microarray_data
--	JEA@20120406	Added variable for tablespace name
--	JEA@20120423	Removed indx5, app code changed to join on assay_id
--	JEA@20120530	Added indx5 on trial_source if table not partitioned

  runType	varchar2(100);
  idxExists	number;
  pExists	number;
  localVar	varchar2(20);
  bitmapVar	varchar2(20);
  bitmapCompress	varchar2(20);
  tableSpace	varchar2(50);
   
  --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0);
  stepCt number(18,0);
  
BEGIN

	runType := upper(run_type);
	tableSpace := upper(tablespace_name);
	
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
  
	--	Determine if de_subject_microarray_data is partitioned, if yes, set localVar to local
  	select count(*)
	into pExists
	from all_tables
	where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
	  and partitioned = 'YES';
	  
	if pExists = 0 then
		localVar := null;
		bitmapVar := null;
		bitmapCompress := 'compress';
	else 
		localVar := 'local';
		bitmapVar := 'bitmap';
		bitmapCompress := null;
	end if;
   
	if runType = 'DROP' then
		stepCt := stepCt + 1;
		cz_write_audit(jobId,databaseName,procedureName,'Start de_subject_microarray_data index drop',0,stepCt,'Done');
		--	drop the indexes
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX1'
		  and owner = 'DEAPP';
		
		if idxExists = 1 then
			execute immediate('drop index deapp.de_microarray_data_idx1');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Drop de_microarray_data_idx1',0,stepCt,'Done');
		end if;
		
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX2'
		  and owner = 'DEAPP';
		
		if idxExists = 1 then
			execute immediate('drop index deapp.de_microarray_data_idx2');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Drop de_microarray_data_idx2',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX3'
		  and owner = 'DEAPP';
		
		if idxExists = 1 then
			execute immediate('drop index deapp.de_microarray_data_idx3');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Drop de_microarray_data_idx3',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX4'
		  and owner = 'DEAPP';
		
		if idxExists = 1 then
			execute immediate('drop index deapp.de_microarray_data_idx4');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Drop de_microarray_data_idx4',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX5'
		  and owner = 'DEAPP';
		
		if idxExists = 1 then
			execute immediate('drop index deapp.de_microarray_data_idx5');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Drop de_microarray_data_idx5',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX10'
		  and owner = 'DEAPP';
		
		if idxExists = 1 then
			execute immediate('drop index deapp.de_microarray_data_idx10');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Drop de_microarray_data_idx10',0,stepCt,'Done');
		end if;
						
	else
		--	add indexes
		stepCt := stepCt + 1;
		cz_write_audit(jobId,databaseName,procedureName,'Start de_subject_microarray_data index create',0,stepCt,'Done');
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX1'
		  and owner = 'DEAPP';
		  
		if idxExists = 0 then
			execute immediate('create index deapp.de_microarray_data_idx1 on deapp.de_subject_microarray_data(trial_name, assay_id, probeset_id) ' || localVar || ' nologging compress tablespace "' || tableSpace || '"'); 
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Create de_microarray_data_idx1',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX2'
		  and owner = 'DEAPP';
		  
		if idxExists = 0 then		
			execute immediate('create index deapp.de_microarray_data_idx2 on deapp.de_subject_microarray_data(assay_id, probeset_id) ' || localVar || ' nologging compress tablespace "' || tableSpace || '"');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Create de_microarray_data_idx2',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX3'
		  and owner = 'DEAPP';
		  
		if idxExists = 0 then		
			execute immediate('create ' || bitmapVar || ' index deapp.de_microarray_data_idx3 on deapp.de_subject_microarray_data(assay_id) ' || localVar || ' nologging ' || bitmapCompress || ' tablespace "' || tableSpace || '"');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Create de_microarray_data_idx3',0,stepCt,'Done');
		end if;
				
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX4'
		  and owner = 'DEAPP';
		  
		if idxExists = 0 then
			execute immediate('create ' || bitmapVar || ' index deapp.de_microarray_data_idx4 on deapp.de_subject_microarray_data(probeset_id) ' || localVar || ' nologging ' || bitmapCompress || ' tablespace "' || tableSpace || '"');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Create de_microarray_data_idx4',0,stepCt,'Done');
		end if;

		if pExists = 0 then
			--	only create this index if the table is not partitioned.  This is the column that the table would be partitioned on
			
			select count(*) 
			into idxExists
			from all_indexes
			where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
			  and index_name = 'DE_MICROARRAY_DATA_IDX5'
			  and owner = 'DEAPP';
			  
			if idxExists = 0 then
				execute immediate('create index deapp.de_microarray_data_idx5 on deapp.de_subject_microarray_data(trial_source) ' || localVar || ' nologging ' || bitmapCompress || ' tablespace "' || tableSpace || '"');
				stepCt := stepCt + 1;
				cz_write_audit(jobId,databaseName,procedureName,'Create de_microarray_data_idx5',0,stepCt,'Done');
			end if;
		end if;

/*		not used
	
		select count(*) 
		into idxExists
		from all_indexes
		where table_name = 'DE_SUBJECT_MICROARRAY_DATA'
		  and index_name = 'DE_MICROARRAY_DATA_IDX10'
		  and owner = 'DEAPP';
		  
		if idxExists = 0 then
			execute immediate('create index deapp.de_microarray_data_idx10 on deapp.de_subject_microarray_data(assay_id, subject_id, probeset_id, zscore) ' || localVar || ' nologging compress tablespace "' || tableSpace || '"');
			stepCt := stepCt + 1;
			cz_write_audit(jobId,databaseName,procedureName,'Create de_microarray_data_idx10',0,stepCt,'Done');
		end if;
*/							
	end if;

end;
/
