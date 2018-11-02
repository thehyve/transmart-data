--
-- Name: i2b2_get_hlevel(character varying); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION i2b2_get_hlevel(concept_path character varying) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

  DECLARE
    root_level INTEGER;
  BEGIN
    SELECT c_hlevel INTO root_level
    FROM i2b2metadata.table_access
    WHERE c_name = parse_nth_value(concept_path, 2, '\');

    RETURN ((length(concept_path) - coalesce(length(replace(concept_path, '\','')),0)) / length('\')) - 2 + root_level;
  END;
$$;

