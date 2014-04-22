--
-- Type: PROCEDURE; Owner: TM_CZ; Name: I2B2_HIDE_NODE
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."I2B2_HIDE_NODE" 
(
  path VARCHAR2
)
AS
BEGIN
  
  -------------------------------------------------------------
  -- hIDES a tree node in I2b2
  -- KCR@20090519 - First Rev
  -- JEA@20120404	Only update second character of c_visualattributes
  -------------------------------------------------------------
  if path != ''  or path != '%'
  then 
  
	update i2b2 b
	set c_visualattributes=substr(b.c_visualattributes,1,1) || 'H' || substr(b.c_visualattributes,3,1)
	where c_fullname like path || '%';
	
	delete from concept_counts
	where concept_path like path || '%';
	
	commit;
	
	
/* 
      --I2B2
     UPDATE i2b2
      SET c_visualattributes = 'FH'
    WHERE c_visualattributes like 'F%'
      AND C_FULLNAME LIKE PATH || '%';

     UPDATE i2b2
      SET c_visualattributes = 'LH'
    WHERE c_visualattributes like 'L%'
      AND C_FULLNAME LIKE PATH || '%';
    COMMIT;
*/
  END IF;
  
END;
/
