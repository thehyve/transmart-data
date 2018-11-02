ALTER FUNCTION _final_median(double precision[]) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION _final_median(anyarray) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION copy_security_from_other_study(character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION cz_end_audit(numeric, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION cz_error_handler(numeric, character varying, character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION cz_start_audit(character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION cz_write_audit(numeric, character varying, character varying, character varying, numeric, numeric, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION cz_write_error(numeric, character varying, character varying, character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION drop_all_indexes(character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION get_last_path_component(character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_add_node(character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_add_nodes(character varying, text[], numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_add_platform(character varying, character varying, character varying, character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_add_root_node(character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_add_trial_nodes(character varying, character varying, text[], numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_build_metadata_xml(character varying, character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_create_concept_counts(character varying, numeric, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_create_full_tree(character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_delete_1_node(character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_delete_all_data(character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_delete_partition(character varying, character varying, character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_fill_in_tree(character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_get_hlevel(character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_get_node_name(character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_annotation_deapp(numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_clinical_data(character varying, character varying, character varying, character varying, character varying, numeric, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_metabolomics_annot(numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_mirna_annot_deapp(numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_proteomics_annot(numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_rbm_annotation(bigint) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_rbm_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_samples(character varying, character varying, character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_security_data(numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_security_data(character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_load_study_metadata(numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_metabolomics_zscore_calc(character varying, character varying, character varying, numeric, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_mirna_zscore_calc(character varying, character varying, numeric, character varying, numeric, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_move_study_by_path(character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_generic_hdddata(character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_gwas_plink_data(character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_metabolomic_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_mrna_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_proteomics_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_qpcr_mirna_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_rna_seq_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_snp_data(character varying, character varying, character varying, character varying, numeric, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_process_vcf_data(character varying, character varying, character varying, character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_rbm_zscore_calc_new(character varying, character varying, character varying, numeric, character varying, bigint, character varying, bigint, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION i2b2_rna_seq_annotation(character varying, numeric) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION replace_last_path_component(character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

ALTER FUNCTION timestamp_to_timepoint(character varying, character varying) SET search_path TO "$user", tm_cz, tm_lz, tm_wz, i2b2demodata, i2b2metadata, deapp, public;

