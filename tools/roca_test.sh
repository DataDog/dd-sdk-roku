#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

set -e

# Resolve the repo root regardless of where the script is called from
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "---- Cleaning up ropm symlinks and stale build output"
rm -rf \
    "$REPO_ROOT/test/node_modules" \
    "$REPO_ROOT/sample/node_modules" \
    "$REPO_ROOT/library/node_modules" \
    "$REPO_ROOT/roca_tests/out"

echo "---- Installing roca test dependencies"
npm install --prefix "$REPO_ROOT/roca_tests"

echo "---- Compiling BrighterScript test sources"
cd "$REPO_ROOT/roca_tests"
./node_modules/.bin/bsc

echo "---- Running roca tests"
./node_modules/.bin/roca \
    --source ../dist/source \
    --require out/helpers/itemGenerator.brs \
    "$@" \
    'out/source/**/*.test.brs'
