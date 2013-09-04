--
-- Name: bio_assay_analysis_ext; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_assay_analysis_ext (
    bio_assay_analysis_ext_id bigint NOT NULL,
    bio_assay_analysis_id bigint NOT NULL,
    cell_type character varying(255),
    genome_version character varying(255),
    model_desc character varying(255),
    model_name character varying(255),
    population character varying(255),
    research_unit character varying(255),
    sample_size character varying(255),
    tissue character varying(255),
    vendor character varying(255),
    vendor_type character varying(255),
    ru character(10)
);

--
-- Name: bio_assay_analysis_ext_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_ext
    ADD CONSTRAINT bio_assay_analysis_ext_pkey PRIMARY KEY (bio_assay_analysis_ext_id);

--
-- Name: bio_assay_analysis_ext_bio_assay_analysis_id_fkey; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_ext
    ADD CONSTRAINT bio_assay_analysis_ext_bio_assay_analysis_id_fkey FOREIGN KEY (bio_assay_analysis_id) REFERENCES bio_assay_analysis(bio_assay_analysis_id);

