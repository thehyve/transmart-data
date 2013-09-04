--
-- Name: concept_counts; Type: TABLE; Schema: i2b2demodata; Owner: -
--
CREATE TABLE concept_counts (
    concept_path character varying(500),
    parent_concept_path character varying(500),
    patient_count numeric(18,0)
);

--
-- Name: concept_counts_concept_path_idx; Type: INDEX; Schema: i2b2demodata; Owner: -
--
CREATE INDEX concept_counts_concept_path_idx ON concept_counts USING btree (concept_path);

--
-- Name: concept_counts_patient_count_idx; Type: INDEX; Schema: i2b2demodata; Owner: -
--
CREATE INDEX concept_counts_patient_count_idx ON concept_counts USING btree (patient_count) WHERE (patient_count = (0)::numeric);

