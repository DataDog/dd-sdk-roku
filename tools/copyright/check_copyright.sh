#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

IFS=$'\n'

# Lists all files requiring the license header.
function files {
	find -E . -iregex '.*\.(xml|brs|sh)$' \
        -not -path "*/node_modules/*" \
        -not -path "*/roku_modules/*" 
}

FILES_WITH_MISSING_LICENSE=""

for file in $(files); do
	if ! grep -q "Apache License Version 2.0" "$file"; then
		FILES_WITH_MISSING_LICENSE="${FILES_WITH_MISSING_LICENSE}\n${file}"
	fi
done

if [ -z "$FILES_WITH_MISSING_LICENSE" ]; then
	echo "✔ All files include the license header"
	exit 0
else
	echo -e "✘ Missing the license header in files: $FILES_WITH_MISSING_LICENSE"
	exit 1
fi