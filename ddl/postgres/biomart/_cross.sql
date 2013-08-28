--
-- Name: fk_baal_search_keyword; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_analysis_attribute_lineage
    ADD CONSTRAINT fk_baal_search_keyword FOREIGN KEY (ancestor_search_keyword_id) REFERENCES searchapp.search_keyword(search_keyword_id);

--
-- Name: fk_baal_search_taxonomy; Type: FK CONSTRAINT; Schema: biomart; Owner: -
--
ALTER TABLE ONLY bio_analysis_attribute_lineage
    ADD CONSTRAINT fk_baal_search_taxonomy FOREIGN KEY (ancestor_term_id) REFERENCES searchapp.search_taxonomy(term_id);

