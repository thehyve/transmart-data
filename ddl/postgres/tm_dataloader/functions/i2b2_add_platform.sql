--
-- Name: i2b2_add_platform(character varying, character varying, character varying, character varying, character varying, character varying, numeric); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION i2b2_add_platform(gpl_id character varying, name character varying, organism character varying, marker_type character varying, genome_build character varying DEFAULT NULL::character varying, release_nbr character varying DEFAULT NULL::character varying, currentjobid numeric DEFAULT '-1'::integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
  DECLARE
    jobID         NUMERIC(18, 0);
    databaseName  VARCHAR(100);
    procedureName VARCHAR(100);
    rowCt         NUMERIC(18, 0);
    stepCt        NUMERIC(18, 0);
    rtnCd         NUMERIC;

  BEGIN
    databaseName := current_schema();
    procedureName := 'I2B2_ADD_PLATFORM';

    stepCt := 0;

    SELECT CASE
      WHEN COALESCE(currentjobid, -1) < 1
      THEN cz_start_audit(procedureName, databaseName)
      ELSE currentjobid END
      INTO jobID;

    stepCt := stepCt + 1;
    PERFORM cz_write_audit(jobId, databaseName, procedureName, 'Starting ' || procedureName || ' for ' || gpl_id, 0, stepCt, 'Done');

    INSERT INTO deapp.de_gpl_info (platform, title, organism, annotation_date, marker_type, genome_build, release_nbr)
    VALUES
      (gpl_id, "name", organism, current_timestamp, marker_type, genome_build, release_nbr);
    get diagnostics rowCt := ROW_COUNT;

    stepCt := stepCt + 1;
    PERFORM cz_write_audit(jobId, databaseName, procedureName, 'Add platform ' || gpl_id, rowCt, stepCt, 'Done');

    stepCt := stepCt + 1;
    PERFORM cz_write_audit(jobId, databaseName, procedureName, 'End ' || procedureName, 0, stepCt, 'Done');

    PERFORM cz_end_audit(jobID, 'SUCCESS') WHERE COALESCE(currentjobid, -1) <> jobID;

    RETURN 1;

    EXCEPTION
    WHEN OTHERS THEN
      SELECT cz_write_error(jobId, SQLSTATE, SQLERRM, NULL, NULL)
      INTO rtnCd;
      RETURN -16;
  END;
  $$;

