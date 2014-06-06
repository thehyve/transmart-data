-- Name: de_two_region_variant_seq; Type: SEQUENCE; Schema: deapp; Owner: -
--
CREATE SEQUENCE de_two_region_variant_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: de_two_region_variant; Type: TABLE; Schema: deapp; Owner: -
--

CREATE TABLE de_two_region_variant (
    two_region_variant_id bigint DEFAULT nextval('de_two_region_variant_seq'::regclass) NOT NULL,
    up_gene character varying(50),
    up_chr character varying(50) NOT NULL,
    up_pos bigint NOT NULL,
    down_gene character varying(50),
    down_chr character varying(50) NOT NULL,
    down_pos bigint NOT NULL,
    is_in_frame boolean NOT NULL,
    soap_class character varying(50),
    reads_span integer,
    reads_junction integer,
    pairs_span integer,
    pairs_junction integer,
    assay_id bigint
);


--
-- Name: COLUMN de_two_region_variant.up_gene; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.up_gene IS 'up stream fusion gene (5" partner)';


--
-- Name: COLUMN de_two_region_variant.up_chr; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.up_chr IS 'chromosome of up stream fusion partner';


--
-- Name: COLUMN de_two_region_variant.up_pos; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.up_pos IS 'location of up stream fusion partner''s junction point';


--
-- Name: COLUMN de_two_region_variant.down_gene; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.down_gene IS 'down stream fusion gene (3" partner)';


--
-- Name: COLUMN de_two_region_variant.down_chr; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.down_chr IS 'chromosome of down stream fusion partner';


--
-- Name: COLUMN de_two_region_variant.down_pos; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.down_pos IS 'location of down stream fusion partner''s junction point';


--
-- Name: COLUMN de_two_region_variant.is_in_frame; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.is_in_frame IS 'whether down stream fusion partner is frame-shift or in-frame-shift';


--
-- Name: COLUMN de_two_region_variant.soap_class; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.soap_class IS 'http://sourceforge.net/p/soapfuse/wiki/classification-of-fusions.for.SOAPfuse/';


--
-- Name: COLUMN de_two_region_variant.reads_span; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.reads_span IS 'number of reads inthe whole span';


--
-- Name: COLUMN de_two_region_variant.reads_junction; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.reads_junction IS 'number of reads spanning the junction';


--
-- Name: COLUMN de_two_region_variant.pairs_span; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.pairs_span IS 'number of spanning mate pairs ';


--
-- Name: COLUMN de_two_region_variant.pairs_junction; Type: COMMENT; Schema: deapp; Owner: -
--

COMMENT ON COLUMN de_two_region_variant.pairs_junction IS 'number of spanning mate pairs where one end spans a fusion ';

--
-- Name: de_two_region_variant_id; Type: CONSTRAINT; Schema: deapp; Owner: -
--
ALTER TABLE ONLY de_two_region_variant
    ADD CONSTRAINT de_two_region_variant_id PRIMARY KEY (two_region_variant_id);

