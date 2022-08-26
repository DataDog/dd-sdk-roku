' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
'* Utility functions around time
'*****************************************************************

' ----------------------------------------------------------------
' Returns the current timestamp in milliseconds since EPOCH
' @return (longinteger) the number of millis since jan 1st 1970
' ----------------------------------------------------------------
function getTimestamp() as longinteger
    date = CreateObject("roDateTime")
    seconds& = date.AsSeconds() ' number of seconds since EPOCH
    millis& = date.GetMilliseconds() ' number of millisecond in current second [0-999]
    timestamp& = (seconds& * 1000) + millis&
    return timestamp&
end function
