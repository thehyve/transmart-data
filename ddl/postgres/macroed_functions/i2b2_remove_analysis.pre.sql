<?php
    $RETURN_METHOD = 'RETURN'; /* RETURN or OUTVAR */
    require __DIR__ . '/../_scripts/macros.php';
?>
CREATE OR REPLACE FUNCTION tm_cz.i2b2_remove_analysis (
    etlID bigint,
    currentJobID bigint DEFAULT null
)
RETURNS BIGINT AS $body$
DECLARE
    <?php standard_vars() ?>

    analysis_id bigint;
    E_ID        bigint;
BEGIN
    E_ID := etlID;
    <?php func_start('I2B2_REMOVE_ANALYSIS') ?>

    --get etl_id
    SELECT bio_assay_analysis_id
    INTO analysis_id
    FROM BIOMART.BIO_ASSAY_ANALYSIS
    WHERE ETL_ID_SOURCE = E_ID;

    --delete data from bio_assay_analysis_data
    <?php step_begin() ?>
    DELETE FROM biomart.bio_assay_analysis_data
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_assay_analysis_data') ?>

    --delete data from bio_assay_analysis_data_tea
    <?php step_begin() ?>
    DELETE FROM biomart.bio_assay_analysis_data_tea
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_assay_analysis_data_tea') ?>

    --delete data from bio_asy_analysis_dataset
    <?php step_begin() ?>
    DELETE FROM biomart.bio_asy_analysis_dataset
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_assay_analysis_dataset') ?>

    --delete from bio_assay_analysis_EQTL
    <?php step_begin() ?>
    DELETE from biomart.bio_assay_analysis_eqtl where bio_assay_analysis_id=analysis_id;
    <?php step_end('Delete existing data in bio_assay_analysis_eqtl') ?>

    --delete from bio_assay_analysis_EXT
    <?php step_begin() ?>
    DELETE FROM biomart.bio_assay_analysis_ext
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_assay_analysis_ext') ?>

    --delete from bio_assay_analysis_GWAS
    <?php step_begin() ?>
    DELETE FROM biomart.bio_assay_analysis_gwas
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_assay_analysis_gwas') ?>

    --delete from bio_asy_analysis_EQTL_TOP50
    <?php step_begin() ?>
    DELETE FROM biomart.bio_asy_analysis_eqtl_top50
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_asy_analysis_eqtl_top50') ?>

    --delete from bio_asy_analysis_gwas_top50
    <?php step_begin() ?>
    DELETE FROM biomart.bio_asy_analysis_gwas_top50
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing data in bio_asy_analysis_gwas_top50') ?>

    --delete from bio_data_observation
    <?php step_begin() ?>
    DELETE FROM biomart.bio_data_observation
    WHERE bio_data_id = analysis_id;
    <?php step_end('Delete existing metadata in bio_data_observation') ?>

    --delete from bio_data_platform
    <?php step_begin() ?>
    DELETE FROM biomart.bio_data_platform
    WHERE bio_data_id = analysis_id;
    <?php step_end('Delete existing metadata in bio_data_platform') ?>

    --delete from bio_data_disease
    <?php step_begin() ?>
    DELETE FROM biomart.bio_data_disease
    WHERE bio_data_id = analysis_id;
    <?php step_end('Delete existing metadata in bio_data_disease') ?>

    --delete from bio_assay_analysis
    <?php step_begin() ?>
    DELETE FROM biomart.bio_assay_analysis
    WHERE bio_assay_analysis_id = analysis_id;
    <?php step_end('Delete existing metadata in bio_assay_analysis') ?>

    --delete from tm_lz.lz_src_analysis_metadata
    <?php step_begin() ?>
    DELETE FROM lz_src_analysis_metadata
    WHERE ETL_ID = etlID;
    <?php step_end('Delete existing metadata in lz_src_study_metadata') ?>

    <?php func_end() ?>
END;

$body$
LANGUAGE PLPGSQL;

<?php // vim: ft=plsql ts=4 sts=4 sw=4 et:
?>

