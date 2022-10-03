#!/bin/bash
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Today Datadog, Inc.

# usage: install.sh path/to/app.zip

echo "---- Checking environment"

if [[ -z "${ROKU_DEV_TARGET}" ]]; then
    echo "ERROR: ROKU_DEV_TARGET is not set."
    exit 1
fi
if [[ -z "${ROKU_DEV_USERNAME}" ]]; then
    echo "ERROR: ROKU_DEV_USERNAME is not set."
    exit 1
fi
if [[ -z "${ROKU_DEV_PASSWORD}" ]]; then
    echo "ERROR: ROKU_DEV_PASSWORD is not set."
    exit 1
fi

echo "   Using device $ROKU_DEV_TARGET with username $ROKU_DEV_USERNAM and password ********"

DEV_SERVER_TMP_FILE=/tmp/dev_server_out
rm -f $DEV_SERVER_TMP_FILE

echo "---- Checking dev server at $ROKU_DEV_TARGET..."

# this script assumes it is runs on MacOS. On other platform, ping arguments can vary
ping -c 1 -W 1 $ROKU_DEV_TARGET > $DEV_SERVER_TMP_FILE 2>&1
result=$?
if (( $result > 0 )); then
    echo "ERROR: Device at $ROKU_DEV_TARGET is not responding to ping.";
    exit $result
fi

# Test for ECP (External Control Protocol); i.e.: is this a Roku device?
rm -f $DEV_SERVER_TMP_FILE
curl --connect-timeout 2 --silent --output $DEV_SERVER_TMP_FILE http://${ROKU_DEV_TARGET}:8060 
result=$?
if (( $result > 0 )); then
    echo "ERROR: Device at $ROKU_DEV_TARGET is not responding to ECP.";
    exit $result
fi
ROKU_DEV_TARGET_NAME=`xmllint --xpath "//*[local-name()='friendlyName']/text()" "$DEV_SERVER_TMP_FILE"`
echo "   Device reports as '$ROKU_DEV_TARGET_NAME'."

# Test for dev web server; i.e.: can we upload an app?
rm -f $DEV_SERVER_TMP_FILE
HTTP_STATUS=`curl --connect-timeout 2 --silent --output $DEV_SERVER_TMP_FILE --write-out "%{http_code}" http://${ROKU_DEV_TARGET}`
result=$?
if (( $result > 0 )); then
    echo "ERROR: Device at $ROKU_DEV_TARGET is not responding.";
    exit $result
fi
echo "   Dev server for '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET) is ready."

echo "---- Uninstalling previous app"
HTTP_STATUS=`curl --user "$ROKU_DEV_USERNAME:$ROKU_DEV_PASSWORD" --digest --silent --show-error -F "mysubmit=Delete" -F "archive=" --output $DEV_SERVER_TMP_FILE --write-out "%{http_code}" http://$ROKU_DEV_TARGET/plugin_install`
result=$?
if (( $result > 0 )); then
    echo "ERROR: Device '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET) is not responding.";
    exit $result
fi
if (( $HTTP_STATUS == 200 )); then
    echo "   Uninstalled previous dev app on device '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET).";
else
    echo "ERROR: Device '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET) answered $HTTP_STATUS.";
    exit 1
fi

echo "---- Installing app $1"
HTTP_STATUS=`curl --user "$ROKU_DEV_USERNAME:$ROKU_DEV_PASSWORD" --digest --silent --show-error -F "mysubmit=Install" -F "archive=@$1" --output $DEV_SERVER_TMP_FILE --write-out "%{http_code}" http://$ROKU_DEV_TARGET/plugin_install`
result=$?
if (( $result > 0 )); then
    echo "ERROR: Device '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET) is not responding.";
    exit $result
fi
if (( $HTTP_STATUS == 200 )); then
    echo "SUCCESS: Installed $1 on device '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET).";
else
    echo "ERROR: Device '$ROKU_DEV_TARGET_NAME' ($ROKU_DEV_TARGET) answered $HTTP_STATUS.";
    exit 1
fi
