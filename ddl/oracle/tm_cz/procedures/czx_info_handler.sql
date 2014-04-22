--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_INFO_HANDLER
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."CZX_INFO_HANDLER" 
(
  jobId IN NUMBER,
  messageID IN NUMBER ,
  messageLine IN NUMBER,
  messageProcedure IN VARCHAR2 ,
  infoMessage IN VARCHAR2,
  stepNumber IN VARCHAR2
)
AUTHID CURRENT_USER
AS
-------------------------------------------------------------------------------------
-- NAME: CZX_INFO_HANDLER
--
-- Copyright c 2011 Recombinant Data Corp.
--

--------------------------------------------------------------------------------------	
  databaseName VARCHAR2(100);
BEGIN

  select
    database_name INTO databasename
  from
    cz_job_master
  where
    job_id=jobID;

  czx_write_audit( jobID, databaseName, messageProcedure, 'Step contains more details', 0, stepNumber, 'Information' );

  czx_write_info(jobID, messageID, messageLine, messageProcedure, infoMessage );

END;
/
