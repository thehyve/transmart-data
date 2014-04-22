--
-- Type: VIEW; Owner: SEARCHAPP; Name: LISTSIG_GENES
--
  CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."LISTSIG_GENES" ("GENE_KEYWORD_ID", "LIST_KEYWORD_ID") AS 
  select k_gsi.search_keyword_id gene_keyword_id, k_gs.search_keyword_id list_keyword_id
from Search_Keyword k_gs, search_Gene_Signature gs, 
search_Gene_Signature_Item gsi, Search_Keyword k_gsi
where k_gs.bio_Data_Id = gs.search_gene_signature_id
and gs.search_gene_signature_id = gsi.search_gene_signature_id
and gsi.bio_Marker_id = k_gsi.bio_Data_Id
;
 
