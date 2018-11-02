--
-- Name: wt_subject_proteomics_logs; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE wt_subject_proteomics_logs (
    probeset_id character varying(500),
    intensity_value numeric,
    pvalue double precision,
    num_calls numeric,
    assay_id numeric(18,0),
    patient_id numeric(18,0),
    sample_id numeric(18,0),
    subject_id character varying(100),
    trial_name character varying(50),
    timepoint character varying(100),
    log_intensity numeric,
    platform character varying(200)
);

