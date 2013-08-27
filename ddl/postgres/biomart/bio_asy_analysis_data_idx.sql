--
-- Name: bio_asy_analysis_data_idx; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_asy_analysis_data_idx (
    bio_asy_analysis_data_idx_id bigint NOT NULL,
    ext_type character varying(100),
    field_name character varying(100),
    field_idx smallint,
    display_name character varying(100),
    display_idx smallint
);

--
-- Name: bio_asy_analysis_data_idx_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_asy_analysis_data_idx
    ADD CONSTRAINT bio_asy_analysis_data_idx_pkey PRIMARY KEY (bio_asy_analysis_data_idx_id);

--
-- Name: trg_bio_asy_anlsis_data_idx_id_fun(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION trg_bio_asy_anlsis_data_idx_id_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.BIO_ASY_ANALYSIS_DATA_IDX_ID IS NULL THEN
		SELECT nextval('biomart.seq_bio_data_id') INTO NEW.BIO_ASY_ANALYSIS_DATA_IDX_ID;
	END IF;
	RETURN NEW;
END;
$$;

--
-- Name: trg_bio_asy_anlsis_data_idx_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_asy_anlsis_data_idx_id BEFORE INSERT ON bio_asy_analysis_data_idx FOR EACH ROW EXECUTE PROCEDURE trg_bio_asy_anlsis_data_idx_id_fun();

