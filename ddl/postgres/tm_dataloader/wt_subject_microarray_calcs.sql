--
-- Name: wt_subject_microarray_calcs; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE wt_subject_microarray_calcs (
    trial_name character varying(50),
    probeset_id bigint,
    mean_intensity double precision,
    median_intensity double precision,
    stddev_intensity double precision
);

