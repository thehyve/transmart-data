--
-- Name: bio_assay_analysis_gwas; Type: TABLE; Schema: biomart_stage; Owner: -
--
CREATE TABLE bio_assay_analysis_gwas (
    bio_asy_analysis_gwas_id bigint NOT NULL,
    bio_assay_analysis_id bigint NOT NULL,
    rs_id character varying(50),
    p_value_char character varying(100),
    etl_id bigint,
    ext_data character varying(4000),
    log_p_value double precision,
    p_value double precision
);

