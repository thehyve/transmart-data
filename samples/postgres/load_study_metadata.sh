#!/bin/bash

set -x
set -e

if [ -z "$KETTLE_HOME" ]; then
    echo "KETTLE_HOME is not set"
    exit 1
fi

# $KETTLE_HOME should have been set by the caller
export KETTLE_HOME

$KITCHEN -norep=Y \
-level=Debug \
-file=$KETTLE_JOBS/Load_Study_Metadata.kjb                         \
-log='logs/load_'$STUDY_ID'_study_metadata_'$(date +"%Y%m%d%H%M")'.log' \
-param:METADATA_LOCATION=$METADATA_LOCATION                          \
-param:METADATA_FILENAME='study_metadata.tsv'