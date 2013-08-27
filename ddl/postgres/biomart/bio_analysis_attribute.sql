--
-- Name: bio_analysis_attribute; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_analysis_attribute (
    study_id character varying(255),
    bio_assay_analysis_id bigint NOT NULL,
    term_id bigint,
    source_cd character varying(255),
    bio_analysis_attribute_id bigint NOT NULL
);

--
-- Name: pk_baa_id; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_analysis_attribute
    ADD CONSTRAINT pk_baa_id PRIMARY KEY (bio_analysis_attribute_id);

--
-- Name: trg_bio_analysis_att_baal_fun(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION trg_bio_analysis_att_baal_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    insert into BIO_ANALYSIS_ATTRIBUTE_LINEAGE 
    (BIO_ANALYSIS_ATTRIBUTE_ID, ANCESTOR_TERM_ID, ANCESTOR_SEARCH_KEYWORD_ID)
    SELECT NEW.BIO_ANALYSIS_ATTRIBUTE_ID, skl.ancestor_id, skl.search_keyword_id 
    FROM searchapp.solr_keywords_lineage skl
    WHERE skl.term_id = NEW.TERM_ID;
END;
$$;

--
-- Name: trg_bio_analysis_att_baal; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_analysis_att_baal AFTER INSERT ON bio_analysis_attribute FOR EACH ROW EXECUTE PROCEDURE trg_bio_analysis_att_baal_fun();

--
-- Name: trg_bio_analysis_attribute_id_fun(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION trg_bio_analysis_attribute_id_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		if NEW.BIO_ANALYSIS_ATTRIBUTE_ID IS NULL
			THEN
			SELECT nextval('BIOMART.SEQ_BIO_DATA_ID') INTO NEW.BIO_ANALYSIS_ATTRIBUTE_ID;
  		END IF;
	RETURN new;
END;
$$;

--
-- Name: trg_bio_analysis_attribute_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_analysis_attribute_id BEFORE INSERT ON bio_analysis_attribute FOR EACH ROW EXECUTE PROCEDURE trg_bio_analysis_attribute_id_fun();

