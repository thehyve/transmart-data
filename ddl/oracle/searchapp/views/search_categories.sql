--
-- Type: VIEW; Owner: SEARCHAPP; Name: SEARCH_CATEGORIES
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SEARCH_CATEGORIES" ("CATEGORY_ID", "CATEGORY_NAME") AS 
  select child_id category_id, st.term_name category_name from search_taxonomy_rels str, search_taxonomy st
where parent_id=(select child_id from search_taxonomy_rels where parent_id is null)
and str.child_id=st.term_id
;
 
