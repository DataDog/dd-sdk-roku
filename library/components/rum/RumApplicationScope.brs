' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ****************************************************************
' * RumApplicationScope: handles the Application level,
' * delegates most to the children
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.applicationVersion = CreateObject("roAppInfo").GetVersion()
end sub

' ----------------------------------------------------------------
' Returns the current context from this scope
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext() as object
    return {
        applicationId: m.top.applicationId,
        serviceName: m.top.serviceName,
        applicationVersion: m.applicationVersion
    }
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    ensureSessionScope()
    m.top.sessionScope.callFunc("handleEvent", event, writer)
end sub

' ----------------------------------------------------------------
' Returns information about whether the current scope can handle more events or not
' @return (boolean) `true` if this scope expects more event, `false` if it's complete
' ----------------------------------------------------------------
function isActive() as boolean
    ' TODO
    return invalid
end function

' ----------------------------------------------------------------
' Sets the internal session scope from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureSessionScope()
    if (m.top.sessionScope = invalid)
        m.top.sessionScope = CreateObject("roSGNode", "RumSessionScope")
    end if
end sub