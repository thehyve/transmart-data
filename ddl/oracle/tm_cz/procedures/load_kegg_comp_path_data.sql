--
-- Type: PROCEDURE; Owner: TM_CZ; Name: LOAD_KEGG_COMP_PATH_DATA
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."LOAD_KEGG_COMP_PATH_DATA" 
as
  --jobRunID CONTROL.SYSTEM_JOB_RUN.JOB_RUN_ID%TYPE;
  --jobStepID CONTROL.SYSTEM_JOB_STEP.JOB_STEP_ID%TYPE;
--CREATE SYNONYM kegg_compound_name FOR PICTOR.kegg_compound_name;
--CREATE SYNONYM kegg_compound_xref FOR PICTOR.kegg_compound_xref;

BEGIN
--------------------------------------------------------------------------------
-- Loads data from PICTOR into biomart_LZ
--  emt@20090324
--------------------------------------------------------------------------------
  --jobrunid := control.insert_system_job_run('LoadPictorPathways', 'Load All Pathways from Pictor -- KEGG');
  
  begin
  --delete residual kegg records from the target tables
  -- NOTE: this delete statement deletes both pathways and genes
    delete from bio_marker
      where primary_source_code='KEGG';
    
    commit;
  end;
  
  begin

    --jobStepID := control.insert_system_job_step(jobRunID, 'Insert compound pathways into bio_marker for KEGG compound pathways'    
  --, 'Insert compound pathways into bio_marker for KEGG compound pathways', 22);
  
    insert into bio_marker(
      bio_marker_name
    , bio_marker_description
    , organism
    , primary_source_code
    , primary_external_id
    , bio_marker_type)
    select distinct
      kd.description
    , kd.description
    , upper(tax.taxonomy_name)
    , 'KEGG'
    , kd.map_id
    , 'PATHWAY'
    from 
      pictor.kmap_desc kd
    , pictor.taxonomy tax
    where kd.taxonomy_id = tax.taxonomy_id;
    --806
  --control.update_system_job_step_pass(jobStepID, SQL%ROWCOUNT);
  
  commit;
  end;
  
    begin

    --jobStepID := control.insert_system_job_step(jobRunID, 'Insert pathway genes  into bio_marker for KEGG compound pathways'    
  --, 'Insert pathway genes into bio_marker for KEGG compound pathways', 22);
 -- insert genes from kmap_gene that are not already in bio_marker

    insert into bio_marker(
      bio_marker_name
    , bio_marker_description
    , organism
    --, primary_source_code
    , primary_external_id
    , bio_marker_type)
    select distinct
      agi.gene_symbol
    , agi.description
    , upper(tn.name)
    , agi.gene_id
    , 'GENE'
    from 
      pictor.kmap_gene kg
    , pictor.kmap_desc kd
    , reference.ext_all_gene_info agi
    , reference.taxonomy_names tn
    , pictor.taxonomy tax
    where kg.map_id = kd.map_id
    and kd.taxonomy_id = tax.taxonomy_id
    and kg.gene_id = agi.gene_id
    and agi.tax_id = tn.tax_id
    and tn.tax_id = tax.taxonomy_id
    and to_char(kg.gene_id) not in 
      (select primary_external_id from bio_marker
      WHERE bio_marker.bio_marker_type='GENE');
      --14,413 new - this should be 0 subsequently
  --control.update_system_job_step_pass(jobStepID, SQL%ROWCOUNT);
  
  commit;
  end;
 
  begin                                                
    --jobStepID := control.insert_system_job_step(jobRunID, 'Insert disease pathways into bio_marker for KEGG compound pathways'    
  --, 'Insert disease pathways into bio_marker for KEGG compound pathways', 22);

    insert into bio_data_correlation(
      bio_data_id
    , asso_bio_data_id
    , bio_data_correl_descr_id
    )
    select distinct
      path.bio_marker_id
    , gene.bio_marker_id
    , bdcd.bio_data_correl_descr_id
    from 
      bio_marker path
    , bio_marker gene
    , pictor.kmap_gene kg
    , bio_data_correl_descr bdcd
    where path.bio_marker_type = 'PATHWAY'
    and gene.bio_marker_type = 'GENE' 
    and path.primary_external_id = to_char(kg.map_id)
    and gene.primary_external_id = to_char(kg.gene_id)
    and bdcd.correlation='PATHWAY GENE';
    -- 42,826
-- 43,075 distinct map, gene, tax 
-- 305 genes that are not in ext_gene_id
-- 4,794 genes are human
-- 1 that is not human: rat, geneid 5212, pancreatic cancer
-- 14,529 not in bio_marker and not human
        
    --control.update_system_job_step_pass(jobStepID, SQL%ROWCOUNT);
  commit;
  end;

end;
 
 
 
 
 
 
/
