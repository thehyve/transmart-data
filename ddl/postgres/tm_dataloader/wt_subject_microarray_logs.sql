--
-- Name: wt_subject_microarray_logs; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE wt_subject_microarray_logs (
    probeset_id bigint,
    intensity_value double precision,
    pvalue double precision,
    num_calls numeric,
    assay_id bigint,
    patient_id bigint,
    sample_id bigint,
    subject_id character varying(100),
    trial_name character varying(50),
    timepoint character varying(100),
    log_intensity double precision,
    raw_intensity double precision
);

