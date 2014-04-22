--
-- Type: FUNCTION; Owner: I2B2DEMODATA; Name: SF_GET_VISIT
--
  CREATE OR REPLACE FUNCTION "I2B2DEMODATA"."SF_GET_VISIT" (v_protocolid     IN SIDESHOW_EAV.protocol_id%TYPE,
                                        v_subjectid      IN SIDESHOW_EAV.subject_id%TYPE,
                                        v_variableid     IN SIDESHOW_EAV.variable_id%TYPE)
                                        RETURN varchar2  IS
--***************************************************************************
--* Name:  Sf_Get_Visit
--* Date:  03/24/2009
--* Author:  George Kuebrich
--* Purpose:    To select and return the subject's visit for the associated dataset and variable_id.
--* Inputs:  protocol_id, subject_id, variable_id from the sideshow_eav table
--* Output:  Returns the subject's visit
--* Effects:   NONE
--***************************************************************************
v_visit varchar2(500);
BEGIN
   SELECT DISTINCT decode(upper(c.variable_name),'VISIT',b.value,decode(upper(c.variable_name),'PERIOD',B.VALUE)) into v_visit
from protocol a,
     sideshow_eav b,
     variable c
where a.protocol_id=b.protocol_id
  and a.protocol_id=c.protocol_id
  and c.variable_id=b.variable_id
  and a.protocol_id=v_protocolid
  and b.subject_id=v_subjectid
  AND decode(upper(c.variable_name),'VISIT',b.value,decode(upper(c.variable_name),'PERIOD',B.VALUE)) IS NOT NULL
  and exists (select ''
               from variable d
              where d.protocol_id=a.protocol_id
                and d.variable_id=v_variableid
                and d.dataset_name=c.dataset_name);
   RETURN v_visit;
END Sf_Get_Visit;
 
 
 
 
 
 
 
 
 
/
 
