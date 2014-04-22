--
-- Type: PROCEDURE; Owner: DEAPP; Name: MICROARRAY_COMPARISON_QRY
--
  CREATE OR REPLACE PROCEDURE "DEAPP"."MICROARRAY_COMPARISON_QRY" (
	patient_ids	 IN VARCHAR2, -- CSV list of patient IDs
	sample_types IN VARCHAR2, -- CSV list of concept cds to use for filtering
	-- pathway_name IN VARCHAR2, -- Name of pathway to use for filtering
    pathway_uid1 IN VARCHAR2, --  A Unique pathway ID from BIO_DADA_UID to use for filtering
    timepoints IN VARCHAR2,  -- CSV list of timepoint concept codes
  cv_1 IN OUT SYS_REFCURSOR --Resultset in Cursor for iteration by caller
)
AS
  --Counter to check if samples exist.
  sample_record_count INTEGER;
  timepoint_count INTEGER;
  mapTrialName     varchar2(50);
  dataTrialName	   varchar2(50);
  
  

BEGIN
  -------------------------------------------------------------------------------
   -- Returns PROBESET, GENE_SYMBOL, REFSEQ, LOG10_INTENSITY, PVALUE, PATIENT_ID, ASSAY_ID
   -- result set for specifed Pathways filtered
   -- by Sample Types and Subject_id.
   -- KCR@20090206 - First rev. 
   -- KCR@20090212 - Second rev.  Changed logic so that if Sampel is not found it returns Zero.
   -- KCR@20090206 - Third rev. Using Collections to hold parsed values instead of DB table.
   -- HX@20090317  - Replace pathway_name with pathway_uid
   -- HX@20090318  - Add pathway_uid column into DE_PATHWAY and populate data
   --                from BIOMART.BIO_DATA_UID
   
   -- 2009-05-04: replace refseq with probeset
   -- 2009-05-26: remove GENE_SYMBOL's concatenation and change probeset to refseq
   -- 2009-05-29: change LOG10_INTENSITY to LOG2_INTENSITY
   -- 2009-06-18: add raw_intensity and change log2_intensity to zscore
   -- 2009-06-23: Add timepoints as a parameter
   
   --JEA@20090929	Changed for partitioned tables to improve performance, added select...into
   --				to get trial_name for both main and subquery
   -------------------------------------------------------------------------------
 
-- Check if sample Types Exist
SELECT COUNT(*)
  INTO sample_record_count
  FROM DE_SUBJECT_SAMPLE_MAPPING
    WHERE sample_type_cd IN 
      --Passing string to Text parser Function
      (SELECT * from table(text_parser(sample_types)));
	  
--	Check if timepoints exist

select count(*) into timepoint_count 
from table(text_parser(timepoints));

--	Get trial name for main query and subquery filters

select distinct s.trial_name into mapTrialName
from de_subject_sample_mapping s
where s.patient_id in (SELECT * from table(text_parser(patient_ids)))
and s.platform = 'MRNA_AFFYMETRIX';

dataTrialName := mapTrialName;

--	Deal with BRC names

if mapTrialName = 'BRC Antidepressant Study' then
   datatrialName := 'BRC:mRNA:ADS';
end if;

if mapTrialName = 'BRC Depression Study' then
   datatrialName := 'BRC:mRNA:DS';
