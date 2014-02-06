--
-- Name: search_user_feedback; Type: TABLE; Schema: searchapp; Owner: -
--
CREATE TABLE search_user_feedback (
    search_user_feedback_id numeric(18,0),
    search_user_id numeric(18,0),
    create_date date,
    feedback_text character varying(2000),
    app_version character varying(100)
);

