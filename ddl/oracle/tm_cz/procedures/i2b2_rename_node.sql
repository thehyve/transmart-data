--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_RENAME_NODE
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_RENAME_NODE" 
(
  trial_id varchar2,
  old_node VARCHAR2,
  new_node VARCHAR2
)
AS
BEGIN
  
  -------------------------------------------------------------
  -- Add a tree node in I2b2
  -- KCR@20090519 - First Rev
  -- JEA@20090910 - Added update of concept_path and parent_concept_path in concept_counts, moved update of i2b2 c_dimcode and c_tooltip to be done
  --				at the same time as c_fullname
  -- JEA@20091029 - Update i2b2_secure and i2b2_tags
  -------------------------------------------------------------
  if old_node != ''  or old_node != '%' or new_node != ''  or new_node != '%'
  then 

    --Update specific name
    update concept_dimension
      set name_char = new_node
      where name_char = old_node
        and concept_path like '%' || trial_id || '%'; 

    --Update all paths
    update concept_dimension
      set CONCEPT_PATH = replace(concept_path, old_node, new_node)

      where 
        concept_path like '%' || trial_id || '%'; 
    COMMIT;
	
	--	Update concept_counts paths
	
	update concept_counts
      set CONCEPT_PATH = replace(concept_path, old_node, new_node),
	      parent_concept_path = replace(parent_concept_path, old_node, new_node)
      where 
        concept_path like '%' || trial_id || '%'; 
    COMMIT;

    --I2B2
    --Update specific name
    update i2b2
      set c_name = new_node
      where c_name = old_node
        and c_fullname like '%' || trial_id || '%'; 

    --Update all paths, added updates to c_dimcode and c_tooltip instead of separate pass
    update i2b2
      set c_fullname = replace(c_fullname, old_node, new_node)
	  	 ,c_dimcode = replace(c_dimcode, old_node, new_node)
		 ,c_tooltip = replace(c_tooltip, old_node, new_node)
      where 
        c_fullname like '%' || trial_id || '%'; 
    COMMIT;
	
	--Update i2b2_secure to match i2b2
    update i2b2_secure
      set c_fullname = replace(c_fullname, old_node, new_node)
	  	 ,c_dimcode = replace(c_dimcode, old_node, new_node)
		 ,c_tooltip = replace(c_tooltip, old_node, new_node)
      where 
        c_fullname like '%' || trial_id || '%'; 
    COMMIT;
  
    --Update path in i2b2_tags
    update i2b2_tags
      set path = replace(path, old_node, new_node)
      where 
        path like '%' || trial_id || '%'; 
    COMMIT;

  END IF;
END;
/
