<?php
    $RETURN_METHOD = 'RETURN'; /* RETURN or OUTVAR */
    require __DIR__ . '/../_scripts/macros.php';
?>
CREATE OR REPLACE FUNCTION tm_cz.i2b2_load_study_metadata (
    currentJobID bigint DEFAULT null
)
RETURNS BIGINT AS $body$
DECLARE

/*************************************************************************
* Copyright 2008-2012 Janssen Research n, LLC.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
******************************************************************/

    <?php standard_vars() ?>

    dcount           integer;
    lcount           integer;
    upload_date      timestamp;
    tmp_compound     varchar(200);
    tmp_disease      varchar(200);
    tmp_organism     varchar(200);
    tmp_pubmed       varchar(200);
    pubmed_id        varchar(200);
    pubmed_title     varchar(200);
    study_compound   record;
    study_disease    record;
    study_taxonomy   record;
    study_pubmed     record;
BEGIN
    <?php func_start('I2B2_LOAD_STUDY_METADATA') ?>

    SELECT LOCALTIMESTAMP INTO upload_date;

    --    delete existing metadata from lz_src_study_metadata
    <?php step_begin() ?>
    DELETE
    FROM
        lz_src_study_metadata
    WHERE
        study_id IN (
            SELECT
                DISTINCT study_id
            FROM
                lt_src_study_metadata );
    <?php step_end('Delete existing metadata in lz_src_study_metadata') ?>

    --    insert metadata into lz_src_study_metadata
    <?php step_begin() ?>
    INSERT INTO lz_src_study_metadata
    SELECT
        x.*,
        upload_date
    FROM
        lt_src_study_metadata x;
    <?php step_end('Insert data into lz_src_study_metadata from lt_src_study_metadata') ?>

    --    delete existing metadata from lz_src_study_metadata_ad_hoc
    <?php step_begin() ?>
    DELETE
    FROM
        lz_src_study_metadata_ad_hoc
    WHERE
        study_id IN (
            SELECT
                DISTINCT study_id
            FROM
                lt_src_study_metadata );

    <?php step_end('Delete existing metadata in lz_src_study_metadata_ad_hoc') ?>

    --    insert metadata into lz_src_study_metadata_ad_hoc
    <?php step_begin() ?>
    INSERT INTO lz_src_study_metadata_ad_hoc
    SELECT
        x.*,
        upload_date
    FROM
        lt_src_study_metadata_ad_hoc x;
    <?php step_end('Insert data in lz_src_study_metadata_ad_hoc') ?>

    --    Update existing bio_experiment data
    <?php step_begin() ?>
    UPDATE biomart.bio_experiment b
    SET ( title,
            description,
            design,
            start_date,
            completion_date,
            primary_investigator,
            overall_design,
            institution,
            country )
        = ( m.title,
            m.description,
            m.design,
            ( CASE is_date ( m.start_date )
                    WHEN 1 THEN NULL
                    ELSE TO_DATE ( m.start_date, 'YYYYMMDD' )
                END ),
            ( CASE is_date ( m.completion_date )
                    WHEN 1 THEN NULL
                    ELSE TO_DATE ( m.completion_date, 'YYYYMMDD' )
                END ),
            COALESCE ( m.primary_investigator, m.study_owner ),
            COALESCE ( SUBSTR ( ( CASE
                            WHEN m.primary_end_points IS NULL THEN NULL
                            WHEN m.primary_end_points = 'N/A' THEN NULL
                            ELSE m.primary_end_points
                        END )
                    || ( CASE
                            WHEN m.inclusion_criteria IS NULL THEN NULL
                            WHEN m.inclusion_criteria = 'N/A' THEN NULL
                            ELSE ' Inclusion Criteria: ' || m.inclusion_criteria
                        END )
                    || ( CASE
                            WHEN m.exclusion_criteria IS NULL THEN NULL
                            WHEN m.exclusion_criteria = 'N/A' THEN NULL
                            ELSE ' Exclusion Criteria: ' || m.exclusion_criteria
                        END ),
                    1,
                    2000 ), -- end SUBSTR
                m.overall_design ),
            m.institution,
            m.country )
    FROM
        tm_lz.lt_src_study_metadata m
    WHERE ( m.study_id IS NOT NULL
        AND m.study_id ::TEXT <> '' )
        AND b.accession = m.study_id
        AND b.etl_id = 'METADATA:' || m.study_id;
    <?php step_end('Updated trial data in BIOMART bio_experiment') ?>

    --    Update existing bio_clinical_trial data only for true Clinical Trials or JnJ Experimental Medicine Studies
    <?php step_begin() ?>
    UPDATE biomart.bio_clinical_trial b
    SET ( study_owner,
            study_phase,
            blinding_procedure,
            studytype,
            duration_of_study_weeks,
            number_of_patients,
            number_of_sites,
            route_of_administration,
            dosing_regimen,
            group_assignment,
            type_of_control,
            completion_date,
            primary_end_points,
            secondary_end_points,
            inclusion_criteria,
            exclusion_criteria,
            subjects,
            gender_restriction_mfb,
            min_age,
            max_age,
            secondary_ids,
            development_partner,
            main_findings,
            geo_platform,
            --,platform_name
            search_area )
        = ( m.study_owner,
            m.study_phase,
            m.blinding_procedure,
            m.studytype,
            ( CASE is_numeric ( m.duration_of_study_weeks )
                    WHEN 1 THEN NULL
                    ELSE m.duration_of_study_weeks::NUMERIC
                END ),
            ( CASE is_numeric ( m.number_of_patients )
                    WHEN 1 THEN NULL
                    ELSE m.number_of_patients::NUMERIC
                END ),
            ( CASE is_numeric ( m.number_of_sites )
                    WHEN 1 THEN NULL
                    ELSE m.number_of_sites::NUMERIC
                END ),
            m.route_of_administration,
            m.dosing_regimen,
            m.group_assignment,
            m.type_of_control,
            ( CASE is_date ( m.completion_date )
                    WHEN 1 THEN NULL
                    ELSE TO_DATE ( m.completion_date, 'YYYYMMDD' )
                END ),
            m.primary_end_points,
            m.secondary_end_points,
            m.inclusion_criteria,
            m.exclusion_criteria,
            m.subjects,
            m.gender_restriction_mfb,
            ( CASE is_numeric ( m.min_age )
                    WHEN 1 THEN NULL
                    ELSE m.min_age::NUMERIC
                END ),
            ( CASE is_numeric ( m.max_age )
                    WHEN 1 THEN NULL
                    ELSE m.max_age::NUMERIC
                END ),
            m.secondary_ids,
            m.development_partner,
            m.main_findings,
            m.geo_platform,
            --,m.platform_name
            m.search_area )
        FROM
            tm_lz.lt_src_study_metadata m
        WHERE ( m.study_id IS NOT NULL AND m.study_id ::TEXT <> '' )
            AND b.trial_number = m.study_id;
    <?php step_end('Updated trial data in BIOMART bio_clinical_trial') ?>

    --    Add new trial data to bio_experiment
    <?php step_begin() ?>
    INSERT INTO biomart.bio_experiment (
        bio_experiment_type,
        title,
        description,
        design,
        start_date,
        completion_date,
        primary_investigator,
        contact_field,
        etl_id,
        status,
        overall_design,
        accession,
        country,
        institution )
    SELECT
        'Experiment',
        m.title,
        m.description,
        m.design,
        ( CASE is_date ( m.start_date )
                WHEN 1 THEN NULL
                ELSE TO_DATE ( m.start_date, 'YYYYMMDD' )
            END ),
        ( CASE is_date ( m.completion_date )
                WHEN 1 THEN NULL
                ELSE TO_DATE ( m.completion_date, 'YYYYMMDD' )
            END ),
        COALESCE ( m.primary_investigator, m.study_owner ),
        m.contact_field,
        'METADATA:' || m.study_id,
        m.study_id,
        COALESCE ( ( CASE
                    WHEN m.primary_end_points IS NULL THEN NULL
                    WHEN m.primary_end_points = 'N/A' THEN NULL
                    ELSE REPLACE ( m.primary_end_points,
                        '"',
                        '' )
                END )
            || ( CASE
                    WHEN m.inclusion_criteria IS NULL THEN NULL
                    WHEN m.inclusion_criteria = 'N/A' THEN NULL
                    ELSE ' Inclusion Criteria: ' || REPLACE ( m.inclusion_criteria,
                        '"',
                        '' )
                END )
            || ( CASE
                    WHEN m.exclusion_criteria IS NULL THEN NULL
                    WHEN m.exclusion_criteria = 'N/A' THEN NULL
                    ELSE ' Exclusion Criteria: ' || REPLACE ( m.exclusion_criteria,
                        '"',
                        '' )
                END ),
            m.overall_design ),
        m.study_id,
        m.country,
        m.institution
    FROM
        lt_src_study_metadata m
    WHERE ( m.study_id IS NOT NULL
        AND m.study_id::TEXT <> '' )
        AND NOT EXISTS (
            SELECT
                1
            FROM
                biomart.bio_experiment x
            WHERE
                m.study_id = x.accession
                AND ( m.study_id IS NOT NULL
                    AND m.study_id::TEXT <> '' ) );
    <?php step_end('Inserted trial data in BIOMART bio_experiment') ?>

    --    Add new trial data to bio_clinical_trial
    <?php step_begin() ?>
    INSERT INTO biomart.bio_clinical_trial (
        trial_number,
        study_owner,
        study_phase,
        blinding_procedure,
        studytype,
        duration_of_study_weeks,
        number_of_patients,
        number_of_sites,
        route_of_administration,
        dosing_regimen,
        group_assignment,
        type_of_control,
        completion_date,
        primary_end_points,
        secondary_end_points,
        inclusion_criteria,
        exclusion_criteria,
        subjects,
        gender_restriction_mfb,
        min_age,
        max_age,
        secondary_ids,
        bio_experiment_id,
        development_partner,
        main_findings,
        geo_platform,
        --platform_name,
        search_area )
    SELECT
        m.study_id,
        m.study_owner,
        m.study_phase,
        m.blinding_procedure,
        m.studytype,
        ( CASE is_numeric ( m.duration_of_study_weeks )
                WHEN 1 THEN NULL
                ELSE m.duration_of_study_weeks ::NUMERIC
            END ),
        ( CASE is_numeric ( m.number_of_patients )
                WHEN 1 THEN NULL
                ELSE m.number_of_patients ::NUMERIC
            END ),
        ( CASE is_numeric ( m.number_of_sites )
                WHEN 1 THEN NULL
                ELSE m.number_of_sites ::NUMERIC
            END ),
        m.route_of_administration,
        m.dosing_regimen,
        m.group_assignment,
        m.type_of_control,
        ( CASE is_date ( m.completion_date )
                WHEN 1 THEN NULL
                ELSE TO_DATE ( m.completion_date, 'YYYYMMDD' )
            END ),
        m.primary_end_points,
        m.secondary_end_points,
        m.inclusion_criteria,
        m.exclusion_criteria,
        m.subjects,
        m.gender_restriction_mfb,
        ( CASE is_numeric ( m.min_age )
                WHEN 1 THEN NULL
                ELSE m.min_age ::NUMERIC
            END ),
        ( CASE is_numeric ( m.max_age )
                WHEN 1 THEN NULL
                ELSE m.max_age ::NUMERIC
            END ),
        m.secondary_ids,
        b.bio_experiment_id,
        m.development_partner,
        m.main_findings,
        m.geo_platform, --,m.platform_name
        m.search_area
    FROM
        tm_lz.lt_src_study_metadata m,
        biomart.bio_experiment b
    WHERE ( m.study_id IS NOT NULL
        AND m.study_id ::TEXT <> '' )
        AND m.study_id = b.accession
        AND NOT EXISTS (
            SELECT
                1
            FROM
                biomart.bio_clinical_trial x
            WHERE
                m.study_id = x.trial_number );
    <?php step_end('Inserted trial data in BIOMART bio_clinical_trial') ?>

    --    Insert new trial into bio_data_uid
    <?php step_begin() ?>
    INSERT INTO biomart.bio_data_uid (
        bio_data_id,
        unique_id,
        bio_data_type )
    SELECT
        DISTINCT b.bio_experiment_id,
        'EXP:' || m.study_id,
        'EXP'
    FROM
        biomart.bio_experiment b,
        lt_src_study_metadata m
    WHERE ( m.study_id IS NOT NULL
        AND m.study_id ::TEXT <> '' )
        AND m.study_id = b.accession
        AND NOT EXISTS (
            SELECT
                1
            FROM
                biomart.bio_data_uid x
            WHERE
                x.unique_id = 'EXP:' || m.study_id );
    <?php step_end('Inserted trial data into BIOMART bio_data_uid') ?>

    --    delete existing compound data for study, compound list may change
    <?php step_begin() ?>
    DELETE
    FROM
        biomart.bio_data_compound dc
    WHERE
        dc.bio_data_id IN (
            SELECT
                x.bio_experiment_id
            FROM
                biomart.bio_experiment x,
                tm_lz.lt_src_study_metadata y
            WHERE
                x.accession = y.study_id
                AND x.etl_id = 'METADATA:' || y.study_id );
    <?php step_end('Delete existing data from bio_data_compound') ?>

    FOR study_compound IN
            SELECT DISTINCT study_id, compound
            FROM tm_lz.lt_src_study_metadata
            WHERE (compound IS NOT NULL AND compound::text <> '') LOOP

        SELECT LENGTH(study_compound.compound) -
               LENGTH(REPLACE(study_compound.compound, ';', '')) + 1
            INTO dcount;

        WHILE dcount > 0 LOOP
            <?php step_begin() ?>
            SELECT
                tm_cz.parse_nth_value ( study_compound.compound, dcount, ';' )
                INTO tmp_compound;

            -- add new compound
            INSERT INTO biomart.bio_compound ( generic_name )
            SELECT
                tmp_compound
            WHERE
                NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_compound x
                    WHERE
                        UPPER ( x.generic_name )
                        = UPPER ( tmp_compound ) )
                AND ( tmp_compound IS NOT NULL AND tmp_compound::TEXT <> '' );
            <?php step_end('Added compound to bio_compound') ?>

            --    Insert new trial data into bio_data_compound
            <?php step_begin() ?>
            INSERT INTO biomart.bio_data_compound (
                bio_data_id,
                bio_compound_id,
                etl_source )
            SELECT
                b.bio_experiment_id,
                c.bio_compound_id,
                'METADATA:' || study_compound.study_id
            FROM
                biomart.bio_experiment b,
                biomart.bio_compound c
            WHERE
                UPPER ( tmp_compound )
                = UPPER ( c.generic_name )
                AND ( tmp_compound IS NOT NULL AND tmp_compound::TEXT <> '' )
                AND b.accession = study_compound.study_id
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_data_compound x
                    WHERE
                        b.bio_experiment_id = x.bio_data_id
                        AND c.bio_compound_id = x.bio_compound_id );
            <?php step_end('Inserted trial data in BIOMART bio_data_compound') ?>

            dcount := dcount - 1;
        END LOOP;
    END LOOP;

    --    delete existing disease data for studies
    <?php step_begin() ?>
    DELETE
    FROM
        biomart.bio_data_disease dc
    WHERE
        dc.bio_data_id IN (
            SELECT
                x.bio_experiment_id
            FROM
                biomart.bio_experiment x,
                tm_lz.lt_src_study_metadata y
            WHERE
                x.accession = y.study_id
                AND x.etl_id = 'METADATA:' || y.study_id );
    <?php step_end('Delete existing data from bio_data_disease') ?>

    FOR study_disease IN
            SELECT DISTINCT study_id, disease
            FROM tm_lz.lt_src_study_metadata
            WHERE ( disease IS NOT NULL AND disease::TEXT <> '' ) LOOP

        SELECT LENGTH(study_disease.disease) -
               LENGTH(REPLACE(study_disease.disease, ';', '')) + 1
            INTO dcount;

        WHILE dcount > 0 LOOP
            SELECT tm_cz.parse_nth_value(study_disease.disease, dcount, ';') INTO tmp_disease;

            --    add new disease
            <?php step_begin() ?>
            INSERT INTO bio_disease (
                disease,
                prefered_name )
            SELECT
                tmp_disease,
                tmp_disease
            WHERE
                NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_disease x
                    WHERE
                        UPPER ( x.disease )
                        = UPPER ( tmp_disease ) )
                AND ( tmp_disease IS NOT NULL AND tmp_disease::TEXT <> '' );
            <?php step_end('Added disease to bio_disease') ?>

            --    Insert new trial data into bio_data_disease
            <?php step_begin() ?>
            INSERT INTO bio_data_disease (
                bio_data_id,
                bio_disease_id,
                etl_source )
            SELECT
                b.bio_experiment_id,
                c.bio_disease_id,
                'METADATA:' || study_disease.study_id
            FROM
                biomart.bio_experiment b,
                biomart.bio_disease c
            WHERE
                UPPER ( tmp_disease ) = UPPER ( c.disease )
                AND ( tmp_disease IS NOT NULL
                    AND tmp_disease::TEXT <> '' )
                AND b.accession = study_disease.study_id
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_data_disease x
                    WHERE
                        b.bio_experiment_id = x.bio_data_id
                        AND c.bio_disease_id = x.bio_disease_id );
            <?php step_end('Inserted trial data in BIOMART bio_data_disease') ?>

            dcount := dcount - 1;
        END LOOP;
    END LOOP;

    --    delete existing taxonomy data for studies
    <?php step_begin() ?>
    DELETE FROM biomart.bio_data_taxonomy dc
    WHERE
        dc.bio_data_id IN (
            SELECT
                x.bio_experiment_id
            FROM
                biomart.bio_experiment x,
                tm_lz.lt_src_study_metadata y
            WHERE
                x.accession = y.study_id
                AND x.etl_id = 'METADATA:' || y.study_id );
    <?php step_end('Delete existing data from bio_data_taxonomy') ?>

    FOR study_taxonomy IN
            SELECT DISTINCT
                study_id,
                organism
            FROM
                tm_lz.lt_src_study_metadata
            WHERE ( organism IS NOT NULL
                AND organism::TEXT <> '' ) LOOP

        SELECT LENGTH(study_taxonomy.organism) -
               LENGTH(REPLACE(study_taxonomy.organism, ';', '')) + 1
            INTO dcount;

        WHILE dcount > 0 LOOP
            SELECT tm_cz.parse_nth_value(study_taxonomy.organism, dcount, ';') INTO tmp_organism;

            --    add new organism
            <?php step_begin() ?>
            INSERT INTO biomart.bio_taxonomy (
                taxon_name,
                taxon_label )
            SELECT
                tmp_organism,
                tmp_organism
            WHERE
                NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_taxonomy x
                    WHERE
                        UPPER ( x.taxon_name )
                        = UPPER ( tmp_organism ) )
                AND ( tmp_organism IS NOT NULL
                    AND tmp_organism::TEXT <> '' );
            <?php step_end('Added organism to bio_taxonomy') ?>

            --    Insert new trial data into bio_data_taxonomy
            <?php step_begin() ?>
            INSERT INTO biomart.bio_data_taxonomy ( bio_data_id,
                bio_taxonomy_id,
                etl_source )
            SELECT
                b.bio_experiment_id,
                c.bio_taxonomy_id,
                'METADATA:' || study_disease.study_id
            FROM
                biomart.bio_experiment b,
                biomart.bio_taxonomy c
            WHERE
                UPPER ( tmp_organism ) = UPPER ( c.taxon_name )
                AND ( tmp_organism IS NOT NULL
                    AND tmp_organism::TEXT <> '' )
                AND b.accession = study_disease.study_id
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_data_taxonomy x
                    WHERE
                        b.bio_experiment_id = x.bio_data_id
                        AND c.bio_taxonomy_id = x.bio_taxonomy_id );
            <?php step_end('Inserted trial data in BIOMART bio_data_taxonomy') ?>

            dcount := dcount - 1;
        END LOOP;
    END LOOP;

    --    add ncbi/GEO linking
    --    check if ncbi exists in bio_content_repository, if not, add
    SELECT
        COUNT ( * )
    INTO dcount
    FROM
        bio_content_repository
    WHERE
        repository_type = 'NCBI'
        AND location_type = 'URL';

    IF dcount = 0 THEN
        <?php step_begin() ?>
        INSERT INTO biomart.bio_content_repository (
            location,
            active_y_n,
            repository_type,
            location_type )
        VALUES (
            'http://www.ncbi.nlm.nih.gov/',
            'Y',
            'NCBI',
            'URL' );
        <?php step_end('Inserted NCBI URL in bio_content_repository') ?>
    END IF;

    --    insert GSE studies into bio_content
    <?php step_begin() ?>
    INSERT INTO bio_content (
        repository_id,
        location,
        file_type,
        etl_id_c )
    SELECT
        bcr.bio_content_repo_id,
        'geo/query/acc.cgi?acc=' || m.study_id,
        'Experiment Web Link',
        'METADATA:' || m.study_id
    FROM
        tm_lz.lt_src_study_metadata m,
        biomart.bio_content_repository bcr
    WHERE
        m.study_id LIKE 'GSE%'
        AND bcr.repository_type = 'NCBI'
        AND bcr.location_type = 'URL'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                biomart.bio_content x
            WHERE
                x.etl_id_c LIKE '%' || m.study_id || '%'
                AND x.file_type = 'Experiment Web Link'
                AND x.location = 'geo/query/acc.cgi?acc=' || m.study_id );
    <?php step_end('Inserted GEO study into bio_content') ?>

    --    insert GSE studies into bio_content_reference
    <?php step_begin() ?>
    INSERT INTO bio_content_reference (
        bio_content_id,
        bio_data_id,
        content_reference_type,
        etl_id_c )
    SELECT
        bc.bio_file_content_id,
        be.bio_experiment_id,
        'Experiment Web Link',
        'METADATA:' || m.study_id
    FROM
        tm_lz.lt_src_study_metadata m,
        biomart.bio_experiment be,
        biomart.bio_content bc
    WHERE
        m.study_id LIKE 'GSE%'
        AND m.study_id = be.accession
        AND bc.file_type = 'Experiment Web Link'
        AND bc.etl_id_c = 'METADATA:' || m.study_id
        AND bc.location = 'geo/query/acc.cgi?acc=' || m.study_id
        AND NOT EXISTS (
            SELECT
                1
            FROM
                biomart.bio_content_reference x
            WHERE
                bc.bio_file_content_id = x.bio_content_id
                AND be.bio_experiment_id = x.bio_data_id );
    <?php step_end('Inserted GEO study into bio_content_reference') ?>

    --    add PUBMED linking
    --    delete existing pubmed data for studies
    <?php step_begin() ?>
    DELETE
    FROM
        biomart.bio_content_reference dc
    WHERE
        dc.bio_content_id IN (
            SELECT
                x.bio_file_content_id
            FROM
                biomart.bio_content x,
                tm_lz.lt_src_study_metadata y
            WHERE
                x.file_type = 'Publication Web Link'
                AND x.etl_id_c = 'METADATA:' || y.study_id );
    <?php step_end('Delete existing Pubmed data from bio_content_reference') ?>

    <?php step_begin() ?>
    DELETE
    FROM
        biomart.bio_content dc
    WHERE
        dc.bio_file_content_id IN (
            SELECT
                x.bio_file_content_id
            FROM
                biomart.bio_content x,
                tm_lz.lt_src_study_metadata y
            WHERE
                x.file_type = 'Publication Web Link'
                AND x.etl_id_c = 'METADATA:' || y.study_id );
    <?php step_end('Delete existing Pubmed data from bio_content') ?>


    --    check if PubMed url exists in bio_content_repository, if not, add
    SELECT
        COUNT ( * )
        INTO dcount
    FROM
        biomart.bio_content_repository
    WHERE
        repository_type = 'PubMed';

    IF dcount = 0 THEN
        <?php step_begin() ?>
        INSERT INTO biomart.bio_content_repository (
            location,
            active_y_n,
            repository_type,
            location_type )
        VALUES (
            'http://www.ncbi.nlm.nih.gov/pubmed/',
            'Y',
            'PubMed',
            'URL' );
        <?php step_end('Inserted GEO study into bio_content_reference') ?>
    END IF;

    FOR study_pubmed IN
            SELECT
                DISTINCT study_id,
                pubmed_ids
            FROM
                tm_lz.lt_src_study_metadata
            WHERE ( pubmed_ids IS NOT NULL
                AND pubmed_ids::TEXT <> '' ) LOOP

        SELECT LENGTH(study_pubmed.pubmed_ids) - LENGTH(REPLACE(study_pubmed.pubmed_ids, ';', '')) + 1
            INTO dcount;

        WHILE dcount > 0 LOOP

            -- multiple pubmed id can be separated by ;, pubmed id and title are separated by :
            SELECT tm_cz.parse_nth_value(study_pubmed.pubmed_ids, dcount, ';') INTO tmp_pubmed;
            SELECT tm_cz.instr(tmp_pubmed, ':') INTO lcount;

            IF lcount = 0 THEN
                pubmed_id := tmp_pubmed;
                pubmed_title := null;
            ELSE
                pubmed_id := substr(tmp_pubmed, 1, tm_cz.instr(tmp_pubmed, ':') - 1);
                PERFORM tm_cz.cz_write_audit(jobId, databaseName, procedureName,
                        'pubmed_id: ' || pubmed_id, 1, stepCt, 'Done');

                pubmed_title := substring(tmp_pubmed from tm_cz.instr(tmp_pubmed, ':') + 1);
                PERFORM tm_cz.cz_write_audit(jobId, databaseName, procedureName,
                        'pubmed_title: ' || pubmed_title,1,stepCt,'Done');
            END IF;

            <?php step_begin() ?>
            INSERT INTO biomart.bio_content (
                repository_id,
                location,
                title,
                file_type,
                etl_id_c )
            SELECT
                bcr.bio_content_repo_id,
                pubmed_id,
                pubmed_title,
                'Publication Web Link',
                'METADATA:' || study_pubmed.study_id
            FROM
                biomart.bio_content_repository bcr
            WHERE
                bcr.repository_type = 'PubMed'
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        bio_content x
                    WHERE
                        x.etl_id_c LIKE '%' || study_pubmed.study_id || '%'
                        AND x.file_type = 'Publication Web Link'
                        AND x.location = pubmed_id );
            <?php step_end('Inserted pubmed for study into bio_content') ?>

            <?php step_begin() ?>
            INSERT INTO biomart.bio_content_reference ( bio_content_id,
                bio_data_id,
                content_reference_type,
                etl_id_c )
            SELECT
                bc.bio_file_content_id,
                be.bio_experiment_id,
                'Publication Web Link',
                'METADATA:' || study_pubmed.study_id
            FROM
                biomart.bio_experiment be,
                biomart.bio_content bc
            WHERE
                be.accession = study_pubmed.study_id
                AND bc.file_type = 'Publication Web Link'
                AND bc.etl_id_c = 'METADATA:' || study_pubmed.study_id
                AND bc.location = pubmed_id
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        biomart.bio_content_reference x
                    WHERE
                        bc.bio_file_content_id = x.bio_content_id
                        AND be.bio_experiment_id = x.bio_data_id );
            <?php step_end('Inserted pubmed for study into bio_content_reference') ?>

            dcount := dcount - 1;
        END LOOP;
    END LOOP;

    -- Delete existing Trial tags in i2b2_tags
    <?php step_begin() ?>
    DELETE
    FROM
        i2b2metadata.i2b2_tags
    WHERE
        UPPER ( tag_type ) = 'Trial';
    <?php step_end('Delete existing Trial tags in i2b2_tags') ?>

    -- Create i2b2_tags
    <?php step_begin() ?>
    INSERT INTO i2b2metadata.i2b2_tags (
        tag_id,
        path,
        tag,
        tag_type,
        tags_idx )
    SELECT
        (select nextval('ont_sq_ps_prid')) as tag_id,
        MIN ( b.c_fullname ) AS path,
        be.accession AS tag,
        'Trial' AS tag_type,
        0 AS tags_idx
    FROM
        biomart.bio_experiment be,
        i2b2metadata.i2b2 b
    WHERE
        be.accession = b.sourcesystem_cd
    GROUP BY
        be.accession;
    <?php step_end('Add Trial tags in i2b2_tags') ?>

    -- Delete existing Compound tags in I2B2METADATA i2b2_tags
    <?php step_begin() ?>
    DELETE
    FROM
        i2b2metadata.i2b2_tags t
    WHERE
        UPPER ( t.tag_type ) = 'COMPOUND';
    <?php step_end('Delete existing Compound tags in I2B2METADATA i2b2_tags') ?>

    -- Insert trial data tags - COMPOUND
    <?php step_begin() ?>
    INSERT INTO i2b2metadata.i2b2_tags (
        tag_id,
        path,
        tag,
        tag_type,
        tags_idx )
    SELECT DISTINCT
        (select nextval('ont_sq_ps_prid')) as tag_id,
        MIN ( o.c_fullname ) AS path,
        ( CASE
                WHEN x.rec_num = 1 THEN c.generic_name
                ELSE c.brand_name
            END ) AS tag,
        'Compound' AS tag_type,
        1 AS tags_idx
    FROM
        biomart.bio_experiment be,
        biomart.bio_data_compound bc,
        biomart.bio_compound c,
        i2b2metadata.i2b2 o,
        (
            SELECT
                1
            UNION
            SELECT
                2 )
        x ( rec_num )
        -- original had (select rownum as rec_num from table_access where rownum < 3)
        -- I can only imagine the usage of table_access here was a... peculiariaty of the original
    WHERE
        be.bio_experiment_id = bc.bio_data_id
        AND bc.bio_compound_id = c.bio_compound_id
        AND be.accession = o.sourcesystem_cd
        AND ( CASE
                WHEN x.rec_num = 1 THEN c.generic_name
                ELSE c.brand_name
            END )
        IS NOT NULL
    GROUP BY
        ( CASE
                WHEN x.rec_num = 1 THEN c.generic_name
                ELSE c.brand_name
            END );
    <?php step_end('Insert Compound tags in I2B2METADATA i2b2_tags') ?>

    --    Insert trial data tags - DISEASE
    <?php step_begin() ?>
    DELETE
    FROM
        i2b2metadata.i2b2_tags t
    WHERE
        UPPER ( t.tag_type ) = 'DISEASE';
    <?php step_end('Delete existing DISEASE tags in I2B2METADATA i2b2_tags') ?>

    <?php step_begin() ?>
    INSERT INTO i2b2metadata.i2b2_tags (
        tag_id,
        path,
        tag,
        tag_type,
        tags_idx )
    SELECT DISTINCT
        (select nextval('ont_sq_ps_prid')) as tag_id,
        MIN ( o.c_fullname ) AS path,
        c.prefered_name,
        'Disease' AS tag_type,
        1 AS tags_idx
    FROM
        biomart.bio_experiment be,
        biomart.bio_data_disease bc,
        biomart.bio_disease c,
        i2b2metadata.i2b2 o
    WHERE
        be.bio_experiment_id = bc.bio_data_id
        AND bc.bio_disease_id = c.bio_disease_id
        AND be.accession = o.sourcesystem_cd
    GROUP BY
        c.prefered_name;
    <?php step_end('Insert Disease tags in I2B2METADATA i2b2_tags') ?>

    --    Load bio_ad_hoc_property
    <?php step_begin() ?>
    DELETE
    FROM
        biomart.bio_ad_hoc_property
    WHERE
        bio_data_id IN (
            SELECT
                DISTINCT x.bio_experiment_id
            FROM
                tm_lz.lt_src_study_metadata_ad_hoc t,
                biomart.bio_experiment x
            WHERE
                t.study_id = x.accession );
    <?php step_end('Delete existing ad_hoc metadata from BIOMART BIO_AD_HOC_PROPERTY') ?>

    <?php step_begin() ?>
    INSERT INTO biomart.bio_ad_hoc_property (
        bio_data_id,
        property_key,
        property_value )
    SELECT
        b.bio_experiment_id,
        t.ad_hoc_property_key,
        t.ad_hoc_property_value
    FROM
        tm_lz.lt_src_study_metadata_ad_hoc t,
        biomart.bio_experiment b
    WHERE
        t.study_id = b.accession;
    <?php step_end('Insert ad_hoc metadata into BIOMART BIO_AD_HOC_PROPERTY') ?>

    PERFORM cz_write_audit(jobId, databaseName, procedureName,
        'End i2b2_load_study_metadata', 0, stepCt, 'Done');
    stepCt := stepCt + 1;

    <?php func_end() ?>
