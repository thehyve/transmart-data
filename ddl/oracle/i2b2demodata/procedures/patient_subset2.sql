--
-- Type: PROCEDURE; Owner: I2B2DEMODATA; Name: PATIENT_SUBSET2
--
  CREATE OR REPLACE PROCEDURE "I2B2DEMODATA"."PATIENT_SUBSET2" (
  p_result_instance_id IN VARCHAR2,
  p_pathway IN VARCHAR2,
  p_refcur  OUT SYS_REFCURSOR) AS

BEGIN

OPEN p_refcur FOR SELECT * FROM (WITH
  patients AS (SELECT DISTINCT a.patient_num
        FROM qt_patient_set_collection a,
             qt_query_result_instance b,
             qt_query_instance c,
             qt_query_master d
        WHERE a.result_instance_id = b.result_instance_id AND
              b.query_instance_id = c.query_instance_id AND
              c.query_master_id = d.query_master_id AND
              b.result_instance_id = p_result_instance_id),

 samples AS  (SELECT a.concept_cd  FROM concept_dimension a WHERE a.concept_path IN (
    SELECT SUBSTR(item_key,INSTR(item_key,'\',1,3)) FROM (
      SELECT extractValue(value(ik),'/item_key') item_key FROM (SELECT sys.xmltype.createXML(a.i2b2_request_xml) col
        FROM qt_query_master a,
             qt_query_instance b,
             qt_query_result_instance c
        WHERE a.query_master_id = b.query_master_id AND
              b.query_instance_id = c.query_instance_id AND
              c.result_instance_id = p_result_instance_id) tab1,
              TABLE(xmlsequence(extract(col,'//ns4:request/query_definition/panel/item/item_key',
                                            'xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/"'))) ik)))

  SELECT DISTINCT a.probeset, a.gene_symbol, a.refseq, a.log10_intensity, a.pvalue, b.patient_uid, a.assay_id
      FROM i2b2_subject_assay_data a
      JOIN i2b2_subject_sample_mapping b
        ON a.patient_id = b.patient_id
      JOIN i2b2_pathway_gene c
        ON a.gene_symbol = c.gene_symbol
      JOIN i2b2_pathway d
        ON d.id = c.pathway_id
      WHERE d.name = p_pathway
        AND b.patient_uid IN (SELECT patient_num FROM patients)
        AND B.concept_code IN (CASE WHEN ( SELECT COUNT(*) FROM I2B2_SUBJECT_SAMPLE_MAPPING
                                       WHERE concept_code IN (SELECT concept_cd FROM samples))>0 THEN
                                         (SELECT concept_cd FROM samples)
                                       ELSE
                                         (SELECT concept_code FROM I2B2_SUBJECT_SAMPLE_MAPPING)
                                      END));
END PATIENT_SUBSET2;
 

 
 
 
 
 
 
 
 
/
 
