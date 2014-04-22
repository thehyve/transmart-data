--
-- Type: PROCEDURE; Owner: TM_CZ; Name: PARSE_DESIGN_FIELD
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."PARSE_DESIGN_FIELD" 
as
  
  bcc_exp number;

  design_fields varchar_table;
  
  cursor c_design
  is
  select bio_experiment_id, design from bio_experiment
  where bio_experiment_type='Experiment'
  and design is not null;

begin

  begin
    delete from bio_data_attribute
      where bio_data_id in 
        (select bio_experiment_id 
        from bio_experiment
        where bio_experiment.bio_experiment_type='Experiment'
        and design is not null);
   end;

  begin
    insert into bio_concept_code(
      bio_concept_code
    , code_description
    , code_type_name
    )
    select 
      'Experiment Design'
    , 'Experiment Design'
    , 'Design'
    from dual
    where not exists
      (select 1 from bio_concept_code
      where bio_concept_code='Experiment Design');
  commit;
  end;
  
  begin
  
    select bio_concept_code_id 
    into bcc_exp
    from bio_concept_code
    where bio_concept_code = 'Experiment Design';
    
    design_fields := control.varchar_table();
    
    for r_design in c_design loop    
      design_fields := control.text_parser(r_design.design, ',');
      for i in design_fields.first..design_fields.last loop
        insert into bio_data_attribute(
          bio_data_id
        , property_code
        , property_value
        )
        select
          r_design.bio_experiment_id
        , bcc_exp
        , ltrim(upper(replace(design_fields(i), '_', ' ')))
        from dual
        where r_design.bio_experiment_id not in (
          select bio_data_id from bio_data_attribute
          where property_code=bcc_exp
          and property_value=ltrim(upper(replace(design_fields(i), '_', ' '))));
            
      end loop;
    
    end loop;
  
  commit;
  end;
end;
 
 
 
 
 
 
 
/
 
