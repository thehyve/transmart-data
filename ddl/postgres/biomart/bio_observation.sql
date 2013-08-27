--
-- Name: bio_observation; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_observation (
    bio_observation_id bigint NOT NULL,
    obs_name character varying(200) NOT NULL,
    obs_code character varying(50),
    obs_descr character varying(1000),
    obs_type character varying(20),
    obs_code_source character varying(20),
    etl_id character varying(50)
);

--
-- Name: bio_observation_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_observation
    ADD CONSTRAINT bio_observation_pkey PRIMARY KEY (bio_observation_id);

--
-- Name: trg_bio_observation_id_fun(); Type: FUNCTION; Schema: biomart; Owner: -
--
CREATE FUNCTION trg_bio_observation_id_fun() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.bio_observation_id IS NULL THEN
		SELECT nextval('biomart.seq_bio_data_id') INTO NEW.bio_observation_id;
	END IF;
	RETURN NEW;
END;
$$;

--
-- Name: trg_bio_observation_id; Type: TRIGGER; Schema: biomart; Owner: -
--
CREATE TRIGGER trg_bio_observation_id BEFORE INSERT ON bio_observation FOR EACH ROW EXECUTE PROCEDURE trg_bio_observation_id_fun();

