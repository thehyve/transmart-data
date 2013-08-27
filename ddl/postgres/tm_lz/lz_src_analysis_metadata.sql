--
-- Name: lz_src_analysis_metadata; Type: TABLE; Schema: tm_lz; Owner: -
--
CREATE TABLE lz_src_analysis_metadata (
    study_id character varying(50),
    data_type character varying(50),
    analysis_name character varying(500),
    description character varying(1000),
    phenotype_ids character varying(250),
    population character varying(500),
    tissue character varying(500),
    genome_version character varying(50),
    genotype_platform_ids character varying(500),
    expression_platform_ids character varying(500),
    statistical_test character varying(500),
    research_unit character varying(500),
    sample_size character varying(500),
    cell_type character varying(500),
    pvalue_cutoff character varying(50),
    etl_date timestamp without time zone,
    filename character varying(500),
    status character varying(50),
    process_date timestamp without time zone,
    etl_id bigint,
    analysis_name_archived character varying(500),
    model_name character varying(500),
    model_desc character varying(4000)
);

--
-- Name: trg_etl_id_fun(); Type: FUNCTION; Schema: tm_lz; Owner: -
--
CREATE FUNCTION trg_etl_id_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.etl_id IS NULL THEN
		SELECT nextval('tm_lz.seq_etl_id') INTO NEW.etl_id;
	END IF;
	RETURN NEW;
END;
$$;


SET default_with_oids = false;

--
-- Name: trg_etl_id; Type: TRIGGER; Schema: tm_lz; Owner: -
--
CREATE TRIGGER trg_etl_id BEFORE INSERT ON lz_src_analysis_metadata FOR EACH ROW EXECUTE PROCEDURE trg_etl_id_fun();

--
-- Name: seq_etl_id; Type: SEQUENCE; Schema: tm_lz; Owner: -
--
CREATE SEQUENCE seq_etl_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

