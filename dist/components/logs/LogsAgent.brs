' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/logs/logStatus.bs"
' *****************************************************************
' * RumAgent: a background component listening for internal events
' *     to write relevant RUM Event to Datadog.
' *****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("LogsAgent.init()")
    m.applicationVersion = CreateObject("roAppInfo").GetVersion()
end sub

' ----------------------------------------------------------------
' Adds a ok log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logOk(message as string, attributes as object)
    ddLogThread("LogsAgent.logOk()")
    sendLog("ok", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a debug log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logDebug(message as string, attributes as object)
    ddLogThread("LogsAgent.logDebug()")
    sendLog("debug", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a info log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logInfo(message as string, attributes as object)
    ddLogThread("LogsAgent.logInfo()")
    sendLog("info", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a notice log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logNotice(message as string, attributes as object)
    ddLogThread("LogsAgent.logNotice()")
    sendLog("notice", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a warn log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logWarn(message as string, attributes as object)
    ddLogThread("LogsAgent.logWarn()")
    sendLog("warn", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a error log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logError(message as string, attributes as object)
    ddLogThread("LogsAgent.logError()")
    sendLog("error", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a critical log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logCritical(message as string, attributes as object)
    ddLogThread("LogsAgent.logCritical()")
    sendLog("critical", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a alert log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logAlert(message as string, attributes as object)
    ddLogThread("LogsAgent.logAlert()")
    sendLog("alert", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a emergency log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logEmergency(message as string, attributes as object)
    ddLogThread("LogsAgent.logEmergency()")
    sendLog("emergency", message, attributes)
end sub

' ----------------------------------------------------------------
' Sends a log event
' @param status (LogStatus) the status of the log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub sendLog(status as object, message as string, attributes as object)
    timestamp& = getTimestamp()
    ensureSetup()
    logEvent = {
        date: timestamp&
        ddtags: "env:" + m.top.envName + ",version:" + m.applicationVersion
        message: message
        status: status
        service: m.top.serviceName
        usr: m.global.datadogUserInfo
    }
    for each key in attributes
        logEvent[key] = attributes[key]
    end for
    if (m.global.datadogContext <> invalid)
        for each key in m.global.datadogContext
            logEvent[key] = m.global.datadogContext[key]
        end for
    end if
    if (m.global.datadogRumContext <> invalid)
        logEvent["application_id"] = m.global.datadogRumContext.applicationId
        logEvent["session_id"] = m.global.datadogRumContext.sessionId
        logEvent["view"] = {
            id: m.global.datadogRumContext.viewId
        }
        logEvent["user_action"] = {
            id: m.global.datadogRumContext.actionId
        }
    end if
    m.writer.writeEvent = FormatJson(logEvent)
end sub

' ----------------------------------------------------------------
' Ensure all dependencies are present (from DI or generated)
' ----------------------------------------------------------------
sub ensureSetup()
    ensureUploader()
    ensureWriter()
end sub

' ----------------------------------------------------------------
' Sets the uploader node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureUploader()
    if (m.uploader = invalid)
        if (m.top.uploader <> invalid)
            m.uploader = m.top.uploader
        else
            m.uploader = CreateObject("roSGNode", "UploaderTask")
        end if
        ' Configure uploader
        m.uploader.endpointHost = m.top.endpointHost
        m.uploader.trackType = "logs"
        m.uploader.payloadPrefix = "["
        m.uploader.payloadPostfix = "]"
        m.uploader.clientToken = m.top.clientToken
        m.uploader.contentType = "application/json"
        m.uploader.queryParams = {
            ddsource: agentSource()
        }
    end if
end sub

' ----------------------------------------------------------------
' Sets the writer node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureWriter()
    if (m.writer = invalid)
        if (m.top.writer <> invalid)
            m.writer = m.top.writer
        else
            m.writer = CreateObject("roSGNode", "WriterTask")
        end if
        ' Configure writer
        m.writer.trackType = "logs"
        m.writer.payloadSeparator = ","
    end if
end sub