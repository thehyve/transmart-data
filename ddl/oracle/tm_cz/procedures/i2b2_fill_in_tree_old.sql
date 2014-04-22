--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_FILL_IN_TREE_OLD
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_FILL_IN_TREE_OLD" 
(
  trial_id VARCHAR2
 ,nodePath VARCHAR2
 ,currentJobID NUMBER := null
)
AS
  TrialID varchar2(100);
  
    --Audit variables
  newJobFlag INTEGER(1);
  databaseName VARCHAR(100);
  procedureName VARCHAR(100);
  jobID number(18,0); 
  stepCt number(18,0);
  
  auditText varchar2(4000);
  
  ----------------------------------------------
  --Goal: To fill out an I2B2 Tree node
  --Steps. Walk backwards through an i2b2 tree and fill in all missing nodes.
  --\1\2\3\4\5\6\
  --Will check that \1\, \1\2\, etc..all exist.
  ----------------------------------------------
  
  -- JEA@20100107 - Added auditing
  -- JEA@20100410 - Removed audit of root_node name, too long
  -- JEA@20100618 - Changed from cursor to table-based for performance
  -- JEA@20101012 - Changed to use tmp_tree_nodes table in control zone
/*  
  --Get the nodes
  CURSOR cNodes is
    --Trimming off the last node as it would never need to be added.
    select distinct substr(c_fullname, 1,instr(c_fullname,'\',-2,1)) as c_fullname
    --select c_fullname
    from i2b2 
    where c_fullname like path || '%';
--      and c_hlevel > = 2;
 */
 
  root_node varchar2(1000);
  node_name varchar(1000);
  v_count NUMBER;
  nodeCt number;
  
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
  
  --start node with the first slash
  
  --	get max number of nodes in path
  
	select nvl(max((length(concept_path) - nvl(length(replace(concept_path, '\')),0)) / length('\'))-2,-1)
	into nodeCt
	from i2b2demodata.concept_dimension
	where concept_path like nodePath || '%';
	
	execute immediate('truncate table tmp_tree_nodes');
	
	--	insert 
	
	insert into tmp_tree_nodes
	(leaf_node
	,node_name
	)
	select distinct substr(c.c_fullname,1,instr(c.c_fullname,'\',-1,x.row_num+1)) as fill_path
		  ,substr(c.c_fullname,instr(c.c_fullname,'\',-1,x.row_num+2)+1
		  ,instr(c.c_fullname,'\',-1,x.row_num+1)-instr(c.c_fullname,'\',-1,x.row_num+2)-1) as fill_name
	from i2b2 c
		,(select rownum as row_num from i2b2
		  where rownum < nodeCt) x
	where c.c_fullname like nodePath || '%'
	  and substr(c.c_fullname,1,instr(c.c_fullname,'\',-1,x.row_num+1)) is not null
	  and length(substr(c.c_fullname,1,instr(c.c_fullname,'\',-1,x.row_num+1))) >= length(nodePath)
	order by fill_path;
 
	insert into concept_dimension
    (concept_cd
	,concept_path
	,name_char
	,update_date
	,download_date
	,import_date
	,sourcesystem_cd
	,table_name
	)
    select 'JNJ'||concept_id.nextval
		  ,t.leaf_node
		  ,to_char(t.node_name)
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,TrialID
		  ,'CONCEPT_DIMENSION'
	from tmp_tree_nodes t
	where not exists
	     (select 1 from concept_dimension x
		  where t.leaf_node = x.concept_path);
		  
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted fill nodes into I2B2DEMODATA concept_dimension',SQL%ROWCOUNT,stepCt,'Done');
    commit;
	
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
	,c_comment
	)
    select (length(c.concept_path) - nvl(length(replace(c.concept_path, '\')),0)) / length('\') - 3
		  ,c.concept_path
		  ,c.name_char
		  ,'FA'
		  ,'N'
		  ,'CONCEPT_CD'
		  ,'CONCEPT_DIMENSION'
		  ,'CONCEPT_PATH'
		  ,c.concept_path
		  ,c.concept_path
		  ,sysdate
		  ,sysdate
		  ,sysdate
		  ,c.sourcesystem_cd
		  ,c.concept_cd
		  ,'LIKE'
		  ,'T'
		  ,'trial:' || TrialID 
    from concept_dimension c
    where c.concept_path in
	     (select t.leaf_node from tmp_tree_nodes t)
	 and not exists
	     (select 1 from i2b2 x
		  where c.concept_path = x.c_fullname);
	stepCt := stepCt + 1;
	tm_cz.cz_write_audit(jobId,databaseName,procedureName,'Inserted fill nodes into I2B2METADATA i2b2',SQL%ROWCOUNT,stepCt,'Done');
    COMMIT;
 
 /*
  --Iterate through each node
  FOR r_cNodes in cNodes Loop
    root_node := '\';
    --Determine how many nodes there are
    --Iterate through, Start with 2 as one will be null from the parser
    
    for loop_counter in 2 .. (length(r_cNodes.c_fullname) - nvl(length(replace(r_cNodes.c_fullname, '\')),0)) / length('\')
    LOOP
      --Determine Node:
      node_name := parse_nth_value(r_cNodes.c_fullname, loop_counter, '\');
      root_node :=  root_node || node_name || '\';
    
      --Dont run for first 2 nodes
      if loop_counter > 3 then 
        --Check if node exists. If it does not, add it.
        select count(*)
          into v_count 
        from i2b2
        where c_fullname = root_node;

        --If it doesn't exist, add it
        if v_count = 0 then
			auditText := 'Inserting ' || root_node;
			stepCt := stepCt + 1;
			-- tm_cz.cz_write_audit(jobId,databaseName,procedureName,auditText,0,stepCt,'Done');
            i2b2_add_node(trial_id, root_node, node_name, jobId);
        end if;
      end if;
      
    END LOOP;

    --RESET VARIABLES
    root_node := '';
    node_name := '';
  END LOOP;
*/
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
 
