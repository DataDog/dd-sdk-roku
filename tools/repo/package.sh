#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: package.sh source_folder

set -e

echo "---- Create temporary staging folder"
staging_dir="$(mktemp -d)"
cleanup() {
    echo "---- Cleanup temporary staging folder"
    rm -rf "$staging_dir"
}
trap cleanup EXIT

mkdir -p "$staging_dir/components/roku_modules"
mkdir -p "$staging_dir/source/roku_modules"

echo "---- Extract version number"
releaseversion="$(awk -F'"' '/"version": ".+"/{ print $4; exit; }' package.json)"

echo "---- Packaging library from folder $1"
cp -r "$1/components/roku_modules/datadogroku" "$staging_dir/components/roku_modules"
cp -r "$1/source/roku_modules/datadogroku" "$staging_dir/source/roku_modules"

echo "---- Creating zip archive datadogroku-$releaseversion.zip"
archive_path="$(pwd)/datadogroku-$releaseversion.zip"
rm -f "$archive_path"
(
    cd "$staging_dir"
    zip -r "$archive_path" components source
)
