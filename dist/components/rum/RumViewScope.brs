' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
'import "pkg:/source/rum/rumHelper.bs"
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
        logVerbose("Delegate to child")
        m.top.activeAction.callfunc("handleEvent", event, writer)
        if (not m.top.activeAction.callfunc("isActive", invalid))
            logVerbose("No child anymore")
            m.top.activeAction = invalid
        else
            logVerbose("Child still active")
        end if
    end if
    if (event.eventType = "stopView")
        stopView(event.viewName, event.viewUrl, writer)
    else if (event.eventType = "startView")
        stopView(m.top.viewName, m.top.viewUrl, writer)
    else if (event.eventType = "addError")
        addError(event.exception, writer)
    else if (event.eventType = "addResource")
        addResource(event.resource, writer)
    else if (event.eventType = "addAction")
        addAction(event.action, writer)
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
sub stopView(name as string, url as string, writer as object)
    logVerbose("RUM stopping view " + name + " (" + url + ")")
    if (m.top.viewUrl <> url)
        logWarning("Trying to stop unknown view '" + name + "' (" + url + "), ignoring.")
        return
    end if
    if (m.stopped)
        logWarning("Trying to stop view '" + name + "' (" + url + ") but it's already stopped.")
        return
    end if
    m.stopped = true
    sendViewUpdate(writer)
end sub

' ----------------------------------------------------------------
' Handles an error event
' @param exception (object) the exception
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addError(exception as object, writer as object)
    if (exception.number = invalid)
        errorType = "unknown"
    else
        errorType = "&h" + decToHex(exception.number)
    end if
    errorMsg = "Unknown exception"
    if (exception.message <> invalid)
        errorMsg = exception.message
    end if
    sendError(errorMsg, errorType, exception.backtrace, writer)
end sub

' ----------------------------------------------------------------
' Sends an error event
' @param message (string) the error message
' @param errorType (string) the error type
' @param backtrace (dynamic) the error backtrace array, or invalid
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendError(message as string, errorType as string, backtrace as dynamic, writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending an error")
    context = getRumContext(invalid)
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
            id: context.applicationId
        }
        date: timestamp&
        error: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            is_crash: false
            message: message
            source: "source"
            source_type: agentSource()
            stack: backtraceToString(backtrace)
            type: errorType
        }
        service: context.serviceName
        session: {
            has_replay: false
            id: context.sessionId
            type: "user"
        }
        source: agentSource()
        type: "error"
        version: context.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
    m.errorCount++
    writer.writeEvent = FormatJson(errorEvent)
end sub

' ----------------------------------------------------------------
' Handles a resource event
' @param resource (object) resource object
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addResource(resource as object, writer as object)
    if (isValidResource(resource))
        sendResource(resource.url, resource.transferTime, resource.method, resource.httpCode, resource.bytesDownloaded, writer)
    else
        sendResourceError(resource.status, resource.url, resource.method, writer)
    end if
end sub

' ----------------------------------------------------------------
' Handles an action event
' @param action (object) action object
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addAction(action as object, writer as object)
    ' TODO RUMM-2586 handle mutliple consecutive actions
    m.top.activeAction = CreateObject("roSGNode", "RumActionScope")
    m.top.activeAction.target = action.target
    m.top.activeAction.actionType = action.type
    m.top.activeAction.parentScope = m.top
    m.actionCount++
end sub

' ----------------------------------------------------------------
' Sends a resource event
' @param url (string) the resource url
' @param transferTime (double) the duration of the transfer (in seconds)
' @param method (dynamic) the method as string ("POST", "GET", …) or invalid
' @param httpCode (dynamic) the HTTP status code as integer (200, 404, …) or invalid
' @param bytesDownloaded (dynamic) the size of the downloaded payload (in bytes as integer) or invalid
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendResource(url as string, transferTime as double, method as dynamic, httpCode as dynamic, bytesDownloaded as dynamic, writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending a resource")
    context = getRumContext(invalid)
    actionId = invalid
    if (m.top.activeAction <> invalid)
        actionId = m.top.activeAction.callfunc("getRumContext", invalid).actionId
    end if
    startTimestampMs& = timestamp& - secToMillis(transferTime)
    resourceEvent = {
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
            id: context.applicationId
        }
        date: startTimestampMs&
        resource: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            type: "native"
            url: url
            method: method
            status_code: httpCode
            size: bytesDownloaded
            duration: secToNanos(transferTime)
        }
        service: context.serviceName
        session: {
            has_replay: false
            id: context.sessionId
            type: "user"
        }
        source: agentSource()
        type: "resource"
        version: context.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
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
sub sendResourceError(status as string, url as dynamic, method as dynamic, writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending a resource error")
    context = getRumContext(invalid)
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
            id: context.applicationId
        }
        date: timestamp&
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
        service: context.serviceName
        session: {
            has_replay: false
            id: context.sessionId
            type: "user"
        }
        source: agentSource()
        type: "error"
        version: context.applicationVersion
        view: {
            id: m.viewId
            url: m.top.viewUrl
            name: m.top.viewName
        }
    }
    writer.writeEvent = FormatJson(errorEvent)
end sub

' ----------------------------------------------------------------
' Send a view event
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendViewUpdate(writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending view update")
    context = getRumContext(invalid)
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
            id: context.applicationId
        }
        date: m.startTimestamp&
        service: context.serviceName
        session: {
            has_replay: false
            id: context.sessionId
            type: "user"
        }
        source: agentSource()
        type: "view"
        version: context.applicationVersion
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
    writer.writeEvent = FormatJson(viewEvent)
end sub