' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
' ****************************************************************
' * RumActionScope: handles an Action's scope
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.startTimestamp& = getTimestamp()
    m.actionId = CreateObject("roDeviceInfo").GetRandomUUID()
    m.stopped = false
    m.lastEventTimestamp& = m.startTimestamp&
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
    rumContext.actionId = m.actionId
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    timestamp& = getTimestamp()
    parentStopping = false
    if (event.eventType = "addError")
        ' TODO RUMM-2435 track linked error
        m.lastEventTimestamp& = getTimestamp()
    else if (event.eventType = "addResource")
        ' TODO RUMM-2435 track linked resource
        m.lastEventTimestamp& = getTimestamp()
    else if (event.eventType = "startView" or event.eventType = "stopView")
        parentStopping = true
    end if
    timeout = timestamp& > (m.lastEventTimestamp& + 100)
    if (timeout or parentStopping)
        sendAction(writer)
        m.stopped = true
    end if
end sub

' ----------------------------------------------------------------
' Returns information about whether the current scope can handle more events or not
' @param _ph (dynamic) no-op argument to avoid random crash on older Roku devices
' @return (boolean) `true` if this scope expects more event, `false` if it's complete
' ----------------------------------------------------------------
function isActive(_ph as dynamic) as boolean
    return not m.stopped
end function

' ----------------------------------------------------------------
' Sends an action event
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendAction(writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending an action")
    duration& = millisToNanos(m.lastEventTimestamp& - m.startTimestamp&)
    context = getRumContext(invalid)
    actionEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        action: {
            id: m.actionId
            loading_time: duration&
            target: {
                name: m.top.target
            }
            type: m.top.actionType
        }
        application: {
            id: context.applicationId
        }
        date: timestamp&
        service: context.serviceName
        session: {
            has_replay: false
            id: context.sessionId
            type: "user"
        }
        source: agentSource()
        type: "action"
        version: context.applicationVersion
        view: {
            id: context.viewId
            url: context.viewUrl
            name: context.viewName
        }
    }
    writer.writeEvent = FormatJson(actionEvent)
end sub
' ****************************************************************
' * RumActionType: list of allowed action types
' ****************************************************************
