#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: sca.sh path/to/app.zip

cwd=`pwd` 

echo "---- Static channel analysis"

if [[ -z "${ROKU_SCA}" ]]; then
    echo "ERROR: ROKU_SCA is not set."
    exit 1
fi

echo " - Using sca tool at $ROKU_SCA on file $1"
$ROKU_SCA -e=error "$1" 
result=$?
if (( $result > 0 )); then
    echo "ERROR: failed Static channel analysis"
    exit $result
fi
