--
-- Name: drop_all_indexes(character varying, character varying); Type: FUNCTION; Schema: tm_dataloader; Owner: -
--
CREATE FUNCTION drop_all_indexes(schema_name character varying, table_name character varying) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
	drop_sql text;
	recreate_sql text;
begin
	select array_to_string(array(select 'drop index ' || schemaname || '.' || indexname from pg_indexes where schemaname = schema_name and tablename = table_name and indexdef not like '% UNIQUE %'), E';\n') into drop_sql;
	select array_to_string(array(select indexdef from pg_indexes where schemaname=schema_name and tablename=table_name and indexdef not like '% UNIQUE %'), E';\n') into recreate_sql;
	execute(drop_sql);
	return recreate_sql;
end
$$;

