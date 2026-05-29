' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
'import "pkg:/source/logs/logStatus.bs"
' *****************************************************************
' * LogsAgent: a component exposing logging APIs that write
' *     Log Events to Datadog.
' *****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("LogsAgent.init()")
end sub

' ----------------------------------------------------------------
' Adds a ok log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logOk(message as string, attributes as object)
    ddLogThread("LogsAgent.logOk()")
    ddLogVerbose("[ OK ] " + message)
    sendLog("ok", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a debug log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logDebug(message as string, attributes as object)
    ddLogThread("LogsAgent.logDebug()")
    ddLogVerbose("[ DEBUG ] " + message)
    sendLog("debug", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a info log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logInfo(message as string, attributes as object)
    ddLogThread("LogsAgent.logInfo()")
    ddLogInfo("[ INFO ] " + message)
    sendLog("info", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a notice log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logNotice(message as string, attributes as object)
    ddLogThread("LogsAgent.logNotice()")
    ddLogInfo("[ NOTICE ] " + message)
    sendLog("notice", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a warn log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logWarn(message as string, attributes as object)
    ddLogThread("LogsAgent.logWarn()")
    ddLogWarning("[ WARN ] " + message)
    sendLog("warn", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a error log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logError(message as string, attributes as object)
    ddLogThread("LogsAgent.logError()")
    ddLogError("[ ERROR ] " + message)
    sendLog("error", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a critical log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logCritical(message as string, attributes as object)
    ddLogThread("LogsAgent.logCritical()")
    ddLogError("[ CRITICAL ] " + message)
    sendLog("critical", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a alert log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logAlert(message as string, attributes as object)
    ddLogThread("LogsAgent.logAlert()")
    ddLogError("[ ALERT ] " + message)
    sendLog("alert", message, attributes)
end sub

' ----------------------------------------------------------------
' Adds a emergency log
' @param message (string) the log message
' @param attributes (object) additional custom attributes
' ----------------------------------------------------------------
sub logEmergency(message as string, attributes as object)
    ddLogThread("LogsAgent.logEmergency()")
    ddLogError("[ EMERGENCY ] " + message)
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
    setupIfNeeded()
    logEvent = {
        date: timestamp&
        ddtags: "env:" + m.env + ",version:" + m.version
        message: message
        status: status
        service: m.service
        usr: m.userInfo
        device: {
            type: "tv"
            name: m.deviceName
            model: m.deviceModel
            brand: "Roku"
        }
        os: {
            name: "Roku"
            version: m.osVersion
            version_major: m.osVersionMajor
        }
        logger: {
            thread_name: m.top.threadInfo().currentThread.name
            version: sdkVersion()
        }
    }
    for each key in attributes
        logEvent[key] = attributes[key]
    end for
    if (m.ddContext <> invalid)
        for each key in m.ddContext
            logEvent[key] = m.ddContext[key]
        end for
    end if
    rumContext = m.rumContext
    if (rumContext <> invalid)
        logEvent["application_id"] = rumContext.applicationId
        logEvent["session_id"] = rumContext.sessionId
        logEvent["view"] = {
            id: rumContext.viewId
        }
        logEvent["user_action"] = {
            id: rumContext.actionId
        }
    end if
    m.writer.writeEvent = FormatJson(logEvent)
end sub

sub setupIfNeeded()
    if (m.isConfigured = true)
        return
    end if
    ' 1. Cache injected dependencies
    fields = m.top.getFields()
    m.uploader = fields.uploader
    m.writer = fields.writer 'allow tests to inject a mock
    m.service = fields.service
    m.version = fields.version
    m.env = fields.env
    m.deviceName = fields.deviceName
    m.deviceModel = fields.deviceModel
    m.osVersion = fields.osVersion
    m.osVersionMajor = fields.osVersionMajor
    m.site = fields.site
    ' 2. Configure writer
    if (m.writer = invalid) 'skipped in tests (mock pre-injected)
        ddLogVerbose("Creating WriterTask")
        m.writer = CreateObject("roSGNode", "WriterTask")
        m.top.writer = m.writer
    end if
    m.writer.setFields({
        trackType: "logs"
        payloadSeparator: ","
    })
    ' 3. Register our track on the shared uploader
    trackId = "logs_" + m.top.threadInfo().node.address
    tracks = (function(m)
            __bsConsequent = m.uploader.tracks
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(m)
    tracks[trackId] = {
        url: getIntakeUrl(m.site, "logs")
        trackType: "logs"
        payloadPrefix: "["
        payloadPostfix: "]"
        contentType: "application/json"
        queryParams: {
            ddsource: agentSource()
        }
    }
    m.uploader.setFields({
        tracks: tracks
    })
    ' 4. Cache the global context locally, kept in sync via observers
    m.global.observeFieldScoped("datadogUserInfo", "onUserInfoChanged")
    m.global.observeFieldScoped("datadogContext", "onContextChanged")
    m.global.observeFieldScoped("datadogRumContext", "onRumContextChanged")
    m.userInfo = m.global.datadogUserInfo
    m.ddContext = m.global.datadogContext
    m.rumContext = m.global.datadogRumContext
    m.isConfigured = true
end sub

sub onUserInfoChanged(event as object)
    m.userInfo = event.getData()
end sub

sub onContextChanged(event as object)
    m.ddContext = event.getData()
end sub

sub onRumContextChanged(event as object)
    m.rumContext = event.getData()
end sub