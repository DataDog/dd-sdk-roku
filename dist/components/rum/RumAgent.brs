' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/rum/rumRawEvents.bs"
'import "pkg:/source/rum/rumHelper.bs"
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
' *****************************************************************
' * RumAgent: a background component listening for internal events
' *     to write relevant RUM Event to Datadog.
' *****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("RumAgent.init()")
    m.port = createObject("roMessagePort")
    m.top.functionName = "rumAgentLoop"
    m.top.control = "RUN"
end sub

' ----------------------------------------------------------------
' Main RumAgent loop
' ----------------------------------------------------------------
sub rumAgentLoop()
    ddLogThread("RumAgent.rumAgentLoop()")
    ensureSetup()
    sendCrash(m.top.lastExitOrTerminationReason)
    addConfigTelemetry(m.top.configuration)
    while (true)
        msg = wait(m.top.keepAliveDelayMs, m.port)
        m.top.rumScope.callfunc("handleEvent", keepAliveEvent(), m.top.writer)
        msgType = type(msg)
        if (msgType <> "Invalid")
            ddLogWarning("Unexpected message " + msgType + ": " + FormatJson(msg))
        end if
    end while
end sub

' ----------------------------------------------------------------
' Starts a view
' @param name (string) the view name (human-readable)
' @param url (string) the view url (developer identifier)
' ----------------------------------------------------------------
sub startView(name as string, url as string)
    ddLogThread("RumAgent.startView()")
    ensureSetup()
    m.top.rumScope.callfunc("handleEvent", startViewEvent(name, url), m.top.writer)
    m.top.rumScope.callfunc("handleEvent", keepAliveEvent(), m.top.writer)
end sub

' ----------------------------------------------------------------
' Stops a view
' @param name (string) the view name (human-readable)
' @param url (string) the view url (developer identifier)
' ----------------------------------------------------------------
sub stopView(name as string, url as string)
    ddLogThread("RumAgent.stopView()")
    ensureSetup()
    m.top.rumScope.callfunc("handleEvent", stopViewEvent(name, url), m.top.writer)
end sub

' ----------------------------------------------------------------
' Adds an action
' @param action (object) the action to track
' ----------------------------------------------------------------
sub addAction(action as object)
    ddLogThread("RumAgent.addAction()")
    ensureSetup()
    m.top.rumScope.callfunc("handleEvent", addActionEvent(action), m.top.writer)
end sub

' ----------------------------------------------------------------
' Adds an error
' @param exception (object) the caught exception object
' ----------------------------------------------------------------
sub addError(exception as object)
    ddLogThread("RumAgent.addError()")
    ensureSetup()
    m.top.rumScope.callfunc("handleEvent", addErrorEvent(exception), m.top.writer)
end sub

' ----------------------------------------------------------------
' Adds a resource
' @param resource (object) the tracked resource object (as retrieved from the roSystemLog)
' ----------------------------------------------------------------
sub addResource(resource as object)
    ddLogThread("RumAgent.addResource()")
    ensureSetup()
    m.top.rumScope.callfunc("handleEvent", addResourceEvent(resource), m.top.writer)
end sub

' ----------------------------------------------------------------
' Sends a crash report from a previous view
' @param lastExitOrTerminationReason (object) the lastExitOrTerminationReason parameter
' from the channel's RunUserInterface
' ----------------------------------------------------------------
sub sendCrash(lastExitOrTerminationReason as string)
    ensureSetup()
    crashReporter = CreateObject("roSGNode", "RumCrashReporterTask")
    crashReporter.writer = m.top.writer
    crashReporter.lastExitOrTerminationReason = lastExitOrTerminationReason
    crashReporter.instanceId = m.instanceId
    crashReporter.control = "RUN"
end sub

' ----------------------------------------------------------------
' Adds a telemetry config event
' @param configuration (object) the configuration information
' ----------------------------------------------------------------
sub addConfigTelemetry(configuration as object)
    ddLogThread("RumAgent.addConfigTelemetry()")
    ensureSetup()
    m.top.telemetryScope.callfunc("handleEvent", addTelemetryConfigEvent(configuration), m.top.writer)
end sub

' ----------------------------------------------------------------
' Adds a telemetry error event
' @param exception (object) the caught exception object
' ----------------------------------------------------------------
sub addErrorTelemetry(exception as object)
    ddLogThread("RumAgent.addErrorTelemetry()")
    ensureSetup()
    m.top.telemetryScope.callfunc("handleEvent", addTelemetryErrorEvent(exception), m.top.writer)
end sub

' ----------------------------------------------------------------
' Adds a telemetry debug event
' @param message (string) the message to send
' ----------------------------------------------------------------
sub addDebugTelemetry(message as string)
    ddLogThread("RumAgent.addDebugTelemetry()")
    ensureSetup()
    m.top.telemetryScope.callfunc("handleEvent", addTelemetryDebugEvent(message), m.top.writer)
end sub

' ----------------------------------------------------------------
' Ensure all dependencies are present (from DI or generated)
' ----------------------------------------------------------------
sub ensureSetup()
    ensureRumScope()
    ensureTelemetryScope()
    ensureUploader()
    ensureWriter()
end sub

' ----------------------------------------------------------------
' Sets the root RUM scope node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureRumScope()
    if (m.top.rumScope = invalid)
        m.instanceId = CreateObject("roDeviceInfo").GetRandomUUID()
        ddLogWarning("RumViewScope.instanceId:" + m.instanceId)
        m.global.addFields({
            datadogRumContext: {}
        })
        datadogRumContext = m.global.datadogRumContext
        datadogRumContext.applicationId = m.top.applicationId
        datadogRumContext.instanceId = m.instanceId
        m.global.setField("datadogRumContext", datadogRumContext)
        ddLogVerbose("Creating RumApplicationScope")
        m.top.rumScope = CreateObject("roSGNode", "RumApplicationScope")
        m.top.rumScope.applicationId = m.top.applicationId
        m.top.rumScope.service = m.top.service
        m.top.rumScope.sessionSampleRate = m.top.sessionSampleRate
    end if
end sub

' ----------------------------------------------------------------
' Sets the telemetry scope node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureTelemetryScope()
    if (m.top.telemetryScope = invalid)
        ddLogVerbose("Creating RumTelemetryScope")
        m.top.telemetryScope = CreateObject("roSGNode", "RumTelemetryScope")
    end if
end sub

' ----------------------------------------------------------------
' Sets the uploader node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureUploader()
    uploader = m.top.uploader
    if (m.top.uploader = invalid)
        ddLogVerbose("Creating MultiTrackUploaderTask")
        uploader = CreateObject("roSGNode", "MultiTrackUploaderTask")
    end if
    trackId = "rum_" + m.top.threadInfo().node.address
    tracks = (function(uploader)
            __bsConsequent = uploader.tracks
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(uploader)
    tracks[trackId] = {
        url: getIntakeUrl(m.top.site, "rum")
        trackType: "rum"
        payloadPrefix: ""
        payloadPostfix: ""
        contentType: "text/plain;charset=UTF-8"
        queryParams: {
            ddsource: agentSource()
            ddtags: "sdk_version:" + sdkVersion()
        }
    }
    uploader.tracks = tracks
    uploader.clientToken = m.top.clientToken
    m.top.uploader = uploader
end sub

' ----------------------------------------------------------------
' Sets the writer node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureWriter()
    writer = m.top.writer
    if (writer = invalid)
        ddLogVerbose("Creating WriterTask")
        writer = CreateObject("roSGNode", "WriterTask")
    end if
    writer.trackType = "rum"
    writer.payloadSeparator = chr(10)
    m.top.writer = writer
end sub