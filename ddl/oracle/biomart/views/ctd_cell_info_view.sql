--
-- Type: VIEW; Owner: BIOMART; Name: CTD_CELL_INFO_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART"."CTD_CELL_INFO_VIEW" ("ID", "REF_ARTICLE_PROTOCOL_ID", "CELLINFO_TYPE", "CELLINFO_COUNT", "CELLINFO_SOURCE") AS 
  select rownum as ID, v."REF_ARTICLE_PROTOCOL_ID",v."CELLINFO_TYPE",v."CELLINFO_COUNT",v."CELLINFO_SOURCE"
from 
(
select distinct REF_ARTICLE_PROTOCOL_ID,
			CELLINFO_TYPE,
			CELLINFO_COUNT,
			CELLINFO_SOURCE
from ctd_full
where CELLINFO_TYPE is not null
order by REF_ARTICLE_PROTOCOL_ID, CELLINFO_TYPE
) v
 
 
 
 
 
 ;
