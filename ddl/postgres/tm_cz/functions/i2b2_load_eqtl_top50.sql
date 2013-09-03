-----------------------------------------------------------------------
--             DO NOT EDIT THIS FILE. IT IS AUTOGENERATED            --
-- Edit the original file in the macroed_functions directory instead --
-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION tm_cz.i2b2_load_eqtl_top50 (
  currentJobID bigint DEFAULT null
) RETURNS BIGINT AS $body$
DECLARE
    newJobFlag    smallint;
    databaseName  varchar(100);
    procedureName varchar(100);
    jobID         bigint;
    stepCt        bigint;
    rowCt         bigint;
    errorNumber   varchar;
    errorMessage  varchar;
BEGIN
    --Set Audit Parameters
    newJobFlag := 0; -- False (Default)
    jobID := currentJobID;
    SELECT current_user INTO databaseName; --(sic)
    procedureName := 'I2B2_LOAD_EQTL_TOP50';

    --Audit JOB Initialization
    --If Job ID does not exist, then this is a single procedure run and we need to create it
    IF (coalesce(jobID::text, '') = '' OR jobID < 1)
        THEN
        newJobFlag := 1; -- True
        SELECT cz_start_audit(procedureName, databaseName) INTO jobID;
    END IF;
    PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Start FUNCTION', 0, stepCt, 'Done');
    stepCt := 1;

    -- Create tmp_analysis_count_eqtl
    BEGIN
    CREATE TEMPORARY TABLE tmp_analysis_count_eqtl AS
    SELECT
        COUNT ( * ) AS total,
        bio_assay_analysis_id
    FROM
        biomart.bio_assay_analysis_eqtl
    GROUP BY
        bio_assay_analysis_id;
    GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Create temporary table tmp_analysis_count_eqtl', rowCt, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;


    -- Update biomart.bio_assay_analysis
    BEGIN
    UPDATE biomart.bio_assay_analysis b
    SET
        b.data_count = (
            SELECT
                a.total
            FROM
                biomart.tmp_analysis_count_eqtl a
            WHERE
                a.bio_assay_analysis_id = b.bio_assay_analysis_id )
    WHERE
        EXISTS (
            SELECT
                1
            FROM
                biomart.tmp_analysis_count_eqtl a
            WHERE
                a.bio_assay_analysis_id = b.bio_assay_analysis_id );
    GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Update biomart.bio_assay_analysis', rowCt, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;


    -- Create temporary table tmp_analysis_eqtl_top500
    BEGIN
    CREATE TEMPORARY TABLE tmp_analysis_eqtl_top500 AS
    SELECT
        a.*
    FROM (
            SELECT
                bio_asy_analysis_eqtl_id,
                bio_assay_analysis_id,
                rs_id,
                p_value,
                log_p_value,
                etl_id,
                ext_data,
                p_value_char,
                gene,
                cis_trans,
                distance_from_gene,
                ROW_NUMBER ( )
                OVER ( PARTITION BY
                        bio_assay_analysis_id
                    ORDER BY
                        p_value ASC,
                        rs_id ASC ) AS rnum
            FROM
                biomart.bio_assay_analysis_eqtl )
        a
    WHERE
        a.rnum <= 500;
    GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Create temporary table tmp_analysis_eqtl_top500', rowCt, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;


    -- Create indexes on temporary table
    BEGIN
    CREATE INDEX t_a_ge_t500_idx ON tmp_analysis_eqtl_top500(rs_id);
    CREATE INDEX t_a_gae_t500_idx ON tmp_analysis_eqtl_top500(bio_assay_analysis_id);
    PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Create indexes on temporary table', 0, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;


    -- drop biomart.bio_asy_analysis_eqtk_top50
    BEGIN
    DROP TABLE biomart.bio_asy_analysis_eqtl_top50 CASCADE;
    GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Drop biomart.bio_asy_analysis_eqtl_top50', rowCt, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;


    -- recreate biomart.bio_asy_analysis_eqtk_top50
    BEGIN
    CREATE TABLE biomart.bio_asy_analysis_eqtl_top50 AS
    SELECT
        baa.bio_assay_analysis_id,
        baa.analysis_name AS analysis,
        info.chrom AS chrom,
        info.pos AS pos,
        gmap.gene_name AS rsgene,
        DATA.rs_id AS rsid,
        DATA.p_value AS pvalue,
        DATA.log_p_value AS logpvalue,
        data.gene AS gene,
        DATA.ext_data AS extdata,
        DATA.rnum
    FROM
        tmp_analysis_eqtl_top500 DATA
        JOIN biomart.bio_assay_analysis baa ON baa.bio_assay_analysis_id = DATA.bio_assay_analysis_id
        JOIN deapp.de_rc_snp_info info ON DATA.rs_id = info.rs_id
            AND ( hg_version = 19 )
        LEFT JOIN deapp.de_snp_gene_map gmap ON gmap.snp_name = info.rs_id;
    GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Recreate biomart.bio_asy_analysys_eqtl_top50', rowCt, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;


    -- Recreate indexes on biomart.bio_asy_analysis_eqtl_top50
    BEGIN
    CREATE INDEX b_asy_eqtl_t50_idx1
        ON biomart.bio_asy_analysis_eqtl_top50(bio_assay_analysis_id) TABLESPACE indx;
    CREATE INDEX b_asy_eqtl_t50_idx2
        ON biomart.bio_asy_analysis_eqtl_top50(analysis) TABLESPACE indx;
    PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'Create indexes on biomart.bio_asy_analysis_eqtl_top50', 0, stepCt, 'Done');
    stepCt := stepCt + 1;
    EXCEPTION
        WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
    END;

    -- Cleanup OVERALL JOB if this proc is being run standalone
    IF newJobFlag = 1 THEN
        PERFORM cz_end_audit(jobID, 'SUCCESS');
    END IF;

    RETURN 0;
EXCEPTION
    WHEN OTHERS THEN
        errorNumber := SQLSTATE;
        errorMessage := SQLERRM;
        PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
        PERFORM cz_end_audit (jobID, 'FAIL');
        RETURN -16;
END;
$body$
LANGUAGE PLPGSQL;
