--
-- Type: VIEW; Owner: SEARCHAPP; Name: SOLR_KEYWORDS_LINEAGE
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SOLR_KEYWORDS_LINEAGE" ("TERM_ID", "ANCESTOR_ID", "SEARCH_KEYWORD_ID") AS 
  select distinct term_id, ancestor_id, search_keyword_id from
(select distinct  l.child_id term_id, l.child_id ancestor_id, st.search_keyword_id
 from searchapp.search_taxonomy_lineage l, search_taxonomy st
 where l.child_id=st.term_id
 and l.child_id is not null 
UNION
 select distinct  l.child_id term_id, l.parent1 ancestor_id, st.search_keyword_id
 from searchapp.search_taxonomy_lineage l, search_taxonomy st
 where l.parent1=st.term_id
 and l.parent1 is not null 
UNION
 select distinct  l.child_id term_id, l.parent2 ancestor_id, st.search_keyword_id
 from searchapp.search_taxonomy_lineage l, search_taxonomy st
 where l.parent2=st.term_id
 and l.parent2 is not null 
UNION
 select distinct  l.child_id term_id, l.parent3 ancestor_id, st.search_keyword_id
 from searchapp.search_taxonomy_lineage l, search_taxonomy st
 where l.parent3=st.term_id
 and l.parent3 is not null 
UNION
 select distinct l.child_id term_id, l.parent4 ancestor_id, st.search_keyword_id
 from searchapp.search_taxonomy_lineage l, search_taxonomy st
 where l.parent4=st.term_id
 and l.parent4 is not null 
)
where search_keyword_id is not null
 ;
