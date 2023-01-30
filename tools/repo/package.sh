#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: package.sh source_folder

echo "---- Create tmp folder"
mkdir -p "tmp/components/roku_modules"
mkdir -p "tmp/source/roku_modules"

echo "---- Extract version number"
releaseversion=`awk -F'"' '/"version": ".+"/{ print $4; exit; }' package.json`

echo "---- Packaging library from folder $1"
cp -r "$1/components/roku_modules/datadogroku" "tmp/components/roku_modules"
cp -r "$1/source/roku_modules/datadogroku" "tmp/source/roku_modules"

echo "---- Creating zip archive datadogroku-$releaseversion.zip"
zip -r "datadogroku-$releaseversion.zip" "tmp"

echo "---- Cleanup tmp folder"
rm -r "tmp"
