--
-- Type: PROCEDURE; Owner: BIOMART; Name: INSERT_CTA_RESULTS
--
  CREATE OR REPLACE PROCEDURE "BIOMART"."INSERT_CTA_RESULTS" (aId integer)
is
begin
insert into biomart.cta_results (
bio_assay_analysis_id,
search_keyword_id,
keyword,
bio_marker_id,
bio_marker_name,
gene_id,
probe_id,
fold_change,
preferred_pvalue,
organism
)
select distinct h.bio_assay_analysis_id, h.search_keyword_id, upper(s.keyword),
   h.bio_marker_id, b.bio_marker_name, b.primary_external_id, h.probe_id, h.fold_change_ratio, h.preferred_pvalue,
   b.organism
from heat_map_results h, bio_marker b, searchapp.search_keyword s
where Bio_Assay_Analysis_Id = aId
and h.bio_marker_id=b.bio_marker_id
and h.search_keyword_id=s.search_keyword_id;
commit;
end;
/
