--
-- Name: bio_assay_analysis_gwas; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_assay_analysis_gwas (
    bio_asy_analysis_gwas_id bigint NOT NULL,
    bio_assay_analysis_id bigint NOT NULL,
    rs_id character varying(50),
    p_value_char character varying(100),
    p_value double precision,
    log_p_value double precision,
    etl_id bigint,
    ext_data character varying(4000)
);

--
-- Name: bio_assay_analysis_gwas_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_gwas
    ADD CONSTRAINT bio_assay_analysis_gwas_pkey PRIMARY KEY (bio_asy_analysis_gwas_id);

--
-- Name: bio_assay_analysis_gwas_idx1; Type: INDEX; Schema: biomart; Owner: -
--
CREATE INDEX bio_assay_analysis_gwas_idx1 ON bio_assay_analysis_gwas USING btree (bio_assay_analysis_id);

--
-- Name: bio_assay_analysis_gwas_idx2; Type: INDEX; Schema: biomart; Owner: -
--
CREATE INDEX bio_assay_analysis_gwas_idx2 ON bio_assay_analysis_gwas USING btree (rs_id);

--
-- Name: trg_bio_asy_analysis_gwas_id_fun(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION trg_bio_asy_analysis_gwas_id_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.bio_asy_analysis_gwas_id IS NULL THEN
		SELECT nextval('biomart.seq_bio_data_id') INTO NEW.bio_asy_analysis_gwas_id;
	END IF;
	RETURN NEW;
END;
$$;

--
-- Name: trg_bio_asy_analysis_gwas_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_asy_analysis_gwas_id BEFORE INSERT ON bio_assay_analysis_gwas FOR EACH ROW EXECUTE PROCEDURE trg_bio_asy_analysis_gwas_id_fun();

