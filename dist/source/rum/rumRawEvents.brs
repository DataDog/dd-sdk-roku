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
' @return (object) timestamp in milliseconds since EPOCH
' ----------------------------------------------------------------
function getOperationTimestamp() as longinteger
    date = CreateObject("roDateTime")
    seconds& = date.AsSeconds() ' number of seconds since EPOCH
    millis& = date.GetMilliseconds() ' number of millisecond in current second [0-999]
    timestamp& = (seconds& * 1000) + millis&
    return timestamp&
end function

' ----------------------------------------------------------------
' @param name (string) the operation name (e.g.: "Login", "Checkout")
' @param operationKey (dynamic) the operation key for distinguishing parallel operations, or invalid for unkeyed
' @param context (object) an assocarray of custom attributes to add to the event
' @return (object) an event describing a startFeatureOperation action
' ----------------------------------------------------------------
function startFeatureOperationEvent(name as string, operationKey as dynamic, context as object) as object
    ' Set the timestamp as soon as you notify the operation event. This will result in more accurate timing.
    return {
        eventType: "startFeatureOperation"
        name: name
        timestamp: getOperationTimestamp()
        operationKey: operationKey
        vitalId: CreateObject("roDeviceInfo").GetRandomUUID()
        context: context
    }
end function

' ----------------------------------------------------------------
' @param name (string) the operation name (e.g.: "Login", "Checkout")
' @param operationKey (dynamic) the operation key for distinguishing parallel operations, or invalid for unkeyed
' @param context (object) an assocarray of custom attributes to add to the event
' @return (object) an event describing a succeedFeatureOperation action
' ----------------------------------------------------------------
function succeedFeatureOperationEvent(name as string, operationKey as dynamic, context as object) as object
    ' Set the timestamp as soon as you notify the operation event. This will result in more accurate timing.
    return {
        eventType: "stopFeatureOperation"
        name: name
        timestamp: getOperationTimestamp()
        operationKey: operationKey
        vitalId: CreateObject("roDeviceInfo").GetRandomUUID()
        context: context
    }
end function

' ----------------------------------------------------------------
' @param name (string) the operation name (e.g.: "Login", "Checkout")
' @param operationKey (dynamic) the operation key for distinguishing parallel operations, or invalid for unkeyed
' @param failureReason (string) the failure reason (use FailureReason enum values: "error", "abandoned", "other")
' @param context (object) an assocarray of custom attributes to add to the event
' @return (object) an event describing a failFeatureOperation action
' ----------------------------------------------------------------
function failFeatureOperationEvent(name as string, operationKey as dynamic, failureReason as string, context as object) as object
    ' Set the timestamp as soon as you notify the operation event. This will result in more accurate timing.
    return {
        eventType: "stopFeatureOperation"
        name: name
        timestamp: getOperationTimestamp()
        operationKey: operationKey
        failureReason: failureReason
        vitalId: CreateObject("roDeviceInfo").GetRandomUUID()
        context: context
    }
end function
' ----------------------------------------------------------------
' RawEvent: enum listing all the possible events handled by RUM scopes
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' VitalStepType: enum listing the step types for vital operation events
' Values match the schema-defined string equivalents from vital-operation-step-schema.json
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' FailureReason: enum listing the failure reasons for vital operation events
' Values match the schema-defined string equivalents from vital-operation-step-schema.json
' ----------------------------------------------------------------
