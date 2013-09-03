<?php
$manual_objects = [
    'tm_cz' => [],
];

foreach (glob('macroed_functions/*.pre.sql') as $file) {
    $manual_objects['tm_cz'][] = ['FUNCTION',
            preg_replace('/macroed_functions\/(.*)\.pre\.sql/', '$1', $file)];
}

// vim: et ts=4 sw=4:
