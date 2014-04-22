--
-- Type: VIEW; Owner: SEARCHAPP; Name: SEARCH_TAXONOMY_TERMS_CATS
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SEARCH_TAXONOMY_TERMS_CATS" ("TERM_ID", "TERM_NAME", "CATEGORY_NAME") AS 
  select distinct term_id, term_name, category_name from 
(
select term_id, term_name, category_name from searchapp.search_taxonomy_level1
UNION
select term_id, term_name, category_name from searchapp.search_taxonomy_level2
UNION
select term_id, term_name, category_name from searchapp.search_taxonomy_level3
UNION
select term_id, term_name, category_name from searchapp.search_taxonomy_level4
UNION
select term_id, term_name, category_name from searchapp.search_taxonomy_level5
)
 ;
