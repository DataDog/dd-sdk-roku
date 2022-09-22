#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

cwd=`pwd` 

for var in "$@"
do
    echo "---- Static code analysis for folder $var"
    cd $var

    if [ -f "package.json" ]; then
        echo " - Install ROPM dependencies"
        ropm install
    fi

    echo " - Cleanup node junk"
    rm -r node_modules

    echo " - Make application"
    export DISTDIR="out/" 
    export DISTZIP="app-$var" 
    make

    echo " - Static Channel Analysis"
    $ROKU_SCA -e=error "out/app-$var.zip" 
    result=$?

    echo " - Cleanup environment"
    unset DISTDIR
    unset DISTZIP

    # back to root folder
    cd $cwd 
    if (( $result > 0 )); then
        exit $result
    fi
done