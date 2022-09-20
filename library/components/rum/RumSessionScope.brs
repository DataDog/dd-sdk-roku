' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ****************************************************************
' * RumSessionScope: handles the Session level,
' * delegates most to the children
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.sessionId = CreateObject("roDeviceInfo").GetRandomUUID()
end sub

' ----------------------------------------------------------------
' Returns the current context from this scope
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext() as object
    if (m.top.parentScope <> invalid)
        rumContext = m.top.parentScope.callFunc("getRumContext")
    else
        rumContext = {}
    end if

    rumContext.sessionId = m.sessionId
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    ' TODO RUMM-2478 update session

    if (m.top.activeView <> invalid)
        m.top.activeView.callFunc("handleEvent", event, writer)
        if (not m.top.activeView.callFunc("isActive"))
            m.top.activeView = invalid
        end if
    end if

    if (event.eventType = "startView")
        m.top.activeView = CreateObject("roSGNode", "RumViewScope")
        m.top.activeView.viewName = event.viewName
        m.top.activeView.viewUrl = event.viewUrl
        m.top.activeView.parentScope = m.top
        m.top.activeView.callFunc("handleEvent", {}, writer)
    end if
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
' Updates the internal session info based on Datadog logic
' ----------------------------------------------------------------
sub updateSession()
    ' TODO RUMM-2478 Implement session update logic
    if (m.sessionId = invalid)
        m.sessionId = m.deviceInfo.GetRandomUUID()
    end if
end sub
