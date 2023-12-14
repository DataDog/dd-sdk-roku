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
' * RumViewScope: handles the View level
' *  - send view updates when required
' *  - TODO handle children scopes
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.viewId = CreateObject("roDeviceInfo").GetRandomUUID()
    m.startTimestamp& = getTimestamp()
    m.stopped = false
    m.documentVersionUpdate = 0
    m.actionCount = 0
    m.errorCount = 0
    m.resourceCount = 0
    datadogRumContext = m.global.datadogRumContext
    datadogRumContext.viewId = m.viewId
    m.instanceId = (function(datadogRumContext)
            __bsConsequent = datadogRumContext.instanceId
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return ""
            end if
        end function)(datadogRumContext)
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
    rumContext.viewId = m.viewId
    rumContext.viewName = m.top.viewName
    rumContext.viewUrl = m.top.viewUrl
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    if (m.top.activeAction <> invalid)
        ddLogVerbose("Delegate to child")
        m.top.activeAction.callfunc("handleEvent", event, writer)
        if (not m.top.activeAction.callfunc("isActive", invalid))
            ddLogVerbose("No child anymore")
            m.top.activeAction = invalid
        else
            ddLogVerbose("Child still active")
        end if
    end if
    context = (function(event)
            __bsConsequent = event.context
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(event)
    if (event.eventType = "stopView")
        stopView(event.viewName, event.viewUrl, context, writer)
    else if (event.eventType = "startView")
        stopView(m.top.viewName, m.top.viewUrl, {}, writer)
    else if (event.eventType = "addError")
        addError(event.exception, context, writer)
    else if (event.eventType = "addResource")
        addResource(event.resource, context, writer)
    else if (event.eventType = "addAction")
        addAction(event.action, context, writer)
    else if (event.eventType = "keepAlive")
        sendViewUpdate(context, writer)
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
' Handles a stopView event
' @param name (string) the name of the stopped view
' @param url (string) the url of the stopped view
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub stopView(name as string, url as string, context as object, writer as object)
    ddLogVerbose("RUM stopping view " + name + " (" + url + ")")
    if (m.top.viewUrl <> url)
        ddLogWarning("Trying to stop unknown view '" + name + "' (" + url + "), ignoring.")
        return
    end if
    if (m.stopped)
        ddLogWarning("Trying to stop view '" + name + "' (" + url + ") but it's already stopped.")
        return
    end if
    m.stopped = true
    sendViewUpdate(context, writer)
end sub

' ----------------------------------------------------------------
' Handles an error event
' @param exception (object) the exception
' @param context (object) the local context
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addError(exception as object, context as object, writer as object)
    if (exception.number = invalid)
        errorType = "unknown"
    else
        errorType = "&h" + decToHex(exception.number)
    end if
    if (exception.message <> invalid)
        errorMsg = exception.message
    else
        errorMsg = "Unknown exception"
    end if
    sendError(errorMsg, errorType, exception.backtrace, context, writer)
end sub

' ----------------------------------------------------------------
' Sends an error event
' @param message (string) the error message
' @param errorType (string) the error type
' @param backtrace (dynamic) the error backtrace array, or invalid
' @param context (object) the local context
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendError(message as string, errorType as string, backtrace as dynamic, context as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending an error")
    rumContext = getRumContext(invalid)
    actionId = invalid
    if (m.top.activeAction <> invalid)
        actionId = m.top.activeAction.callfunc("getRumContext", invalid).actionId
    end if
    errorEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        action: {
            id: actionId
        }
        application: {
            id: rumContext.applicationId
        }
        context: mergeContext(m.global.datadogContext, context)
        date: timestamp&
        device: {
            type: "tv"
            name: rumContext.deviceName
            model: rumContext.deviceModel
            brand: "Roku"
        }
        error: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            is_crash: false
            message: message
            source: "source"
            source_type: agentSource()
            stack: backtraceToString(backtrace)
            type: errorType
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
        type: "error"
        usr: m.global.datadogUserInfo
        version: rumContext.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
    ddLogInfo("Tracking error '" + message + "' in view " + m.top.viewName + " (" + m.viewId + ")")
    m.errorCount++
    writer.writeEvent = FormatJson(errorEvent)
end sub

' ----------------------------------------------------------------
' Handles a resource event
' @param resource (object) resource object
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addResource(resource as object, context as object, writer as object)
    if (isValidResource(resource))
        sendResource(resource, context, writer)
    else
        sendResourceError(resource.status, resource.url, resource.method, context, writer)
    end if
end sub

' ----------------------------------------------------------------
' Handles an action event
' @param action (object) action object
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addAction(action as object, context as object, writer as object)
    ' TODO RUMM-2586 handle multiple consecutive actions
    if (action.type = "custom")
        sendCustomAction(action.target, context, writer)
    else if (m.top.activeAction = invalid)
        m.top.activeAction = CreateObject("roSGNode", "RumActionScope")
        m.top.activeAction.target = action.target
        m.top.activeAction.actionType = action.type
        m.top.activeAction.parentScope = m.top
        m.top.activeAction.context = context
    end if
    m.actionCount++
end sub

' ----------------------------------------------------------------
' Sends a custom action event
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendCustomAction(target as string, context as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending a custom action")
    actionId = CreateObject("roDeviceInfo").GetRandomUUID()
    rumContext = getRumContext(invalid)
    actionEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        action: {
            id: actionId
            error: {
                count: 0
            }
            loading_time: 0
            resource: {
                count: 0
            }
            target: {
                name: target
            }
            type: "custom"
        }
        application: {
            id: rumContext.applicationId
        }
        context: mergeContext(m.global.datadogContext, context)
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
        type: "action"
        usr: m.global.datadogUserInfo
        version: rumContext.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
    ddLogInfo("Tracking custom action '" + target + "' in view " + m.top.viewName + " (" + m.viewId + ")")
    writer.writeEvent = FormatJson(actionEvent)
end sub

' ----------------------------------------------------------------
' Sends a resource event
' @param resource (object) the resource associative array, with the following entries
'  - url (string) the resource url
'  - transferTime (double) the duration of the transfer (in seconds)
'  - method (dynamic) the method as string ("POST", "GET", …) or invalid
'  - httpCode (dynamic) the HTTP status code as integer (200, 404, …) or invalid
'  - bytesDownloaded (dynamic) the size of the downloaded payload (in bytes as integer) or invalid
'  - traceId (dynamic) the id of the trace forwarded in the request header (as string), or invalid
'  - spanId (dynamic) the id of the span forwarded in the request header (as string), or invalid
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendResource(resource as object, context as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending a resource")
    rumContext = getRumContext(invalid)
    actionId = invalid
    if (m.top.activeAction <> invalid)
        actionId = m.top.activeAction.callfunc("getRumContext", invalid).actionId
    end if
    startTimestampMs& = timestamp& - secToMillis(resource.transferTime)
    resourceEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
            trace_id: resource.traceId
            span_id: resource.spanId
            rule_psr: (function(resource)
                    __bsConsequent = resource.rulePsr
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return 1
                    end if
                end function)(resource)
        }
        action: {
            id: actionId
        }
        application: {
            id: rumContext.applicationId
        }
        context: mergeContext(m.global.datadogContext, context)
        date: startTimestampMs&
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
        resource: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            type: "native"
            url: resource.url
            method: resource.method
            status_code: resource.httpCode
            size: resource.bytesDownloaded
            duration: secToNanos(resource.transferTime)
        }
        service: rumContext.service
        session: {
            has_replay: false
            id: rumContext.sessionId
            type: "user"
        }
        source: agentSource()
        type: "resource"
        usr: m.global.datadogUserInfo
        version: rumContext.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
    method = (function(resource)
            __bsConsequent = resource.method
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return "?"
            end if
        end function)(resource)
    statusCode = (function(resource)
            __bsConsequent = resource.httpCode
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return 0
            end if
        end function)(resource)
    ddLogInfo("Tracking resource " + method + ":" + resource.url + " -> " + statusCode.toStr() + " in view " + m.top.viewName + " (" + m.viewId + ")")
    m.resourceCount++
    writer.writeEvent = FormatJson(resourceEvent)
end sub

' ----------------------------------------------------------------
' Sends an error event corresponding to a failed network request
' @param status (string) the error message
' @param url (string) the resource url
' @param method (dynamic) the method as string ("POST", "GET", …) or invalid
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendResourceError(status as string, url as dynamic, method as dynamic, context as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending a resource error")
    rumContext = getRumContext(invalid)
    actionId = invalid
    if (m.top.activeAction <> invalid)
        actionId = m.top.activeAction.callfunc("getRumContext", invalid).actionId
    end if
    errorEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        action: {
            id: actionId
        }
        application: {
            id: rumContext.applicationId
        }
        context: mergeContext(m.global.datadogContext, context)
        date: timestamp&
        device: {
            type: "tv"
            name: rumContext.deviceName
            model: rumContext.deviceModel
            brand: "Roku"
        }
        error: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            is_crash: false
            message: "Failed to perform request"
            resource: {
                method: method
                type: "native"
                url: url
            }
            source: "network"
            source_type: agentSource()
            stack: invalid
            type: status
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
        type: "error"
        usr: m.global.datadogUserInfo
        version: rumContext.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
    ddLogInfo("Tracking resource error " + method + ":" + url + "' in view " + m.top.viewName + " (" + m.viewId + ")")
    writer.writeEvent = FormatJson(errorEvent)
end sub

' ----------------------------------------------------------------
' Send a view event
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendViewUpdate(context as object, writer as object)
    timestamp& = getTimestamp()
    ddLogThread("Sending view update")
    rumContext = getRumContext(invalid)
    m.documentVersionUpdate++
    timeSpentNs& = (timestamp& - m.startTimestamp&) * 1000000 ' convert ms to ns
    viewEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
            document_version: m.documentVersionUpdate
        }
        application: {
            id: rumContext.applicationId
        }
        context: mergeContext(m.top.context, mergeContext(m.global.datadogContext, context))
        date: m.startTimestamp&
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
        type: "view"
        usr: m.global.datadogUserInfo
        version: rumContext.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
            time_spent: timeSpentNs&
            action: {
                count: m.actionCount
            }
            error: {
                count: m.errorCount
            }
            resource: {
                count: m.resourceCount
            }
        }
    }
    ddLogInfo("Tracking view update for view " + m.top.viewName + " (" + m.viewId + ")")
    jsonEvent = FormatJson(viewEvent)
    writer.writeEvent = jsonEvent
    if (m.instanceId <> invalid and m.instanceId <> "")
        path = lastViewEventFilePath(m.instanceId)
        DeleteFile(path)
        if (rumContext.sessionState = "tracked")
            ddLogVerbose("Keeping track of the last known view into " + path)
            viewEvent._dd.lastEvent = true
            jsonEvent = FormatJson(viewEvent)
            WriteAsciiFile(path, jsonEvent)
        else
            ddLogInfo("Session not tracked, clear last known view")
        end if
    else
        ddLogWarning("Invalid or empty instance id... ignoring for now")
    end if
end sub