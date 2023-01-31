#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: release.sh version

cwd=`pwd` 

rootdir=`git rev-parse --show-toplevel`
subdirs=("library" "test" "sample")

# Upgrade the version in the hardcoded value in the lib
hardcoded="library/source/datadogSdk.bs"
echo "---- Bump version in $hardcoded"
cd $rootdir
sed -i '' -E 's/    return "[0-9]*\.[0-9]*\.[0-9]*[a-z0-9-]*"/    return "'"$1"'"/g' $hardcoded

# Upgrade version defined in the package.json files
for subdir in "${subdirs[@]}";
do
    echo "---- Bump version in $subdir/package.json"
    cd $rootdir
    cd "$subdir"

    npm config set git-tag-version false
    npm config set allow-same-version true
    npm version $1
done

echo "---- Bump version in root dir"
cd $rootdir
npm config set git-tag-version true
npm config set sign-git-tag true
npm version $1 -m "Bump to version $1"


echo "---- Bumped all versions to $1"
cd $cwd