END;
/*    ignore for now
    --    Add trial/study to search_secure_object
    insert into searchapp.search_secure_object
    (bio_data_id
    ,display_name
    ,data_type
    ,bio_data_unique_id
    )
    select b.bio_experiment_id
          ,parse_nth_value(md.c_fullname,2,'\') || ' - ' || b.accession as display_name
          ,'BIO_CLINICAL_TRIAL' as data_type
          ,'EXP:' || b.accession as bio_data_unique_id
    from i2b2metadata.i2b2 md
        ,biomart.bio_experiment b
    where b.accession = md.sourcesystem_cd
      and md.c_hlevel = 0
      and md.c_fullname not like '\Public Studies\%'
      and md.c_fullname not like '\Internal Studies\%'
      and md.c_fullname not like '\Experimental Medicine Study\NORMALS\%'
      and not exists
         (select 1 from searchapp.search_secure_object so
          where b.bio_experiment_id = so.bio_data_id)
    ;
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted new trial/study into SEARCHAPP search_secure_object',SQL%ROWCOUNT,stepCt,'Done');
    commit;
*/
/*    not used
    --    Insert WORKFLOW tags
    delete from i2b2_tags
    where tag_type = 'WORKFLOW';
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Delete existing trial WORKFLOW in I2B2METADATA i2b2_tags',SQL%ROWCOUNT,stepCt,'Done');
    commit;
    insert into i2b2_tags
    (path
    ,tag_type
    ,tag
    )
    select distinct b.c_fullname
          ,'WORKFLOW'
          ,decode(d.platform,'MRNA_AFFYMETRIX','Gene Expression','RBM','RBM','Protein','Protein',null) as tag
    from deapp.de_subject_sample_mapping d
        ,i2b2 b
    where d.platform is not null
      and d.trial_name = b.sourcesystem_cd
      and b.c_hlevel = 0
      and b.c_fullname not like '%Across Trials%';
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted heatmap WORKFLOW in I2B2METADATA i2b2_tags',SQL%ROWCOUNT,stepCt,'Done');
    commit;
    insert into i2b2_tags
    (path
    ,tag_type
    ,tag
    )
    select distinct c.c_fullname
          ,'WORKFLOW'
          ,'SNP'
    from deapp.de_snp_data_by_patient snp
    ,i2b2 c
    where snp.trial_name = c.sourcesystem_cd
      and c.c_hlevel = 0;
    stepCt := stepCt + 1;
    cz_write_audit(jobId,databaseName,procedureName,'Inserted SNP WORKFLOW in I2B2METADATA i2b2_tags',SQL%ROWCOUNT,stepCt,'Done');
    commit;
*/
$body$
LANGUAGE PLPGSQL;

<?php // vim: ts=4 sts=4 sw=4 et filetype=plsql :
?>
