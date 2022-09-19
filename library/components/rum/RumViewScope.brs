' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

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
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext() as object
    if (m.top.parentScope <> invalid)
        rumContext = m.top.parentScope.callFunc("getRumContext")
    else
        rumContext = {}
    end if
    rumContext.viewId = m.viewId
    return rumContext
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    if (event.eventType = "stopView")
        stopView(event.viewName, event.viewUrl, writer)
    else if (event.eventType = "startView")
        stopView(m.top.viewName, m.top.viewUrl, writer)
    else if (event.eventType = "addError")
        addError(event.exception, writer)
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
' Handles a stopView event
' @param name (string) the name of the stopped view
' @param url (string) the url of the stopped view
' @param writer (object) the writer node (see WriterTask.brs)
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
' Send an error event
' @param exception (object) the exception
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub addError(exception as object, writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending an error")

    context = getRumContext()

    if (exception.number = invalid)
        errorType = "unknown"
    else
        errorType = "&h" + decToHex(exception.number)
    end if
    if (exception.message = invalid)
        errorMsg = "Unknown exception"
    else
        errorMsg = exception.message
    end if

    errorEvent = {
        _dd: {
            format_version: 2,
            session: { plan: 1 }
        },
        application: {
            id: context.applicationId
        },
        date: timestamp&,
        error: {
            id: CreateObject("roDeviceInfo").GetRandomUUID(),
            is_crash: false,
            message: errorMsg,
            source: "source",
            source_type: agentSource(),
            stack: backtraceToString(exception.backtrace),
            type: errorType
        },
        service: context.serviceName,
        session: {
            has_replay: false,
            id: context.sessionId,
            type: "user"
        },
        source: agentSource(),
        type: "error",
        version: context.applicationVersion,
        view: {
            id: m.viewId,
            url: m.top.viewUrl,
            name: m.top.viewName
        }
    }

    writer.writeEvent = FormatJson(errorEvent)
end sub

' ----------------------------------------------------------------
' Send a view event
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub sendViewUpdate(writer as object)
    timestamp& = getTimestamp()
    logVerbose("Sending view update")

    context = getRumContext()

    m.documentVersionUpdate++
    timeSpentNs& = (timestamp& - m.startTimestamp&) * 1000000 ' convert ms to ns

    viewEvent = {
        _dd: {
            format_version: 2,
            session: { plan: 1 },
            document_version: m.documentVersionUpdate
        },
        application: {
            id: context.applicationId
        },
        date: m.startTimestamp&,
        service: context.serviceName,
        session: {
            has_replay: false,
            id: context.sessionId,
            type: "user"
        },
        source: agentSource(),
        type: "view",
        version: context.applicationVersion,
        view: {
            id: m.viewId,
            url: m.top.viewUrl,
            name: m.top.viewName,
            time_spent: timeSpentNs&,
            action: { count: 0 }, ' TODO RUMM-2435
            error: { count: 0 }, ' TODO RUMM-2435
            resource: { count: 0 }' TODO RUMM-2435
        }
    }

    writer.writeEvent = FormatJson(viewEvent)
end sub
