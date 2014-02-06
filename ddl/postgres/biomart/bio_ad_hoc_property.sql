--
-- Name: bio_ad_hoc_property; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_ad_hoc_property (
    ad_hoc_property_id bigint NOT NULL,
    bio_data_id bigint NOT NULL,
    property_key character varying(50),
    property_value character varying(2000)
);

