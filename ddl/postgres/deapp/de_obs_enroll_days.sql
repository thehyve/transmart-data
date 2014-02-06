--
-- Name: de_obs_enroll_days; Type: TABLE; Schema: deapp; Owner: -
--
CREATE TABLE de_obs_enroll_days (
    encounter_num numeric(38,0),
    days_since_enroll numeric(18,5),
    study_id character varying(200),
    visit_date timestamp without time zone
);

