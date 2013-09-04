--
-- Name: cz_form_layout; Type: TABLE; Schema: tm_cz; Owner: -
--
CREATE TABLE cz_form_layout (
    form_layout_id bigint NOT NULL,
    form_column character varying(255) NOT NULL,
    data_type character varying(255),
    display_name character varying(255),
    form_key character varying(255) NOT NULL,
    sequence bigint
);

--
-- Name: cz_form_layout_pkey; Type: CONSTRAINT; Schema: tm_cz; Owner: -
--
ALTER TABLE ONLY cz_form_layout
    ADD CONSTRAINT cz_form_layout_pkey PRIMARY KEY (form_layout_id);

