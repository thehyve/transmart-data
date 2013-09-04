--
-- Name: bio_ad_hoc_property; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_ad_hoc_property (
    ad_hoc_property_id bigint NOT NULL,
    property_key character varying(255) NOT NULL,
    bio_data_id bigint NOT NULL,
    property_value character varying(255) NOT NULL
);

--
-- Name: bio_ad_hoc_property_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_ad_hoc_property
    ADD CONSTRAINT bio_ad_hoc_property_pkey PRIMARY KEY (ad_hoc_property_id);

