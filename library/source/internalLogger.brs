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
    print "Datadog Verbose >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_info` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logInfo(message as string)
    print "Datadog    Info >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_warning` compiler flag is enabled
' @param message (string) the message to log
' ----------------------------------------------------------------
sub logWarning(message as string)
    print "Datadog Warning >> "; message
end sub

' ----------------------------------------------------------------
' Outputs the message in parameter if the `dd_error` compiler flag is enabled
' @param message (string) the message to log
' @param error (object) the caught exception
' ----------------------------------------------------------------
sub logError(message as string, error as object)
    print "Datadog   Error >> "; message
    if (type(error) = "roAssociativeArray")
        print "Error #" + error.number.ToStr() + ": " + error.message
        for each frame in error.backtrace
            print frame.function + " (" + frame.filename + ":" + frame.line_number.ToStr() + ")"
        end for
    end if
end sub

