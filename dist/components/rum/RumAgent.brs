' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/rum/rumRawEvents.bs"
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
    m.top.observeFieldScoped("stop", m.port)
    m.top.functionName = "rumAgentLoop"
    m.top.control = "RUN"
end sub

' ----------------------------------------------------------------
' Main RumAgent loop
' ----------------------------------------------------------------
sub rumAgentLoop()
    ddLogThread("RumAgent.rumAgentLoop()")
    while (true)
        msg = wait(m.top.keepAliveDelayMs, m.port)
        ensureSetup()
        m.top.rumScope.callfunc("handleEvent", keepAliveEvent(), m.top.writer)
        msgType = type(msg)
        if (msgType = "roSGNodeEvent")
            fieldName = msg.getField()
            if (fieldName = "stop")
                return
            else
                ddLogWarning(fieldName + " not handled")
            end if
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
' Ensure all dependencies are present (from DI or generated)
' ----------------------------------------------------------------
sub ensureSetup()
    ensureRumScope()
    ensureUploader()
    ensureWriter()
end sub

' ----------------------------------------------------------------
' Sets the uploader node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureRumScope()
    if (m.top.rumScope = invalid)
        ddLogVerbose("Creating RumApplicationScope")
        m.top.rumScope = CreateObject("roSGNode", "RumApplicationScope")
        m.top.rumScope.applicationId = m.top.applicationId
        m.top.rumScope.serviceName = m.top.serviceName
        m.global.addFields({
            datadogRumContext: {}
        })
        datadogRumContext = m.global.datadogRumContext
        datadogRumContext.applicationId = m.top.applicationId
        m.global.setField("datadogRumContext", datadogRumContext)
    end if
end sub

' ----------------------------------------------------------------
' Sets the uploader node from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureUploader()
    uploader = m.top.uploader
    if (m.top.uploader = invalid)
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
        endpointHost: m.top.endpointHost
        trackType: "rum"
        payloadPrefix: ""
        payloadPostfix: ""
        contentType: "text/plain;charset=UTF-8"
        queryParams: {}
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