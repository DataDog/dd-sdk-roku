#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: cleanup.sh

echo "---- Clean up MacOs .DS_Store"
find . -name ".DS_Store" -print -delete

echo "---- Clean up Node"
find . -name "node_modules" -type d -print -exec rm -rv {} \;
find . -name "package-lock.json" -print -delete

echo "---- Clean up Roku"
find . -name "roku_modules" -type d -print -exec rm -rv {} \;
find . -name "out" -type d -print -exec rm -rv {} \;
