--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_WRITE_INFO
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."CZX_WRITE_INFO" 
(
  v_job_id IN NUMBER DEFAULT NULL ,
  v_message_id IN NUMBER DEFAULT NULL ,
  v_message_line IN NUMBER DEFAULT NULL ,
  v_message_procedure IN VARCHAR2 DEFAULT NULL ,
  v_info_message IN VARCHAR2 DEFAULT NULL
)
AUTHID CURRENT_USER
AS
-------------------------------------------------------------------------------------
-- NAME: CZX_WRITE_INFO
--
-- Copyright c 2011 Recombinant Data Corp.
--

--------------------------------------------------------------------------------------
BEGIN

   INSERT INTO cz_job_message
     ( job_id, message_id, message_line, message_procedure, info_message )
     VALUES ( v_job_id, v_message_id, v_message_line, v_message_procedure, v_info_message );
END;
/
 
