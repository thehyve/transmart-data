--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_LOAD_COMPOUND_METADATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_LOAD_COMPOUND_METADATA" 
(
  currentJobID NUMBER := null
)
AS
	--	NOTE****	The compound.txt file must have the LF's cleaned from data (Run CleanCells macro before exporting to tab-delimited file)
	-- JEA@20110720	New, cloned for tranSMART consortia
  
	--Audit variables
	newJobFlag INTEGER(1);
	databaseName VARCHAR(100);
	procedureName VARCHAR(100);
	jobID number(18,0);
	stepCt number(18,0);

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

	--	Update existing compound data by generic_names, cnto_number, jnj_number or cas_registry
	
	update biomart.bio_compound b
	set (cas_registry
		,code_name
		,brand_name
		,chemical_name
		,mechanism
		,product_category
		,description
		) = (select trim('"' from c.cas_registry)
				   ,trim('"' from c.code_name)
				   ,trim('"' from c.brand_name)
				   ,trim('"' from c.chemical_name)
				   ,trim('"' from c.mechanism)
				   ,trim('"' from c.product_category)
				   ,trim('"' from c.description)
			 from control.compound_extrnl c
			 where (c.generic_name is not null
					and b.generic_name = c.generic_name)
				or (c.cas_registry is not null
					and b.cas_registry = c.cas_registry)
			)
		where (b.generic_name is not null
			   and exists
			   (select 1 from control.compound_extrnl c
			    where b.generic_name = c.generic_name
			      and c.generic_name is not null
			   ))
		  or (b.cas_registry is not null
			  and exists
			  (select 1 from control.compound_extrnl c
			   where b.cas_registry = c.cas_registry
			     and c.cas_registry is not null
			  ))
	;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Updated compound in BIOMART bio_compound',SQL%ROWCOUNT,stepCt,'Done');
	commit;
	
	--	Add new compound to bio_compound
	
	insert into biomart.bio_compound b
	(cas_registry
	,code_name
	,generic_name
	,brand_name
	,chemical_name
	,mechanism
	,product_category
	,description
	,etl_id
	)
	select trim('"' from c.cas_registry)
		  ,trim('"' from c.code_name)
		  ,trim('"' from c.generic_name)
		  ,trim('"' from c.brand_name)
		  ,trim('"' from c.chemical_name)
		  ,trim('"' from c.mechanism)
		  ,trim('"' from c.product_category)
		  ,replace(trim('"' from c.description),'""','"')
		  ,to_char(sysdate,'YYYY/MM/DD HH:mm:SS')
	from control.compound_extrnl c
	where (c.generic_name is not null or
		   c.cas_registry is not null)
	  and not exists
		   (select 1 from biomart.bio_compound xb
		    where xb.generic_name = c.generic_name)
	  and not exists
		   (select 1 from biomart.bio_compound wb
		    where wb.cas_registry = c.cas_registry)
	;
	stepCt := stepCt + 1;
	control.cz_write_audit(jobId,databaseName,procedureName,'Inserted compound into BIOMART bio_compound',SQL%ROWCOUNT,stepCt,'Done');
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
 
