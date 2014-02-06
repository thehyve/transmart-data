--
-- Name: bio_observation; Type: TABLE; Schema: biomart; Owner: -
--
CREATE TABLE bio_observation (
    bio_observation_id bigint,
    obs_name character varying(200),
    obs_code character varying(50),
    obs_descr character varying(1000),
    obs_type character varying(20),
    obs_code_source character varying(20),
    etl_id character varying(50)
);

