--
-- Name: replace_last_path_component(character varying, character varying); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION replace_last_path_component(node_path character varying, new_value character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
  lastComp  CHARACTER VARYING;
  modString CHARACTER VARYING;
BEGIN
  RETURN regexp_replace(node_path, '\\[^\\]+\\$', '\\' || new_value || '\\');
END;
$_$;

