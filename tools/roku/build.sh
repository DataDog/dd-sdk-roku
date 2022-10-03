#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: build.sh folder

cwd=`pwd` 

for var in "$@"
do
    echo "---- Building folder $var"
    cd $var

    if [ -f "package.json" ]; then
        echo " - Install ROPM dependencies"
        ropm install
    fi

    echo " - Run BrighterScript compiler/linter (version ‘$(bsc --version)’)"
    bsc --lintConfig ../tools/lint/bslint.json
    result=$?

    # Needs to happen after calling bsc as it needs bslint in node_modules
    echo " - Cleanup node junk"
    rm -r node_modules

    # back to root folder
    cd $cwd 
    if (( $result > 0 )); then
        exit $result
    fi
done