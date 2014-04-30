--
-- Type: VIEW; Owner: BIOMART; Name: CTD_EVENTS_VIEW
--
  CREATE OR REPLACE FORCE VIEW "BIOMART"."CTD_EVENTS_VIEW" ("ID", "REF_ARTICLE_PROTOCOL_ID", "DEFINITION_OF_THE_EVENT", "NUMBER_OF_EVENTS", "EVENT_RATE", "TIME_TO_EVENT", "EVENT_PCT_REDUCTION", "EVENT_P_VALUE", "EVENT_DESCRIPTION") AS 
  select rownum as ID, v."REF_ARTICLE_PROTOCOL_ID",v."DEFINITION_OF_THE_EVENT",v."NUMBER_OF_EVENTS",v."EVENT_RATE",v."TIME_TO_EVENT",v."EVENT_PCT_REDUCTION",v."EVENT_P_VALUE",v."EVENT_DESCRIPTION"
from 
(
select distinct REF_ARTICLE_PROTOCOL_ID,
			DEFINITION_OF_THE_EVENT,
			NUMBER_OF_EVENTS,
			EVENT_RATE,
			TIME_TO_EVENT,
			EVENT_PCT_REDUCTION,
			EVENT_P_VALUE,
			EVENT_DESCRIPTION
from ctd_full
where DEFINITION_OF_THE_EVENT is not null or EVENT_DESCRIPTION is not null
order by REF_ARTICLE_PROTOCOL_ID, DEFINITION_OF_THE_EVENT
) v
 
 
 
 
 
 ;