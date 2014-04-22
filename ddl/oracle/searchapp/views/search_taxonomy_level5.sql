--
-- Type: VIEW; Owner: SEARCHAPP; Name: SEARCH_TAXONOMY_LEVEL5
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SEARCH_TAXONOMY_LEVEL5" ("TERM_ID", "TERM_NAME", "CATEGORY_NAME") AS 
  select st.term_id, st.term_name, category_name
from search_taxonomy_rels str, search_taxonomy st, search_taxonomy_level4 stl4
where parent_id=stl4.term_id
and str.child_id=st.term_id
 ;
