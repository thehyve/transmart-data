--
-- Type: PROCEDURE; Owner: TM_CZ; Name: LOAD_CENTCLIN_CONTENT_DATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."LOAD_CENTCLIN_CONTENT_DATA" 
as
begin

begin

  delete from biomart_wz.bio_content_reference
    ;

  delete from biomart_wz.bio_content
    where repository_id = 
      (select bio_content_repo_id
      from biomart_wz.bio_content_repository
      where location = '\\JJHOST2\share\data\ClinicalTrials');
    
  delete from biomart_wz.bio_content_repository
    where lower(location) = '\\jjhost2\share\data\clinicaltrials';

commit;
end;

begin
-- populate bio_content_repository

  insert into biomart_wz.bio_content_repository(
    location
  , active_y_n
  , repository_type
  , location_type
  )
  values (
    '\\JJHOST2\share\data\ClinicalTrials'
  , 'Y'
  , 'Clinical Trials'
  , 'Data'
  );
  
commit;
end;

begin

  insert into biomart_wz.bio_content(
    file_name
  , repository_id
  , location
  --, title  , abstract
  , file_type
  --, etl_id
  )
  select distinct
    ec.file_name
  , bcr.bio_content_repo_id
  , ec.file_path
  , 'Data'
  from 
    centclinrd.externalcontent ec
  , biomart_wz.bio_content_repository bcr
  where bcr.location='\\JJHOST2\share\data\ClinicalTrials';
  
commit;
end;

begin

  insert into biomart_wz.bio_content_reference(
    bio_content_id
  , bio_data_id
  , content_reference_type
  )
  select distinct
    bc.bio_file_content_id
  , baa.bio_assay_analysis_id
  , bcr.location_type
  from
    biomart_wz.bio_content bc
  , biomart_wz.bio_assay_analysis baa
  , biomart_wz.bio_content_repository bcr
  , centclinrd.geneexpressionanalysiscontent geac
  , centclinrd.externalcontent ec
  where bc.repository_id = bcr.bio_content_repo_id
  and baa.etl_id = 'GEAC.'||to_char(geac.id)
  and geac.id = ec.id
  and ec.file_name = bc.file_name;
  
  --143 with GEAC in bio_assay_analysis

  
commit;
end;


end;
 

 
 
 
 
 
/
 
