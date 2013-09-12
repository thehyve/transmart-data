<?php require __DIR__ . '/../../inc/host_fixup.php' ?>
driver_class=org.postgresql.Driver

url=jdbc:postgresql://<?= $host ?>:<?= $_ENV['PGPORT'] ?>/<?= $_ENV['PGDATABASE'], "\n" ?>

tm_cz_username=tm_cz
tm_cz_password=tm_cz