end if;
      
 --Sample Record Count is invalid or non existent.
    IF sample_record_count = 0
    THEN
    BEGIN 

      
		if timepoint_count=0 then
		--	no samples or timepoints, only patients
			OPEN cv_1 FOR  
			select a.PROBESET
                ,a.GENE_SYMBOL
	              ,a.refseq
	              ,a.zscore as LOG2_INTENSITY
	              ,a.PVALUE
	              ,a.patient_ID
	              ,a.ASSAY_ID
	              ,a.raw_intensity 
            from de_subject_microarray_data a 
            where a.trial_name = dataTrialName
              and a.assay_id in
                  (select distinct s.assay_id
                  from de_subject_sample_mapping s
                  where s.patient_id in (SELECT * from table(text_parser(patient_ids)) )
                    and s.trial_name = mapTrialName
                  )	  
            and a.gene_symbol in 
               (select distinct gene_symbol
                from DE_pathway_gene c
	                ,de_pathway p
                where p.pathway_uid= pathway_uid1
                  and  p.id =c.pathway_id
                )
          order by a.GENE_SYMBOL, a.PROBESET, a.patient_id ;
      
		else
		  --	no samples, only timepoints and patients
				OPEN cv_1 FOR  
			    select a.PROBESET
                ,a.GENE_SYMBOL
	              ,a.refseq
	              ,a.zscore as LOG2_INTENSITY
	              ,a.PVALUE
	              ,a.patient_ID
	              ,a.ASSAY_ID
	              ,a.raw_intensity 
				from de_subject_microarray_data a 
				where a.trial_name = dataTrialName
				and a.assay_id in
                  (select distinct s.assay_id
                  from de_subject_sample_mapping s
                  where s.patient_id in (SELECT * from table(text_parser(patient_ids)) ) 
				            and s.timepoint_cd in (SELECT * from table(text_parser(timepoints)) )
                    and s.trial_name = mapTrialName
                  )	  
				and a.gene_symbol in 
				(select distinct gene_symbol
					from DE_pathway_gene c
	                ,de_pathway p
                where p.pathway_uid= pathway_uid1
                  and  p.id =c.pathway_id
                )
          order by a.GENE_SYMBOL, a.PROBESET, a.patient_id ;
		end if;
	END;

  --else use all filters (If Subject is non existent or invalid, then return 
    ELSE 
    BEGIN
    
		if timepoint_count=0 then
		--	no timepoints, only samples and patients
			OPEN cv_1 FOR  
			select a.PROBESET
                ,a.GENE_SYMBOL
	              ,a.refseq
	              ,a.zscore as LOG2_INTENSITY
	              ,a.PVALUE
	              ,a.patient_ID
	              ,a.ASSAY_ID
	              ,a.raw_intensity 
            from de_subject_microarray_data a 
            where a.trial_name = dataTrialName
              and a.assay_id in
                  (select distinct s.assay_id
                  from de_subject_sample_mapping s
                  where s.patient_id in (SELECT * from table(text_parser(patient_ids)) )
				    and s.sample_type_cd IN (SELECT * from table(text_parser(sample_types))) 
                    and s.trial_name = mapTrialName
                  )	  
            and a.gene_symbol in 
               (select distinct gene_symbol
                from DE_pathway_gene c
	                ,de_pathway p
                where p.pathway_uid= pathway_uid1
                  and  p.id =c.pathway_id
                )
          order by a.GENE_SYMBOL, a.PROBESET, a.patient_id ;

/*		original code
		OPEN cv_1 FOR        
          select distinct a.PROBESET, a.GENE_SYMBOL, a.refseq, a.zscore as LOG2_INTENSITY, 
                 a.PVALUE, a.patient_ID, a.ASSAY_ID, a.raw_intensity
          FROM DE_SUBJECT_MICROARRAY_DATA a, DE_pathway_gene c, de_pathway p,
               DE_subject_sample_mapping b
          where p.pathway_uid= pathway_uid1 and c.pathway_id= p.id and
                a.gene_symbol = c.gene_symbol and
                a.PATIENT_ID = b.PATIENT_ID and a.assay_id = b.assay_id
                and a.timepoint=b.timepoint and
                b.sample_type_cd IN (SELECT * from table(text_parser(sample_types))) and 
                b.patient_id IN (SELECT * from table(text_parser(patient_ids)))
          order by a.GENE_SYMBOL, a.PROBESET, a.patient_id;
		  */
      
		else
				--	samples, timepoints, and patients, oh my!
		        OPEN cv_1 FOR  
			    select a.PROBESET
                ,a.GENE_SYMBOL
	              ,a.refseq
	              ,a.zscore as LOG2_INTENSITY
	              ,a.PVALUE
	              ,a.patient_ID
	              ,a.ASSAY_ID
	              ,a.raw_intensity 
				from de_subject_microarray_data a 
				where a.trial_name = dataTrialName
				and a.assay_id in
                  (select distinct s.assay_id
                  from de_subject_sample_mapping s
                  where s.patient_id in (SELECT * from table(text_parser(patient_ids)) ) 
				    and s.timepoint_cd in (SELECT * from table(text_parser(timepoints)) )
					and s.sample_type_cd in (SELECT * from table(text_parser(sample_types)))
                    and s.trial_name = mapTrialName
                  )	  
				and a.gene_symbol in 
					(select distinct gene_symbol
					from DE_pathway_gene c
	                ,de_pathway p
					where p.pathway_uid= pathway_uid1
					and  p.id =c.pathway_id
					)
          order by a.GENE_SYMBOL, a.PROBESET, a.patient_id ;
   
/*		original code

        OPEN cv_1 FOR        
          select distinct a.PROBESET, a.GENE_SYMBOL, a.refseq, a.zscore as LOG2_INTENSITY, 
                 a.PVALUE, a.patient_ID, a.ASSAY_ID, a.raw_intensity
          FROM DE_SUBJECT_MICROARRAY_DATA a, DE_pathway_gene c, de_pathway p,
               DE_subject_sample_mapping b
          where p.pathway_uid= pathway_uid1 and c.pathway_id= p.id and
                a.gene_symbol = c.gene_symbol and
                b.sample_type_cd IN (SELECT * from table(text_parser(sample_types))) and 
                b.patient_id IN (SELECT * from table(text_parser(patient_ids))) and
                b.TIMEPOINT_CD IN (SELECT * from table(text_parser(timepoints))) and 
                a.PATIENT_ID=b.patient_id and a.timepoint=b.timepoint and 
                a.assay_id=b.assay_id    
          order by a.GENE_SYMBOL, a.PROBESET, a.patient_id; */
          
        end if;
    
	END;
  END IF;  
END microarray_comparison_qry; 

 
 
 
 
/
