--
-- Name: bio_data_platform; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_data_platform (
    bio_data_id bigint NOT NULL,
    bio_assay_platform_id bigint NOT NULL,
    etl_source character varying(100)
);

--
-- Name: bio_data_platform_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_data_platform
    ADD CONSTRAINT bio_data_platform_pkey PRIMARY KEY (bio_data_id, bio_assay_platform_id);

