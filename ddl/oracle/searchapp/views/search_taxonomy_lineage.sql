--
-- Type: VIEW; Owner: SEARCHAPP; Name: SEARCH_TAXONOMY_LINEAGE
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."SEARCH_TAXONOMY_LINEAGE" ("CHILD_ID", "PARENT1", "PARENT2", "PARENT3", "PARENT4") AS 
  select s1.child_id child_id, s2.child_id parent1, s3.child_id parent2, s4.child_id parent3, s5.child_id parent4
from search_taxonomy_rels s1, search_taxonomy_rels s2, search_taxonomy_rels s3, search_taxonomy_rels s4, search_taxonomy_rels s5
where s1.parent_id=s2.child_id(+) 
and s2.parent_id=s3.child_id(+)
and s3.parent_id=s4.child_id(+)
and s4.parent_id=s5.child_id(+)
;
 
