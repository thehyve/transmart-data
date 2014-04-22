--
-- Type: FUNCTION; Owner: BIOMART; Name: TAB_TO_STRING
--
  CREATE OR REPLACE FUNCTION "BIOMART"."TAB_TO_STRING" (p_varchar2_tab  IN  t_varchar2_tab,
                                          p_delimiter     IN  VARCHAR2 DEFAULT ',') RETURN VARCHAR2 IS
  l_string     VARCHAR2(32767);
BEGIN
  FOR i IN p_varchar2_tab.FIRST .. p_varchar2_tab.LAST LOOP
    IF i != p_varchar2_tab.FIRST THEN
      l_string := l_string || p_delimiter;
    END IF;
    l_string := l_string || p_varchar2_tab(i);
  END LOOP;
  RETURN l_string;
END tab_to_string;
 
 
 
 
 
 
 
 
/
