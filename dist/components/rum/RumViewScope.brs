' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
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
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    if (event.eventType = "stopView")
        stopView(event.viewName, event.viewUrl, writer)
    else if (event.eventType = "startView")
        stopView(m.top.viewName, m.top.viewUrl, writer)
    else if (event.eventType = "addError")
        addError(event.exception, writer)
    else if (event.eventType = "addResource")
        addResource(event.resource, writer)
    end if
end sub

' ----------------------------------------------------------------
' Returns information about whether the current scope can handle more events or not
' @param _ph (dynamic) no-op argument to avoid random crash on older Roku devices
' @return (boolean) `true` if this scope expects more event, `false` if it's complete
' ----------------------------------------------------------------
function isActive(_ph as dynamic) as boolean
    ' TODO test this behavior
    return true
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
    errorEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        ' TODO RUMM-2435 parent action id
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
    writer.writeEvent = FormatJson(errorEvent)
end sub

' ----------------------------------------------------------------
' Handles a resource event
' @param resource (object) resource object
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub addResource(resource as object, writer as object)
    status = resource.status
    if (status = invalid or status = "")
        status = "ok"
    end if
    url = resource.url
    transferTime = resource.transferTime
    method = resource.method
    if (status = "ok" and url <> invalid and transferTime <> invalid)
        sendResource(url, transferTime, method, resource.httpCode, resource.bytesDownloaded, writer)
    else
        sendResourceError(status, url, method, writer)
    end if
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
    startTimestampMs& = timestamp& - secToMillis(transferTime)
    resourceEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        ' TODO RUMM-2435 parent action id
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
    errorEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        ' TODO RUMM-2435 parent action id
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
                count: 0
            } ' TODO RUMM-2435
            error: {
                count: 0
            } ' TODO RUMM-2435
            resource: {
                count: 0
            } ' TODO RUMM-2435
        }
    }
    writer.writeEvent = FormatJson(viewEvent)
end sub