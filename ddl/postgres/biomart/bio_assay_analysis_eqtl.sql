--
-- Name: bio_assay_analysis_eqtl; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_assay_analysis_eqtl (
    bio_asy_analysis_eqtl_id bigint NOT NULL,
    bio_assay_analysis_id bigint NOT NULL,
    rs_id character varying(50),
    gene character varying(50),
    p_value_char character varying(100),
    p_value double precision,
    log_p_value double precision,
    cis_trans character varying(10),
    distance_from_gene character varying(10),
    etl_id bigint,
    ext_data character varying(4000)
);

--
-- Name: bio_assay_analysis_eqtl_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_eqtl
    ADD CONSTRAINT bio_assay_analysis_eqtl_pkey PRIMARY KEY (bio_asy_analysis_eqtl_id);

--
-- Name: trg_bio_asy_analysis_eqtl_id_fun(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION trg_bio_asy_analysis_eqtl_id_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.bio_asy_analysis_eqtl_id IS NULL THEN
		SELECT nextval('biomart.seq_bio_data_id') INTO NEW.bio_asy_analysis_eqtl_id;
	END IF;
	RETURN NEW;
END;
$$;

--
-- Name: trg_bio_asy_analysis_eqtl_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_asy_analysis_eqtl_id BEFORE INSERT ON bio_assay_analysis_eqtl FOR EACH ROW EXECUTE PROCEDURE trg_bio_asy_analysis_eqtl_id_fun();

