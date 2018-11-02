--
-- Name: wt_subject_proteomics_med; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE wt_subject_proteomics_med (
    probeset_id character varying(500),
    intensity_value numeric,
    log_intensity numeric,
    assay_id numeric(18,0),
    patient_id numeric(18,0),
    sample_id numeric(18,0),
    subject_id character varying(100),
    trial_name character varying(50),
    timepoint character varying(100),
    pvalue double precision,
    num_calls numeric,
    mean_intensity numeric,
    stddev_intensity numeric,
    median_intensity numeric,
    zscore numeric,
    platform character varying(200)
);

