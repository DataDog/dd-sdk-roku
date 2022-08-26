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
    print "Datadog    >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_info` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logInfo(message as string)
    print "Datadog ℹℹ >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_warning` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logWarning(message as string)
    print "Datadog ⚠️  >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_error` compiler flag is enabled
' @param message (string) the message to log
' @param error (object) the caught exception
' ----------------------------------------------------------------
sub logError(message as string, error = invalid as object)

    print "Datadog ‼️  >> "; message
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
    frameCount = error.backtrace.count()
    lastFrame = error.backtrace[frameCount - 1]

    msg = error.message + " (runtime error &h" + decToHex(error.number) + ") in " + lastFrame.filename + "(" + lastFrame.line_number.toStr() + ")"
    for i = (frameCount - 1) to 0 step -1
        frame = error.backtrace[i]
        msg = msg + chr(10) + "#" + i.toStr() + "  Function " + frame.function
        msg = msg + chr(10) + "   file/line: " + lastFrame.filename + "(" + lastFrame.line_number.toStr() + ")"
    end for

    return msg
end function


' ----------------------------------------------------------------
' Converts an integer to hexadecimal string (without prefix)
' @param number (integer) the postitive number to convert
' @return (string) the hexadecimal string
' ----------------------------------------------------------------
function decToHex(number as integer) as string
    hexTab = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    hex = ""
    while (number > 0)
        hex = hexTab [number mod 16] + hex
        number = number / 16
    end while

    if (hex = "")
        return "0"
    else
        return hex
    end if
end function
