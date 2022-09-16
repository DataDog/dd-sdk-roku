' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
' * RumAgent: a background component listening for internal events
' *     to write relevant RUM Event to Datadog.
'*****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
end sub

' ----------------------------------------------------------------
' Starts a view
' ----------------------------------------------------------------
sub startView(name as string, url as string)
    ensureSetup()
    m.rumScope.callFunc("handleEvent", { eventType: "startView", viewName: name, viewUrl: url }, m.writer)
end sub

' ----------------------------------------------------------------
' Stops a view
' ----------------------------------------------------------------
sub stopView(name as string, url as string)
    ensureSetup()
    m.rumScope.callFunc("handleEvent", { eventType: "stopView", viewName: name, viewUrl: url }, m.writer)
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
    if (m.rumScope = invalid)
        logInfo("Rum Scope doesn't exist…")
        if (m.top.rumScope <> invalid)
            logInfo("Using injected rumScope")
            m.rumScope = m.top.rumScope
        else
            logInfo("Creating new rumScope")
            m.rumScope = CreateObject("roSGNode", "RumApplicationScope")
            m.rumScope.applicationId = m.applicationId
            m.rumScope.serviceName = m.serviceName
        end if
    end if
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
        m.uploader.trackType = "rum"
        m.uploader.payloadPrefix = ""
        m.uploader.payloadPostfix = ""
        m.uploader.clientToken = m.top.clientToken
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
        m.writer.trackType = "rum"
        m.writer.payloadSeparator = chr(10)
    end if
end sub
