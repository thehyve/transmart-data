--
-- Name: bio_data_observation; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_data_observation (
    bio_data_id bigint NOT NULL,
    bio_observation_id bigint NOT NULL,
    etl_source character varying(100)
);

--
-- Name: bio_data_observation_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_data_observation
    ADD CONSTRAINT bio_data_observation_pkey PRIMARY KEY (bio_data_id, bio_observation_id);

