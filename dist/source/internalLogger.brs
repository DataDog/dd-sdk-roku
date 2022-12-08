' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
' *****************************************************************
' * Common internal logging functions
' *****************************************************************

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_verbose` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub ddLogVerbose(message as string)
    if (__isLogLevelAllowed(4))
        'bs:disable-next-line
        print __logPrefix(); "    >> "; message
    end if
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_info` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub ddLogInfo(message as string)
    if (__isLogLevelAllowed(3))
        'bs:disable-next-line
        print __logPrefix(); " ℹℹ >> "; message
    end if
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_warning` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub ddLogWarning(message as string)
    if (__isLogLevelAllowed(2))
        'bs:disable-next-line
        print __logPrefix(); " ⚠️  >> "; message
    end if
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_error` compiler flag is enabled
' @param message (string) the message to log
' @param error (object) the caught exception
' ----------------------------------------------------------------
sub ddLogError(message as string, error = invalid as object)
    if (__isLogLevelAllowed(1))
        'bs:disable-next-line
        print __logPrefix(); " ‼️  >> "; message
        if (type(error) = "roAssociativeArray")
            'bs:disable-next-line
            print "              " + errorToString(error)
        end if
    end if
end sub

' ----------------------------------------------------------------
' Prints information about the current thread
' @param operationName (string) the current operation (default is "")
' ----------------------------------------------------------------
sub ddLogThread(operationName = "" as string)
    if (__isLogLevelAllowed(5))
        node = CreateObject("roSGNode", "Node")
        threadInfo = node.threadInfo()
        'bs:disable-next-line
        print __logPrefix(); " ⚙  >> "; operationName; " on thread "; threadInfo.currentThread.name; " ("; threadInfo.currentThread.type; ":"; threadInfo.currentThread.id; ")"
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
' @param number (integer) the positive number to convert
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
' Checks whether the given log level is allowed in the current app
' @param level (LogLevel) the level of the log (1: error; 2: warning; )
' ----------------------------------------------------------------
function __isLogLevelAllowed(level as object) as boolean
    if (m.global <> invalid)
        verbosity = (function(m)
                __bsConsequent = m.global.datadogVerbosity
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return 0
                end if
            end function)(m)
        return level <= verbosity
    end if
    return false
end function
' ****************************************************************
' * LogLevel: level (severity) of logs
' ****************************************************************
