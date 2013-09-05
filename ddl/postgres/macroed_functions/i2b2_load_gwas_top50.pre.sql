<?php
    $RETURN_METHOD = 'RETURN'; /* RETURN or OUTVAR */
    require __DIR__ . '/../_scripts/macros.php';
?>
CREATE OR REPLACE FUNCTION tm_cz.i2b2_load_gwas_top50(
    currentJobID bigint DEFAULT null
)
RETURNS BIGINT AS $body$
DECLARE
    <?php standard_vars() ?>
BEGIN
    <?php func_start('I2B2_LOAD_GWAS_TOP50') ?>

    -- Create temporary table tmp_analysis_gwas_top500
    <?php step_begin() ?>
    CREATE TABLE tmp_analysis_gwas_top500 AS
    SELECT
        a.*
    FROM (
            SELECT
                bio_asy_analysis_gwas_id,
                bio_assay_analysis_id,
                rs_id,
                p_value,
                log_p_value,
                etl_id,
                ext_data,
                p_value_char,
                ROW_NUMBER ( )
                OVER ( PARTITION BY
                        bio_assay_analysis_id
                    ORDER BY
                        p_value ASC,
                        rs_id ASC ) AS rnum
            FROM
                BIOMART.bio_assay_analysis_gwas
        )
        a
    WHERE
        a.rnum <= 500;
    <?php step_end('Create temporary table tmp_analysis_gwas_top500') ?>

    -- Create indexes on tmp_analysis_gwas_top500
    <?php step_begin() ?>
    CREATE INDEX t_a_g_t500_idx ON tmp_analysis_gwas_top500(rs_id);
    CREATE INDEX t_a_ga_t500_idx ON tmp_analysis_gwas_top500(bio_assay_analysis_id);
    <?php step_end('Create indexes on tmp_analysis_gwas_top500', 0) ?>

    -- Drop table biomart.bio_asy_analysis_gwas_top50
    <?php step_begin() ?>
    SELECT COUNT(*) INTO rowCt FROM biomart.bio_asy_analysis_gwas_top50;
    DROP TABLE biomart.bio_asy_analysis_gwas_top50;
    <?php step_end('Drop table biomart.bio_asy_analysis_gwas_top50', 'rowCt') ?>

    -- Recreate table biomart.bio_asy_analysis_gwas_top50
    <?php step_begin() ?>
    CREATE TABLE biomart.bio_asy_analysis_gwas_top50 AS
    SELECT
        baa.bio_assay_analysis_id,
        baa.analysis_name AS analysis,
        info.chrom AS chrom,
        info.pos AS pos,
        gmap.gene_name AS rsgene,
        DATA.rs_id AS rsid,
        DATA.p_value AS pvalue,
        DATA.log_p_value AS logpvalue,
        DATA.ext_data AS extdata,
        DATA.rnum
    FROM
        biomart.tmp_analysis_gwas_top500 DATA
        JOIN biomart.bio_assay_analysis baa ON baa.bio_assay_analysis_id = DATA.bio_assay_analysis_id
        JOIN deapp.de_rc_snp_info info ON DATA.rs_id = info.rs_id
            AND ( hg_version = 19 )
        LEFT JOIN deapp.de_snp_gene_map gmap ON gmap.snp_name = info.rs_id;
    <?php step_end('Recreate table biomart.bio_asy_analysis_gwas_top50') ?>

    -- Recreate indexes on biomart.bio_asy_analysis_gwas_top50
    <?php step_begin() ?>
    CREATE INDEX b_asy_gwas_t50_idx1 ON biomart.bio_asy_analysis_gwas_top50(bio_assay_analysis_id) TABLESPACE indx;
    CREATE INDEX b_asy_gwas_t50_idx2 ON biomart.bio_asy_analysis_gwas_top50(analysis) TABLESPACE indx;
    <?php step_end('Recreate indexes on biomart.bio_asy_analysis_gwas_top50', 0) ?>

    <?php func_end() ?>
END;
$body$
LANGUAGE PLPGSQL;
<?php // vim: ts=4 sts=4 sw=4 et:
?>
