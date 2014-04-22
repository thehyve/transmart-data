--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_START_AUDIT
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."CZX_START_AUDIT" 
(V_JOB_NAME IN VARCHAR2 DEFAULT NULL ,
  V_DATABASE_NAME IN VARCHAR2 DEFAULT NULL ,
  V_JOB_ID OUT NUMBER)
  AUTHID CURRENT_USER  
IS 
  PRAGMA AUTONOMOUS_TRANSACTION;
-------------------------------------------------------------------------------------
-- NAME: CZX_START_AUDIT
--
-- Copyright c 2011 Recombinant Data Corp.
--

--------------------------------------------------------------------------------------

BEGIN
   INSERT INTO CZ_JOB_MASTER
     ( START_DATE, 
		ACTIVE, 
		USERNAME,
		SESSION_ID, 
		DATABASE_NAME, 
		JOB_NAME, 
		JOB_STATUS )
     VALUES (
		SYSDATE, 
		'Y', 
		USER, 
		UID, 
		V_DATABASE_NAME, 
		V_JOB_NAME, 
		'Running' )

	RETURNING JOB_ID INTO V_JOB_ID;
	
	COMMIT;
  
EXCEPTION
    WHEN OTHERS THEN ROLLBACK;
END;
/
