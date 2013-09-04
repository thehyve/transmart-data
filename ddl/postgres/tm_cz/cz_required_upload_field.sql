--
-- Name: cz_required_upload_field; Type: TABLE; Schema: tm_cz; Owner: -
--
CREATE TABLE cz_required_upload_field (
    required_upload_field_id bigint NOT NULL,
    field character varying(255) NOT NULL,
    type character varying(255) NOT NULL
);

--
-- Name: cz_required_upload_field_pkey; Type: CONSTRAINT; Schema: tm_cz; Owner: -
--
ALTER TABLE ONLY cz_required_upload_field
    ADD CONSTRAINT cz_required_upload_field_pkey PRIMARY KEY (required_upload_field_id);

