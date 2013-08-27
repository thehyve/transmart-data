--
-- Name: bio_assay_analysis_ext; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_assay_analysis_ext (
    bio_assay_analysis_id bigint NOT NULL,
    bio_assay_expression_platform_ bigint,
    bio_assay_genotype_platform_id bigint,
    gnome_version character(10),
    tissue character(10),
    cell_type character(10),
    population character(10),
    ru character(10),
    sample_size character(10)
);

--
-- Name: bio_assay_analysis_ext_pkey; Type: CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_ext
    ADD CONSTRAINT bio_assay_analysis_ext_pkey PRIMARY KEY (bio_assay_analysis_id);

--
-- Name: bio_assay_analysis_ext_bio_assay_analysis_id_fkey; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_ext
    ADD CONSTRAINT bio_assay_analysis_ext_bio_assay_analysis_id_fkey FOREIGN KEY (bio_assay_analysis_id) REFERENCES bio_assay_analysis(bio_assay_analysis_id);

--
-- Name: bio_assay_analysis_ext_bio_assay_expression_platform__fkey; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_ext
    ADD CONSTRAINT bio_assay_analysis_ext_bio_assay_expression_platform__fkey FOREIGN KEY (bio_assay_expression_platform_) REFERENCES bio_assay_platform(bio_assay_platform_id);

--
-- Name: bio_assay_analysis_ext_bio_assay_genotype_platform_id_fkey; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_assay_analysis_ext
    ADD CONSTRAINT bio_assay_analysis_ext_bio_assay_genotype_platform_id_fkey FOREIGN KEY (bio_assay_genotype_platform_id) REFERENCES bio_assay_platform(bio_assay_platform_id);

