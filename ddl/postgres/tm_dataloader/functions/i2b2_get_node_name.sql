--
-- Name: i2b2_get_node_name(character varying); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION i2b2_get_node_name(concept_path character varying) RETURNS character varying
    LANGUAGE sql IMMUTABLE SECURITY DEFINER
    AS $$
	SELECT parse_nth_value(concept_path,length(concept_path)-length(replace(concept_path,'\','')),'\');
$$;

