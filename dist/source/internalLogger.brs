' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'*****************************************************************
'* Common internal logging functions
'*****************************************************************

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_verbose` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logVerbose(message as string)
    print __logPrefix(); "    >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_info` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logInfo(message as string)
    print __logPrefix(); " ℹℹ >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_warning` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logWarning(message as string)
    print __logPrefix(); " ⚠️  >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_error` compiler flag is enabled
' @param message (string) the message to log
' @param error (object) the caught exception
' ----------------------------------------------------------------
sub logError(message as string, error = invalid as object)
    print __logPrefix(); " ‼️  >> "; message
    if (type(error) = "roAssociativeArray")
        print "              " + errorToString(error)
    end if
end sub

' ----------------------------------------------------------------
' Returns the error as a multiline String matching the standard Roku output
' @param error (object) the caught exception
' @return (string) the string representation of the error with its backtrace
' ----------------------------------------------------------------
function errorToString(error as object) as string
    msg = ""
    if (error.message <> invalid)
        msg += error.message
    end if
    if (error.number <> invalid)
        msg += " (runtime error &h" + decToHex(error.number) + ")"
    end if
    if (error.backtrace <> invalid)
        frameCount = error.backtrace.count()
        lastFrame = error.backtrace[frameCount - 1]
        msg = msg + " in " + lastFrame.filename + "(" + lastFrame.line_number.toStr() + ")"
        msg = msg + chr(10) + backtraceToString(error.backtrace)
        return msg
    end if
    return msg
end function

' ----------------------------------------------------------------
' Returns an exception's backtrace as a multiline String matching the standard Roku output
' @param backtrace (object) the exception backtrace array
' @return (string) the string representation of the backtrace
' ----------------------------------------------------------------
function backtraceToString(backtrace as object) as dynamic
    if (backtrace = invalid)
        return invalid
    end if
    frameCount = backtrace.count()
    msg = ""
    first = true
    for i = (frameCount - 1) to 0 step - 1
        frame = backtrace[i]
        if (not first)
            msg = msg + chr(10)
        end if
        msg = msg + "#" + i.toStr() + "  Function " + frame.function
        msg = msg + chr(10) + "   file/line: " + frame.filename + "(" + frame.line_number.toStr() + ")"
        first = false
    end for
    return msg
end function

' ----------------------------------------------------------------
' @return (string) the prefix for all Datadog logs
' ----------------------------------------------------------------
function __logPrefix() as string
    return "Datadog " + __shortTimestamp()
end function

' ----------------------------------------------------------------
' @return (string) a short representation of the current timestamp
' ----------------------------------------------------------------
function __shortTimestamp() as string
    date = CreateObject("roDateTime")
    seconds& = date.AsSeconds()
    return (seconds& mod 100).toStr() + "." + date.GetMilliseconds().toStr()
end function

' ----------------------------------------------------------------
' Converts an integer to hexadecimal string (without prefix)
' @param number (integer) the postitive number to convert
' @return (string) the hexadecimal string
' ----------------------------------------------------------------
function decToHex(number as integer) as string
    hexTab = [
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "A"
        "B"
        "C"
        "D"
        "E"
        "F"
    ]
    hex = ""
    while (number > 0)
        hex = hexTab[number mod 16] + hex
        number = number / 16
    end while
    if (hex = "")
        return "0"
    else
        return hex
    end if
end function

' ----------------------------------------------------------------
' Prints information about the current thread
' @param operationName (string) the current operation (default is "")
' ----------------------------------------------------------------
sub logThread(operationName = "" as string)
    node = CreateObject("roSGNode", "Node")
    threadInfo = node.threadInfo()
    logVerbose(operationName + " on thread " + threadInfo.currentThread.name + " (" + threadInfo.currentThread.type + ":" + threadInfo.currentThread.id + ")")
end sub