--
-- Name: median(anyelement); Type: AGGREGATE; Schema: tm_dataloader; Owner: -
--
CREATE AGGREGATE median(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}',
    FINALFUNC = tm_dataloader._final_median
);

--
-- Name: median(double precision); Type: AGGREGATE; Schema: tm_dataloader; Owner: -
--
CREATE AGGREGATE median(double precision) (
    SFUNC = array_append,
    STYPE = double precision[],
    INITCOND = '{}',
    FINALFUNC = tm_dataloader._final_median
);


SET default_with_oids = false;

