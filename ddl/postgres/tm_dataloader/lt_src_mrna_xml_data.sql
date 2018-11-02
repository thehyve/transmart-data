--
-- Name: lt_src_mrna_xml_data; Type: TABLE; Schema: tm_dataloader; Owner: -
--
CREATE UNLOGGED TABLE lt_src_mrna_xml_data (
    study_id character varying(50) NOT NULL,
    category_cd character varying(2000) NOT NULL,
    c_metadataxml text NOT NULL
);

