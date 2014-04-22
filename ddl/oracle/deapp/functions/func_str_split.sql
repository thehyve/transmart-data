--
-- Type: FUNCTION; Owner: DEAPP; Name: FUNC_STR_SPLIT
--
  CREATE OR REPLACE FUNCTION "DEAPP"."FUNC_STR_SPLIT" (
  str_to_split IN OUT VARCHAR2,
  str_delimiter IN VARCHAR2) 
    RETURN VARCHAR2
IS
  t_pos NUMBER;
  t_len NUMBER;
  t_strlen NUMBER;
  t_strresult VARCHAR2(2000);
BEGIN
  t_strresult := NULL;
  IF str_to_split IS NOT NULL 
  THEN
    t_len := LENGTH(str_delimiter);
    t_strlen := LENGTH(str_to_split);
    t_pos := INSTR(str_to_split,str_delimiter);
    IF t_pos > 0 
    THEN
      t_strresult := SUBSTR(str_to_split,1,t_pos-1);
      str_to_split := SUBSTR(str_to_split,t_pos+t_len,t_strlen);
    ELSE
      t_strresult := str_to_split;
      str_to_split := NULL;
    END IF;
  END IF;
  
  RETURN t_strresult;
  
END func_str_split;
 
 
 
/
