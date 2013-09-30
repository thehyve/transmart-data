<?php
    $RETURN_METHOD = 'RETURN'; /* RETURN or OUTVAR */
    require __DIR__ . '/../_scripts/macros.php';
?>

CREATE OR REPLACE FUNCTION tm_cz.i2b2_load_eqtl_top50 (
  currentJobID bigint DEFAULT null
) RETURNS BIGINT AS $body$
DECLARE
    <?php standard_vars() ?>
BEGIN
    <?php func_start('I2B2_LOAD_EQTL_TOP50') ?>

    -- Create tmp_analysis_count_eqtl
    <?php step_begin() ?>
    DROP TABLE IF EXISTS biomart.tmp_analysis_count_eqtl;
    CREATE TABLE biomart.tmp_analysis_count_eqtl AS
    SELECT
        COUNT ( * ) AS total,
        bio_assay_analysis_id
    FROM
        biomart.bio_assay_analysis_eqtl
    GROUP BY
        bio_assay_analysis_id;
    <?php step_end('Create temporary table tmp_analysis_count_eqtl') ?>


    -- Update biomart.bio_assay_analysis
    <?php step_begin() ?>
    UPDATE biomart.bio_assay_analysis b
    SET
        data_count = (
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
    <?php step_end('Update biomart.bio_assay_analysis') ?>


    -- Create temporary table tmp_analysis_eqtl_top500
    <?php step_begin() ?>
    DROP TABLE IF EXISTS tmp_analysis_eqtl_top500;
    CREATE TABLE biomart.tmp_analysis_eqtl_top500 AS
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
    <?php step_end('Create temporary table tmp_analysis_eqtl_top500') ?>


    -- Create indexes on temporary table
    <?php step_begin() ?>
    CREATE INDEX t_a_ge_t500_idx ON biomart.tmp_analysis_eqtl_top500(rs_id);
    CREATE INDEX t_a_gae_t500_idx ON biomart.tmp_analysis_eqtl_top500(bio_assay_analysis_id);
    <?php step_end('Create indexes on temporary table', 0) ?>


    -- drop biomart.bio_asy_analysis_eqtk_top50
    <?php step_begin() ?>
    DROP TABLE IF EXISTS biomart.bio_asy_analysis_eqtl_top50 CASCADE;
    <?php step_end('Drop biomart.bio_asy_analysis_eqtl_top50') ?>


    -- recreate biomart.bio_asy_analysis_eqtk_top50
    <?php step_begin() ?>
    CREATE TABLE biomart.bio_asy_analysis_eqtl_top50 AS
    SELECT
        baa.bio_assay_analysis_id,
        baa.analysis_name AS analysis,
        info.chrom AS chrom,
        info.pos AS pos,
        gmap.snp_name AS rsgene,
        DATA.rs_id AS rsid,
        DATA.p_value AS pvalue,
        DATA.log_p_value AS logpvalue,
        data.gene AS gene,
        DATA.ext_data AS extdata,
        DATA.rnum
    FROM
        biomart.tmp_analysis_eqtl_top500 DATA
        JOIN biomart.bio_assay_analysis baa ON baa.bio_assay_analysis_id = DATA.bio_assay_analysis_id
        JOIN deapp.de_rc_snp_info info ON DATA.rs_id = info.rs_id
            AND ( hg_version = '19' )
        LEFT JOIN deapp.de_snp_gene_map gmap ON gmap.snp_name = info.rs_id;
    <?php step_end('Recreate biomart.bio_asy_analysys_eqtl_top50') ?>


    -- Recreate indexes on biomart.bio_asy_analysis_eqtl_top50
    <?php step_begin() ?>
    CREATE INDEX b_asy_eqtl_t50_idx1
        ON biomart.bio_asy_analysis_eqtl_top50(bio_assay_analysis_id) TABLESPACE indx;
    CREATE INDEX b_asy_eqtl_t50_idx2
        ON biomart.bio_asy_analysis_eqtl_top50(analysis) TABLESPACE indx;
    <?php step_end('Create indexes on biomart.bio_asy_analysis_eqtl_top50', 0) ?>

    <?php func_end() ?>
END;
$body$
LANGUAGE PLPGSQL;
<?php // vim: ts=4 sts=4 sw=4 et:
?>
