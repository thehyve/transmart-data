--
-- Type: VIEW; Owner: SEARCHAPP; Name: SEARCH_TAXONOMY_LEVEL3
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SEARCH_TAXONOMY_LEVEL3" ("TERM_ID", "TERM_NAME", "CATEGORY_NAME") AS 
  select st.term_id, st.term_name, category_name
from search_taxonomy_rels str, search_taxonomy st, search_taxonomy_level2 stl2
where parent_id=stl2.term_id
and str.child_id=st.term_id
;
 
