' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.


'*****************************************************************
'* MockRumScope: a mock for a Rum*Scope component.
'*****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
end sub

' ----------------------------------------------------------------
' Returns the current context from this scope
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext() as object
    recordFunctionCall("getRumContext", {})
    returnValue = getStubReturnValue("getRumContext", {})
    if (returnValue <> invalid)
        return returnValue
    else
        return {}
    end if
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    recordFunctionCall("handleEvent", { event: event, writer: writer })
end sub


' ----------------------------------------------------------------
' Returns information about whether the current scope can handle more events or not
' @return (boolean) `true` if this scope expects more event, `false` if it's complete
' ----------------------------------------------------------------
function isActive() as boolean
    recordFunctionCall("isActive", {})
    return getStubReturnValue("isActive", {})
end function
