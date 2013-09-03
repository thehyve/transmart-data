<?php
    $RETURN_METHOD = 'RETURN'; /* RETURN or OUTVAR */
    require __DIR__ . '/../_scripts/macros.php';
?>
CREATE OR REPLACE FUNCTION tm_cz.i2b2_remove_study (
	study_id		IN	text,
	currentjobID	IN	bigint DEFAULT null
)
RETURNS BIGINT AS $body$
DECLARE
     -- not tested yet zhanh101 5/23/2013

    <?php standard_vars() ?>

    topNode             varchar(2000);
    etl_id              varchar(2000);
    etl_source_id       varchar(2000);
    v_bio_experiment_id bigint;
    StudyID             text;
    v_result            integer;
    r_delAnalysis       record;
    tText               text;
BEGIN
	StudyID := upper(study_id);

    <?php func_start('I2B2_REMOVE_STUDY') ?>

	tText := 'Start i2b2_remove_study for ' || StudyID;
	PERFORM tm_cz.cz_write_audit(jobID, databaseName, procedureName, tText, 0, stepCt, 'Done');
    stepCt := stepCt + 1;

	--get topNode
    SELECT c_fullname
    INTO topNode
    FROM i2b2metadata.i2b2
    WHERE
        sourcesystem_CD = StudyID
        AND c_hlevel = 1;

	IF topNode IS NOT NULL AND topNode::text <> '' THEN
        tText := 'About to call i2b2_backout_trial with arguments study_id = ' ||
                StudyID || ', topNode = ' || topNode || ', jobID = ' || jobID;
		PERFORM tm_cz.cz_write_audit(jobID, databaseName, procedureName, tText, 0, stepCt, 'Done');
        stepCt := stepCt + 1;

		--execute i2b2_backout_trial;
        <?php step_begin() ?>
        SELECT tm_cz.i2b2_backout_trial(StudyID, topNode, jobID) INTO v_result;
        IF v_result < 0 THEN
            PERFORM tm_cz.cz_error_handler(jobID, procedureName, '', 'Call to i2b2_backout_trial failed');
            PERFORM tm_cz.cz_end_audit (jobID, 'FAIL');
            RETURN -16;
        END IF;
        <?php step_end('Call to i2b2_backout_trial') ?>
	END IF;

	--get analysis associated
	 FOR r_delAnalysis IN
            SELECT ETL_ID_source
            FROM bio_assay_analysis
            WHERE ETL_ID = study_id LOOP

        --	deletes hidden nodes for a trial one at a time
        tText := 'About to call i2b2_remove_analysis with arguments ETL_ID_SOURCE=' ||
                r_delAnalysis.ETL_ID_source || ', jobID=' || jobID;
		PERFORM tm_cz.cz_write_audit(jobID, databaseName, procedureName, tText, 0, stepCt, 'Done');
        stepCt := stepCt + 1;

        <?php step_begin() ?>
		SELECT tm_cz.i2b2_remove_analysis(r_delAnalysis.ETL_ID_source, jobID) INTO v_result;
        IF v_result < 0 THEN
            PERFORM tm_cz.cz_error_handler(jobID, procedureName, '', 'Call to i2b2_remove_analysis failed');
            PERFORM tm_cz.cz_end_audit (jobID, 'FAIL');
            RETURN -16;
        END IF;
        <?php step_end("'Call to i2b2_remove_analysis for ETL_ID_SOURCE=' || r_delAnalysis.ETL_ID_source") ?>
	END LOOP;

    -- delete entries in bio_experiment and bio_clinical_trial
    SELECT bio_experiment_id
    INTO v_bio_experiment_id
    FROM biomart.bio_experiment
    WHERE accession = study_id;

    tText := 'Using bio_experiment_id = ' || v_bio_experiment_id;
    PERFORM tm_cz.cz_write_audit(jobID, databaseName, procedureName, tText, 0, stepCt, 'Done');
    stepCt := stepCt + 1;

    <?php step_begin() ?>
    DELETE FROM bio_experiment
    WHERE bio_experiment_id = v_bio_experiment_id;
    <?php step_end('Delete from bio_experiment') ?>

    <?php step_begin() ?>
    DELETE FROM bio_clinical_trial
    WHERE bio_experiment_id = v_bio_experiment_id;
    <?php step_end('Delete from bio_clinical_trial') ?>

    <?php func_end() ?>
END;
$body$
LANGUAGE PLPGSQL;

<?php // vim: ft=plsql ts=4 sts=4 sw=4 et:
?>
