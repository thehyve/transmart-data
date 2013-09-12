<?php
/* argument: params file */
$data = [];
foreach (new SplFileObject($argv[1]) as $line) {
	if (preg_match('/^\s*(.+)=["]?(.+?)"?$/', $line, $matches)) {
		$data[$matches[1]] = $matches[2];
	}
}
$expected_keys = [
	'DATA_FILE',
	'PLATFORM',
	'TITLE'];
sort($expected_keys);

$read_keys = array_keys($data);
sort($read_keys);

if ($expected_keys !== $read_keys) {
	fprintf(STDERR, "Mismatch between expected and read:\n%s\nvs\n%s\n",
		var_export($expected_keys, true),
		var_export($read_keys, true));
	exit(1);
}

$data['SOURCE_DIRECTORY'] = realpath(dirname($argv[1]) . "/snp_annotation");
if (!$data['SOURCE_DIRECTORY']) {
	fprintf(STDERR, "Could not calculate realpath of source dir\n");
	exit(1);
}
$data['DESTINATION_DIRECTORY'] = $data['SOURCE_DIRECTORY'] . '/out';
?>
source_directory=<?= $data['SOURCE_DIRECTORY'], "\n" ?>
input_file=<?= $data['DATA_FILE'], "\n" ?>
destination_directory=<?= $data['DESTINATION_DIRECTORY'], "\n" ?>

probe_info_file=RICERCA.probeinfo
snp_gene_map_file=RICERCA.genemap
snp_map_file=RICERCA.map

platform=<?= $data['PLATFORM'], "\n" ?>
title=<?= $data['TITLE'], "\n" ?>
marker_type=SNP
organism=Homo sapiens
recreate_annotation_table=no
gene_info_table=gene_info

skip_gx_annotation_loader=yes
skip_taxonomy_name=yes
skip_gene_info=yes
skip_gx_gpl_loader=yes

skip_gpl_annotation_loader=no
skip_de_gpl_info=no
skip_de_snp_info=no
skip_de_snp_probe=no
skip_de_snp_gene_map=no
