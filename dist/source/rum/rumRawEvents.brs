' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'*****************************************************************
'* Utilities to generate internal RUM events
'*****************************************************************

' ----------------------------------------------------------------
' @param viewName (string) the view name (human-readable)
' @param viewUrl (string) the view url (developer identifier)
' @param context (object) an assocarray of custom attributes to add to the view
' @return (object) an event describing a startView action
' ----------------------------------------------------------------
function startViewEvent(viewName as string, viewUrl as string, context as object) as object
    return {
        eventType: "startView"
        viewName: viewName
        viewUrl: viewUrl
        context: context
    }
end function

' ----------------------------------------------------------------
' @param viewName (string) the view name (human-readable)
' @param viewUrl (string) the view url (developer identifier)
' @param context (object) an assocarray of custom attributes to add to the view
' @return (object) an event describing a stopView action
' ----------------------------------------------------------------
function stopViewEvent(viewName as string, viewUrl as string, context as object) as object
    return {
        eventType: "stopView"
        viewName: viewName
        viewUrl: viewUrl
        context: context
    }
end function

' ----------------------------------------------------------------
' @param action (object) the action to track
' @param context (object) an assocarray of custom attributes to add to the view
' @return (object) an event describing an addAction action
' ----------------------------------------------------------------
function addActionEvent(action as object, context as object) as object
    return {
        eventType: "addAction"
        action: action
        context: context
    }
end function

' ----------------------------------------------------------------
' @param exception (object) the caught exception
' @param context (object) an assocarray of custom attributes to add to the view
' @return (object) an event describing an addError action
' ----------------------------------------------------------------
function addErrorEvent(exception as object, context as object) as object
    return {
        eventType: "addError"
        exception: exception
        context: context
    }
end function

' ----------------------------------------------------------------
' @param resource (object) the resource object
' @param context (object) an assocarray of custom attributes to add to the view
' @return (object) an event describing an addResource action
' ----------------------------------------------------------------
function addResourceEvent(resource as object, context as object) as object
    return {
        eventType: "addResource"
        resource: resource
        context: context
    }
end function

' ----------------------------------------------------------------
' @return (object) a keep alive
' ----------------------------------------------------------------
function keepAliveEvent() as object
    return {
        eventType: "keepAlive"
    }
end function

' ----------------------------------------------------------------
' @param configuration (object) the configuration object
' @return (object) an event describing an addTelemetryConfigEvent action
' ----------------------------------------------------------------
function addTelemetryConfigEvent(configuration as object) as object
    return {
        eventType: "telemetryConfig"
        configuration: configuration
    }
end function

' ----------------------------------------------------------------
' @param exception (object) the exception object
' @return (object) an event describing an addTelemetryErrorEvent action
' ----------------------------------------------------------------
function addTelemetryErrorEvent(exception as object) as object
    return {
        eventType: "telemetryError"
        exception: exception
    }
end function

' ----------------------------------------------------------------
' @param message (string) the message
' @return (object) an event describing an addTelemetryDebugEvent action
' ----------------------------------------------------------------
function addTelemetryDebugEvent(message as string) as object
    return {
        eventType: "telemetryDebug"
        message: message
    }
end function
' ----------------------------------------------------------------
' RawEvent: enum listing all the possible events handled by RUM scopes
' ----------------------------------------------------------------
