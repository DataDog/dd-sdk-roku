' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/rum/rumHelper.bs"
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
    ' Handle vital events at session scope (not delegated to view)
    if (event.eventType = "startFeatureOperation" or event.eventType = "stopFeatureOperation")
        handleVitalEvent(event, currentWriter)
        return
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
        m.top.activeView.context = (function(event)
                __bsConsequent = event.context
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return {}
                end if
            end function)(event)
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
    ddLogInfo("Renewing the session (sampling rate: " + m.top.sessionSampleRate.toStr() + ")")
    m.sessionId = CreateObject("roDeviceInfo").GetRandomUUID()
    m.sessionStartMs = timestamp&
    m.activeOperations = {}
    rndSession = Rnd(100) ' Rnd(n) returns a number between 1 and n (both inclusive)
    if (rndSession <= m.top.sessionSampleRate)
        m.sessionState = "tracked"
    else
        m.sessionState = "not_tracked"
    end if
    datadogRumContext = (function(m)
            __bsConsequent = m.global.datadogRumContext
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(m)
    datadogRumContext.sessionId = m.sessionId
    m.global.setField("datadogRumContext", datadogRumContext)
end sub

' ----------------------------------------------------------------
' Handles a vital operation event (start or stop)
' @param event (object) the raw event (startFeatureOperation or stopFeatureOperation)
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleVitalEvent(event as object, writer as object)
    ' Determine step type from event type
    if (event.eventType = "startFeatureOperation")
        stepType = "start"
    else
        stepType = "end"
    end if
    ' Track active operations and log developer warnings
    lookupKey = __operationLookupKey(event.name, event.operationKey)
    if (stepType = "start")
        __trackOperationStart(event.name, event.operationKey, lookupKey)
    else
        __trackOperationEnd(event.name, event.operationKey, lookupKey)
    end if
    ' Build and write the vital event (always emitted, warnings do not suppress)
    sendVitalEvent(event, stepType, writer)
end sub

' ----------------------------------------------------------------
' Sends a vital operation step event
' @param event (object) the raw event containing vitalId, name, operationKey, failureReason, and context
' @param stepType (string) the step type (VitalStepType enum value: "start" or "end")
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendVitalEvent(event as object, stepType as string, writer as object)
    ' Use the timestamp given as it is more accurate to when the operation started.
    if (event.timestamp <> invalid)
        timestamp& = event.timestamp
    else
        timestamp& = getTimestamp()
    end if
    rumContext = getRumContext(invalid)
    ' Get view context if available
    if (m.top.activeView <> invalid)
        viewId = m.top.activeView.callfunc("getRumContext", invalid).viewId
        viewUrl = m.top.activeView.viewUrl
        viewName = m.top.activeView.viewName
        viewContext = (function(m)
                __bsConsequent = m.top.activeView.context
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return {}
                end if
            end function)(m)
    else
        ddLogWarning("Vital operation event received without an active view. The event will be sent with incomplete context information.")
        viewId = "00000000-0000-0000-0000-000000000000"
        viewUrl = ""
        viewName = invalid
        viewContext = {}
    end if
    ' Merge attributes: Global < View < Command
    mergedContext = mergeContext(mergeContext(m.global.datadogContext, viewContext), (function(event)
            __bsConsequent = event.context
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(event))
    vitalEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        application: {
            id: rumContext.applicationId
        }
        context: mergedContext
        date: timestamp&
        device: {
            type: "tv"
            name: rumContext.deviceName
            model: rumContext.deviceModel
            brand: "Roku"
        }
        os: {
            name: "Roku"
            version: rumContext.osVersion
            version_major: rumContext.osVersionMajor
        }
        service: rumContext.service
        session: {
            has_replay: false
            id: rumContext.sessionId
            type: "user"
        }
        source: agentSource()
        type: "vital"
        usr: m.global.datadogUserInfo
        version: rumContext.applicationVersion
        view: {
            id: viewId
            url: viewUrl
            name: viewName
        }
        vital: {
            id: event.vitalId
            name: event.name
            type: "operation_step"
            operation_key: event.operationKey
            step_type: stepType
            failure_reason: event.failureReason
        }
    }
    ddLogInfo("Tracking vital operation '" + event.name + "' (" + stepType + ")")
    writer.writeEvent = FormatJson(vitalEvent)
end sub

' ----------------------------------------------------------------
' Returns the lookup key for an operation based on its name and operationKey
' @param name (string) the operation name
' @param operationKey (dynamic) the operation key, or invalid for unkeyed operations
' @return (string) the lookup key for tracking active operations
' ----------------------------------------------------------------
function __operationLookupKey(name as string, operationKey as dynamic) as string
    if (operationKey <> invalid)
        return name + operationKey
    end if
    return name
end function

' ----------------------------------------------------------------
' Ensures the active operations map is initialized (lazy initialization)
' ----------------------------------------------------------------
sub __ensureActiveOperations()
    if (m.activeOperations = invalid)
        m.activeOperations = {}
    end if
end sub

' ----------------------------------------------------------------
' Tracks the start of an operation, logging a warning if already active
' @param name (string) the operation name
' @param operationKey (dynamic) the operation key, or invalid for unkeyed operations
' @param lookupKey (string) the lookup key from __operationLookupKey()
' ----------------------------------------------------------------
sub __trackOperationStart(name as string, operationKey as dynamic, lookupKey as string)
    __ensureActiveOperations()
    if (m.activeOperations.DoesExist(lookupKey))
        ddLogWarning("Operation " + __formatOperationName(name, operationKey) + " has already been started. The previous instance may be terminated by the backend.")
    end if
    m.activeOperations[lookupKey] = true
end sub

' ----------------------------------------------------------------
' Tracks the end of an operation, logging a warning if not currently active
' @param name (string) the operation name
' @param operationKey (dynamic) the operation key, or invalid for unkeyed operations
' @param lookupKey (string) the lookup key from __operationLookupKey()
' ----------------------------------------------------------------
sub __trackOperationEnd(name as string, operationKey as dynamic, lookupKey as string)
    __ensureActiveOperations()
    if (not m.activeOperations.DoesExist(lookupKey))
        ddLogWarning("Stop was called, but operation " + __formatOperationName(name, operationKey) + " is currently not active. Make sure to call startOperation first.")
    end if
    m.activeOperations.Delete(lookupKey)
end sub

' ----------------------------------------------------------------
' Formats an operation name and key for use in developer warning messages
' @param name (string) the operation name
' @param operationKey (dynamic) the operation key, or invalid for unkeyed operations
' @return (string) formatted operation identifier for warning messages
' ----------------------------------------------------------------
function __formatOperationName(name as string, operationKey as dynamic) as string
    if (operationKey <> invalid)
        return "'" + name + "' (key '" + operationKey + "')"
    end if
    return "'" + name + "'"
end function