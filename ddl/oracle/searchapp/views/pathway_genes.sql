--
-- Type: VIEW; Owner: SEARCHAPP; Name: PATHWAY_GENES
--
CREATE OR REPLACE FORCE VIEW "SEARCHAPP"."PATHWAY_GENES" ("GENE_KEYWORD_ID", "PATHWAY_KEYWORD_ID", "GENE_BIOMARKER_ID") AS 
  select k_gene.search_keyword_id gene_keyword_id,  k_pathway.search_keyword_id pathway_keyword_id, 
       b.asso_Bio_Marker_Id gene_biomarker_id
from SEARCHAPP.SEARCH_KEYWORD k_pathway, BIOMART.BIO_MARKER_CORREL_MV b,
									SEARCHAPP.SEARCH_KEYWORD k_gene 
									where b.correl_Type = 'PATHWAY_GENE'   
                  and b.bio_Marker_Id = k_pathway.bio_Data_Id  
									and k_pathway.data_Category = 'PATHWAY' 
									and b.asso_Bio_Marker_Id = k_gene.bio_Data_Id 
									and k_gene.data_Category = 'GENE';
