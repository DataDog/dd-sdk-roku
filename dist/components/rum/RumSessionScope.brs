' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
'import "pkg:/source/rum/rumSessionState.bs"
' ****************************************************************
' * RumSessionScope: handles the Session level,
' * delegates most to the children
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
end sub

' ----------------------------------------------------------------
' Returns the current context from this scope
' @param _ph (dynamic) no-op argument to avoid random crash on older Roku devices
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext(_ph as dynamic) as object
    rumContext = {}
    if (m.top.parentScope <> invalid)
        rumContext = m.top.parentScope.callfunc("getRumContext", invalid)
    end if
    rumContext.sessionId = m.sessionId
    rumContext.sessionState = m.sessionState
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    ' TODO RUMM-2478 update session (+ update global rum context)
    updateSession(event.eventType)
    if (m.sessionState = "tracked")
        currentWriter = writer
    else
        currentWriter = {
            writer: "noOp"
            writeEvent: ""
        }
    end if
    if (m.top.activeView <> invalid)
        m.top.activeView.callfunc("handleEvent", event, currentWriter)
        if (not m.top.activeView.callfunc("isActive", invalid))
            m.top.activeView = invalid
        end if
    end if
    if (event.eventType = "startView")
        m.top.activeView = CreateObject("roSGNode", "RumViewScope")
        m.top.activeView.viewName = event.viewName
        m.top.activeView.viewUrl = event.viewUrl
        m.top.activeView.parentScope = m.top
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
sub updateSession(eventType as dynamic)
    ddLogThread("RumSessionScope.updateSession()")
    timestampMs& = getTimestamp()
    isFirstSession = m.sessionId = invalid
    isInteraction = (eventType = "startView") or (eventType = "addAction") or (eventType = "resetSession")
    lastInteractionMs& = (function(m)
            __bsConsequent = m.lastInteractionTimestampMs&
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return 0
            end if
        end function)(m)
    sessionStartMs& = (function(m)
            __bsConsequent = m.sessionStartMs
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return 0
            end if
        end function)(m)
    timeSinceLastInteractionMs = timestampMs& - lastInteractionMs&
    timeSinceSessionStartMs = timestampMs& - sessionStartMs&
    isExpired = timeSinceLastInteractionMs >= m.top.inactivityThresholdMs
    isTimedOut = timeSinceSessionStartMs >= m.top.maxDurationMs
    if (isInteraction)
        if (isFirstSession or isExpired or isTimedOut)
            renewSession(timestampMs&)
        end if
        m.lastInteractionTimestampMs& = timestampMs&
    else if (isExpired)
        m.sessionState = "expired"
    end if
end sub

' ----------------------------------------------------------------
' Renews the internal session
' @param timestamp& (longinteger) the event timestamp in milliseconds
' ----------------------------------------------------------------
sub renewSession(timestamp& as longinteger)
    ddLogWarning("Renewing the session")
    m.sessionId = CreateObject("roDeviceInfo").GetRandomUUID()
    m.sessionStartMs = timestamp&
    rndSession = (Rnd(101) - 1) ' Rnd(n) returns a number between 1 and n (both inclusive)
    if (rndSession < m.top.sessionSampleRate)
        m.sessionState = "tracked"
    else
        m.sessionState = "not_tracked"
    end if
    datadogRumContext = m.global.datadogRumContext
    datadogRumContext.sessionId = m.sessionId
    m.global.setField("datadogRumContext", datadogRumContext)
end sub