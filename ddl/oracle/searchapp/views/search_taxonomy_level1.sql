--
-- Type: VIEW; Owner: SEARCHAPP; Name: SEARCH_TAXONOMY_LEVEL1
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SEARCH_TAXONOMY_LEVEL1" ("TERM_ID", "TERM_NAME", "CATEGORY_NAME") AS 
  select st.term_id, st.term_name, category_name
from search_taxonomy_rels str, search_taxonomy st, search_categories sc
where parent_id=sc.category_id
and str.child_id=st.term_id
;
 
