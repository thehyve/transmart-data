--
-- Name: insert_pid_map_fromtemp(character varying, numeric); Type: FUNCTION; Schema: i2b2demodata; Owner: -
--
CREATE FUNCTION insert_pid_map_fromtemp(temppidtablename character varying, upload_id numeric, OUT errormsg character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$ 

DECLARE
 existingPatientNum VARCHAR(32);
 maxPatientNum NUMERIC;
 --TYPE distinctPidCurTyp IS CURSOR;
 --distinctPidCurTyp refcursor;
 --distinctPidCur   distinctPidCurTyp;
 distinctPidCur CURSOR;
 sql_stmt  VARCHAR(400);
disPatientId VARCHAR(100); 
disPatientIdSource VARCHAR(100);

BEGIN
 sql_stmt := ' SELECT distinct patient_id,patient_id_source from ' || tempPidTableName ||' ';
 
  --delete the data if they miss 
  -- smuniraju: rowid not implemented in postgres/ greenplum
  -- execute ' delete  from ' || tempPidTableName ||  ' t1  
  --			where rowid > (select min(rowid) from ' || tempPidTableName || ' t2 
  -- 			where t1.patient_map_id = t2.patient_map_id
  -- 			and t1.patient_map_id_source = t2.patient_map_id_source) ';
  execute 'delete  from ' || tempPidTableName ||  ' t1  
		   where ( ctid) 
		    not in (select  max(ctid) from  ' || tempPidTableName ||  ' 
			group  BY patient_map_id,patient_map_id_source,patient_id,patient_id_source)';
  
  LOCK TABLE  patient_mapping IN EXCLUSIVE MODE NOWAIT;
  select max(patient_num) into maxPatientNum from patient_mapping ; 
 
 -- set max patient num to zero of the value is null
  if maxPatientNum is null then 
    maxPatientNum := 0;
  end if;

  open distinctPidCur for execute(sql_stmt);

  loop   
     FETCH distinctPidCur INTO disPatientId, disPatientIdSource;
      -- smuniraju: %NOTFOUND is not supported in POSTGRES
	  -- EXIT WHEN distinctPidCur%NOTFOUND;
	  EXIT WHEN NOT FOUND;    
        
	  if  disPatientIdSource = 'HIVE' THEN 
		begin
		 --check if hive NUMERIC exist, if so assign that NUMERIC to reset of map_id's within that pid
		 select patient_num into existingPatientNum from patient_mapping where patient_num = disPatientId and patient_ide_source = 'HIVE';
		   EXCEPTION  
			 when NO_DATA_FOUND THEN
			   existingPatientNum := null;
		end;
   
		if existingPatientNum is not null then 
			-- smuniraju: not exists results in corelated queries not supported by greenplum
			-- execute ' update ' || tempPidTableName ||' set patient_num = patient_id, process_status_flag = ''P''
			-- where patient_id = ' || disPatientId || ' and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
			-- and pm.patient_ide_source = patient_map_id_source)';
			execute 'update ' || tempPidTableName ||' temp set patient_num = patient_id::numeric, process_status_flag = ''P''
					 from patient_mapping pm 
					 where pm.patient_ide = temp.patient_map_id
					 and pm.patient_ide_source = temp.patient_map_id_source
					 and pm.patient_ide is null
					 and patient_id = ' || disPatientId || '';
		else 
			-- generate new patient_num i.e. take max(patient_num) + 1 
			if maxPatientNum < disPatientId then 
			   maxPatientNum := disPatientId;
			end if ;
	
		-- smuniraju: not exists results in corelated queries not supported by greenplum
		-- execute ' update ' || tempPidTableName ||' set patient_num = patient_id, process_status_flag = ''P'' where 
		-- patient_id = ' || disPatientId || ' and patient_id_source = ''HIVE'' and not exists (select 1 from patient_mapping pm where pm.patient_ide -- = patient_map_id and pm.patient_ide_source = patient_map_id_source)';
		execute 'update ' || tempPidTableName ||' temp set patient_num = patient_id::numeric, process_status_flag = ''P'' 
				 from patient_mapping pm
				 where pm.patient_ide = temp.patient_map_id
				 and pm.patient_ide_source = temp.patient_map_id_source
				 and pm.patient_ide is null and  pm.patient_ide_source is null
				 and patient_id = ' || disPatientId || ' and patient_id_source = ''HIVE'''; 
	end if;    
    
	  -- test if record fectched
	  -- dbms_output.put_line(' HIVE ');
	else 
		begin
		   select patient_num into existingPatientNum from patient_mapping where patient_ide = disPatientId and 
			patient_ide_source = disPatientIdSource ; 

		   -- test if record fetched. 
		   EXCEPTION
			   WHEN NO_DATA_FOUND THEN
			   existingPatientNum := null;
		   end;
		   if existingPatientNum is not null then 
				-- smuniraju: not exists results in corelated queries not supported by greenplum
				-- execute ' update ' || tempPidTableName ||' set patient_num = ' || existingPatientNum || ', process_status_flag = ''P''
				-- where patient_id = ' || disPatientId || ' and not exists (select 1 from patient_mapping pm where pm.patient_ide = patient_map_id
				-- and pm.patient_ide_source = patient_map_id_source)' ;
				execute 'update ' || tempPidTableName ||' temp set patient_num = ' || existingPatientNum || '::numeric, process_status_flag = ''P''
						 from patient_mapping pm 
						 where pm.patient_ide = temp.patient_map_id
						 and pm.patient_ide_source = temp.patient_map_id_source
						 and pm.patient_ide is null and pm.patient_ide_source is null
						 and patient_id = ' || disPatientId || '';
		   else 
				maxPatientNum := maxPatientNum + 1 ; 
				 execute 'insert into ' || tempPidTableName ||' (patient_map_id,patient_map_id_source,patient_id,patient_id_source,patient_num,process_status_flag
				 ,patient_map_id_status,update_date,download_date,import_date,sourcesystem_cd) 
				 values(' || maxPatientNum || ',''HIVE'',' || maxPatientNum || ',''HIVE'',' || maxPatientNum || ',''P'',''A'',current_timestamp,current_timestamp,current_timestamp,''edu.harvard.i2b2.crc'')'; 
			   
			   -- smuniraju: not exists results in corelated queries not supported by greenplum
			   -- execute 'update ' || tempPidTableName ||' set patient_num =  ' || maxPatientNum || ' , process_status_flag = ''P'' 
			   -- where patient_id = ' || disPatientId || ' and  not exists (select 1 from 
			   --  patient_mapping pm where pm.patient_ide = patient_map_id
			   --  and pm.patient_ide_source = patient_map_id_source)' ;
				execute 'update ' || tempPidTableName ||' temp set patient_num =  ' || maxPatientNum || ' , process_status_flag = ''P'' 
						 from patient_mapping pm 
						 where pm.patient_ide = temp.patient_map_id
						 and pm.patient_ide_source = temp.patient_map_id_source
						 and pm.patient_ide is null 
						 and pm.patient_ide_source is null
						 and patient_id = ' || disPatientId || ' ';						
		   end if ;
      -- dbms_output.put_line(' NOT HIVE ');
	end if; 
  END LOOP;
  close distinctPidCur ;
  -- smuniraju: Postgres doesn't allow commit and rollback within procedures because it is explicity done upon 'END;'	 
  -- commit;

  -- do the mapping update if the update date is old
  -- smuniraju: merge resulting in errors.
   /* execute ' merge into patient_mapping
      using ' || tempPidTableName ||' temp
      on (temp.patient_map_id = patient_mapping.patient_IDE 
  		  and temp.patient_map_id_source = patient_mapping.patient_IDE_SOURCE
	   ) when matched then 
  		update set patient_num = temp.patient_id,
    	patient_ide_status	= temp.patient_map_id_status  ,
    	update_date = temp.update_date,
    	download_date  = temp.download_date ,
		import_date = sysdate ,
    	sourcesystem_cd  = temp.sourcesystem_cd ,
		upload_id = ' || upload_id ||'  
    	where  temp.patient_id_source = ''HIVE'' and temp.process_status_flag is null  and
        nvl(patient_mapping.update_date,to_date(''1900-01-01'',''YYYY-MM-DD''))<= nvl(temp.update_date,to_date(''1900-01-01'',''YYYY-MM-DD'')) ' ;
	*/
  execute ' update patient_mapping pm set 
			patient_num = temp.patient_id::numeric,
			patient_ide_status	= temp.patient_map_id_status  ,
			update_date = temp.update_date,
			download_date  = temp.download_date ,
			import_date = now() ,
			sourcesystem_cd  = temp.sourcesystem_cd ,
			upload_id = ' || upload_id ||'  	
			from ' || tempPidTableName ||' temp
			where pm.patient_ide = temp.patient_map_id and pm.patient_ide_source = temp.patient_map_id_source
			and temp.patient_id_source = ''HIVE'' and temp.process_status_flag is null  and 
			coalesce(pm.update_date,to_date(''1900-01-01'',''YYYY-MM-DD''))<= coalesce(temp.update_date,to_date(''1900-01-01'',''YYYY-MM-DD'')) ' ;
	
  -- insert new mapping records i.e flagged P
  execute ' insert into patient_mapping (patient_ide,patient_ide_source,patient_ide_status,patient_num,update_date,download_date,import_date,sourcesystem_cd,upload_id) 
				select patient_map_id,patient_map_id_source,patient_map_id_status,patient_num,update_date,download_date,now(),sourcesystem_cd,' || upload_id ||' from '|| tempPidTableName || ' 
				where process_status_flag = ''P'' ' ; 
  -- smuniraju: Postgres doesn't allow commit and rollback within procedures because it is explicity done upon 'END;'	 
  -- commit;
  EXCEPTION
   WHEN OTHERS THEN
		RAISE EXCEPTION'An error was encountered - % -ERROR- %', SQLSTATE, SQLERRM;
		  -- postgres  doesn't support isOpen
		  -- if distinctPidCur%isopen then
		  --    close distinctPidCur;
		  -- end if;
	  begin
		close distinctPidCur;
		EXCEPTION
			WHEN OTHERS THEN
				RAISE NOTICE 'Error occured closing cursor.';
	  end;
      -- smuniraju: Postgres doesn't allow rollback within procedures because it is explicity when a transaction fails.
	  -- rollback;      
end;

$$;

