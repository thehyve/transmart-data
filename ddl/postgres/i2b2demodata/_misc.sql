--
-- Name: concept_id; Type: SEQUENCE; Schema: i2b2demodata; Owner: -
--
CREATE SEQUENCE concept_id
    START WITH 200
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: seq_patient_num; Type: SEQUENCE; Schema: i2b2demodata; Owner: -
--
CREATE SEQUENCE seq_patient_num
    START WITH 1000000200
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: sq_up_encdim_encounternum; Type: SEQUENCE; Schema: i2b2demodata; Owner: -
--
CREATE SEQUENCE sq_up_encdim_encounternum
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 9999999999999
    CACHE 1;

--
-- Name: INDEX concept_counts_patient_count_idx; Type: COMMENT; Schema: i2b2demodata; Owner: -
--
COMMENT ON INDEX concept_counts_patient_count_idx IS 'For ETL. Function i2b2_create_concept_counts() used to create a index just to speed up the query under "set any node with missing or zero counts to hidden" so this is presumably useful, together with the index on concept_path.';

