#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

cwd=`pwd` 

for var in "$@"
do
    echo "---- Linting folder $var"
    cd $var

    if [ -f "package.json" ]; then
        echo " - Install ROPM dependencies"
        ropm install
        echo " - Cleanup node junk"
        rm -r node_modules
    fi

    echo " - Run BrighterScript compiler/linter"
    bsc --lintConfig ../tools/lint/bslint.json
    result=$?

    # back to root folder
    cd $cwd 
    if (( $result > 0 )); then
        exit $result
    fi
done