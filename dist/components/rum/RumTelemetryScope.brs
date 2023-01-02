' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/rum/rumRawEvents.bs"
'import "pkg:/source/rum/rumHelper.bs"
' ****************************************************************
' * RumTelemetryScope: handles the internal Telemetry events
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
end sub

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    ddLogThread("RumTelemetryScope.handleEvent()")
    if (event.eventType = "telemetryConfig")
        sendConfigEvent(event, writer)
    else if (event.eventType = "telemetryDebug")
        sendDebugEvent(event, writer)
    else if (event.eventType = "telemetryError")
        sendErrorEvent(event, writer)
    end if
end sub

' ----------------------------------------------------------------
' Sends a configuration event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendConfigEvent(event as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending a config telemetry")
    rumContext = (function(m)
            __bsConsequent = m.global.datadogRumContext
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(m)
    configEvent = {
        _dd: {
            format_version: 2
        }
        action: {
            id: rumContext.actionId
        }
        application: {
            id: rumContext.applicationId
        }
        date: timestamp&
        experimental_features: {}
        service: sdkServiceName()
        session: {
            id: rumContext.sessionId
        }
        source: agentSource()
        telemetry: {
            type: "configuration"
            configuration: {
                session_sample_rate: event.configuration.sessionSampleRate
            }
        }
        type: "telemetry"
        version: sdkVersion()
        view: {
            id: rumContext.viewId
        }
    }
    writer.writeEvent = FormatJson(configEvent)
end sub

' ----------------------------------------------------------------
' Sends a debug log event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendDebugEvent(event as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending a debug log telemetry")
    rumContext = (function(m)
            __bsConsequent = m.global.datadogRumContext
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(m)
    configEvent = {
        _dd: {
            format_version: 2
        }
        action: {
            id: rumContext.actionId
        }
        application: {
            id: rumContext.applicationId
        }
        date: timestamp&
        service: sdkServiceName()
        session: {
            id: rumContext.sessionId
        }
        source: agentSource()
        telemetry: {
            type: "log"
            status: "debug"
            message: event.message
        }
        type: "telemetry"
        version: sdkVersion()
        view: {
            id: rumContext.viewId
        }
    }
    writer.writeEvent = FormatJson(configEvent)
end sub

' ----------------------------------------------------------------
' Sends an error log event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask component)
' ----------------------------------------------------------------
sub sendErrorEvent(event as object, writer as object)
    timestamp& = getTimestamp()
    ddLogVerbose("Sending an error log telemetry")
    exception = event.exception
    if (exception = invalid or exception.number = invalid or exception.message = invalid)
        return
    end if
    errorType = "&h" + decToHex(exception.number)
    errorMsg = exception.message
    rumContext = (function(m)
            __bsConsequent = m.global.datadogRumContext
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(m)
    configEvent = {
        _dd: {
            format_version: 2
        }
        action: {
            id: rumContext.actionId
        }
        application: {
            id: rumContext.applicationId
        }
        date: timestamp&
        service: sdkServiceName()
        session: {
            id: rumContext.sessionId
        }
        source: agentSource()
        telemetry: {
            type: "log"
            status: "error"
            message: errorMsg
            error: {
                stack: backtraceToString(exception.backtrace)
                kind: errorType
            }
        }
        type: "telemetry"
        version: sdkVersion()
        view: {
            id: rumContext.viewId
        }
    }
    writer.writeEvent = FormatJson(configEvent)
end sub