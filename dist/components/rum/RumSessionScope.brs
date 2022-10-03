' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
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
' @param _ph (dynamic) no-op argument to avoid random crash on older Roku devices
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext(_ph as dynamic) as object
    if (m.top.parentScope <> invalid)
        rumContext = m.top.parentScope.callfunc("getRumContext", invalid)
    else
        rumContext = {}
    end if
    rumContext.sessionId = m.sessionId
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    ' TODO RUMM-2478 update session
    if (m.top.activeView <> invalid)
        m.top.activeView.callfunc("handleEvent", event, writer)
        if (not m.top.activeView.callfunc("isActive", invalid))
            m.top.activeView = invalid
        end if
    end if
    if (event.eventType = "startView")
        m.top.activeView = CreateObject("roSGNode", "RumViewScope")
        m.top.activeView.viewName = event.viewName
        m.top.activeView.viewUrl = event.viewUrl
        m.top.activeView.parentScope = m.top
        m.top.activeView.callfunc("handleEvent", {}, writer)
    end if
end sub

' ----------------------------------------------------------------
' Returns information about whether the current scope can handle more events or not
' @param _ph (dynamic) no-op argument to avoid random crash on older Roku devices
' @return (boolean) `true` if this scope expects more event, `false` if it's complete
' ----------------------------------------------------------------
function isActive(_ph as dynamic) as boolean
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