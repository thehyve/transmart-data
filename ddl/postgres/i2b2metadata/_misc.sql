--
-- Name: i2b2_tag_options_tag_option_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2metadata; Owner: -
--
ALTER SEQUENCE i2b2_tag_options_tag_option_id_seq OWNED BY i2b2_tag_options.tag_option_id;

--
-- Name: i2b2_tag_types_tag_type_id_seq; Type: SEQUENCE OWNED BY; Schema: i2b2metadata; Owner: -
--
ALTER SEQUENCE i2b2_tag_types_tag_type_id_seq OWNED BY i2b2_tag_types.tag_type_id;

--
-- Name: seq_concept_code; Type: SEQUENCE; Schema: i2b2metadata; Owner: -
--
CREATE SEQUENCE seq_concept_code
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: sq_i2b2_id; Type: SEQUENCE; Schema: i2b2metadata; Owner: -
--
CREATE SEQUENCE sq_i2b2_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: sq_i2b2_tag_id; Type: SEQUENCE; Schema: i2b2metadata; Owner: -
--
CREATE SEQUENCE sq_i2b2_tag_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: INDEX i2b2_c_comment_char_length_idx; Type: COMMENT; Schema: i2b2metadata; Owner: -
--
COMMENT ON INDEX i2b2_c_comment_char_length_idx IS 'For i2b2metadata.i2b2_trial_nodes view';

