' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
'import "pkg:/source/rum/rumHelper.bs"
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
    m.errorCount = 0
    m.resourceCount = 0
    datadogRumContext = m.global.datadogRumContext
    datadogRumContext.actionId = m.actionId
    m.global.setField("datadogRumContext", datadogRumContext)
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
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    timestamp& = getTimestamp()
    threshold& = m.lastEventTimestamp& + 100
    parentStopping = false
    if (event.eventType = "addError")
        if (timestamp& <= (threshold&))
            m.errorCount++
            m.lastEventTimestamp& = timestamp&
            return
        end if
    else if (event.eventType = "addResource")
        if (isValidResource(event.resource))
            transferTime& = secToMillis(event.resource.transferTime)
            resourceStartTimestamp& = timestamp& - transferTime&
            if (resourceStartTimestamp& <= (threshold&))
                m.resourceCount++
                m.lastEventTimestamp& = timestamp&
                return
            end if
        else if (timestamp& <= (threshold&))
            m.errorCount++
            m.lastEventTimestamp& = timestamp&
            return
        end if
    else if (event.eventType = "startView" or event.eventType = "stopView")
        parentStopping = true
    end if
    timeout = timestamp& > (threshold&)
    if (timeout or parentStopping)
        sendAction(writer)
        m.stopped = true
        datadogRumContext = m.global.datadogRumContext
        datadogRumContext.actionId = invalid
        m.global.setField("datadogRumContext", datadogRumContext)
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
    ddLogVerbose("Sending an action")
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
            error: {
                count: m.errorCount
            }
            loading_time: duration&
            resource: {
                count: m.resourceCount
            }
            target: {
                name: m.top.target
            }
            type: m.top.actionType
        }
        application: {
            id: context.applicationId
        }
        context: m.global.datadogContext
        date: m.startTimestamp&
        device: {
            type: "tv"
            name: context.deviceName
            model: context.deviceModel
            brand: "Roku"
        }
        os: {
            name: "Roku"
            version: context.osVersion
            version_major: context.osVersionMajor
        }
        service: context.service
        session: {
            has_replay: false
            id: context.sessionId
            type: "user"
        }
        source: agentSource()
        type: "action"
        usr: m.global.datadogUserInfo
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
