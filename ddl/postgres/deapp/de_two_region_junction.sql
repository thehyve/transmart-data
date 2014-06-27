-- Name: de_two_region_junction_seq; Type: SEQUENCE; Schema: deapp; Owner: -
--
CREATE SEQUENCE de_two_region_junction_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: de_two_region_junction; Type: TABLE; Schema: deapp; Owner: -
--

CREATE TABLE de_two_region_junction (
    two_region_junction_id bigint DEFAULT nextval('de_two_region_junction_seq'::regclass) NOT NULL,
    up_gene character varying(50),
    up_chr character varying(50) NOT NULL,
    up_pos bigint NOT NULL,
    down_gene character varying(50),
    down_chr character varying(50) NOT NULL,
    down_pos bigint NOT NULL,
    is_in_frame boolean NOT NULL,
    assay_id bigint
);


--
-- Name: COLUMN de_two_region_junction.up_gene; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.up_gene IS 'up stream fusion gene (5" partner)';


--
-- Name: COLUMN de_two_region_junction.up_chr; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.up_chr IS 'chromosome of up stream fusion partner';


--
-- Name: COLUMN de_two_region_junction.up_pos; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.up_pos IS 'location of up stream fusion partner''s junction point';


--
-- Name: COLUMN de_two_region_junction.down_gene; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.down_gene IS 'down stream fusion gene (3" partner)';


--
-- Name: COLUMN de_two_region_junction.down_chr; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.down_chr IS 'chromosome of down stream fusion partner';


--
-- Name: COLUMN de_two_region_junction.down_pos; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.down_pos IS 'location of down stream fusion partner''s junction point';


--
-- Name: COLUMN de_two_region_junction.is_in_frame; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_junction.is_in_frame IS 'whether down stream fusion partner is frame-shift or in-frame-shift';



--
-- Name: de_two_region_junction_id; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE ONLY de_two_region_junction
    ADD CONSTRAINT de_two_region_junction_id_pk PRIMARY KEY (two_region_junction_id);

