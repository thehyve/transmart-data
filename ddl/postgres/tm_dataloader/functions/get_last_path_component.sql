--
-- Name: get_last_path_component(character varying); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION get_last_path_component(node_path character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
	parts      TEXT [];
	partsCount INT;
	lastComp   CHARACTER VARYING;
	pos        INT;
BEGIN
	parts := regexp_split_to_array(node_path, '\\');
	RETURN parts [array_length(parts, 1) - 1];
END;
$$;

