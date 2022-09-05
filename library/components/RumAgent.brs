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
    m.deviceInfo = CreateObject("roDeviceInfo")
    m.appInfo = CreateObject("roAppInfo")
    m.session = {
        ' TODO RUMM-2478 Implement session logic
        id: m.deviceInfo.GetRandomUUID(),
        startTime&: getTimestamp()
    }
    m.view = invalid
end sub

' ----------------------------------------------------------------
' Starts a view
' ----------------------------------------------------------------
sub startView(name as string, url as string)
    if (m.view <> invalid)
        stopView(m.view.name, m.view.url)
    end if

    m.view = {
        id: m.deviceInfo.GetRandomUUID(),
        name: name,
        url: url,
        startTime&: getTimestamp(),
        update: 0,
        stopped: false
    }
    sendViewUpdate()
end sub

' ----------------------------------------------------------------
' Stops a view
' ----------------------------------------------------------------
sub stopView(name as string, url as string)
    if (m.view = invalid)
        logWarning("Trying to stop invalid view, ignoring.")
        return
    end if

    if (m.view.url <> url)
        logWarning("Trying to stop unknown view '" + name + "' (" + url + "), ignoring.")
        return
    end if

    if (m.view.stopped)
        logWarning("Trying to stop view '" + name + "' (" + url + ") but it's already stopped.")
        return
    end if

    m.view.stopped = true
    sendViewUpdate()
end sub

' ----------------------------------------------------------------
' Send a view event
' ----------------------------------------------------------------
sub sendViewUpdate()
    timestamp& = getTimestamp()

    ensureWriter()
    ensureUploader()

    m.view.update++
    timeSpentNs& = (timestamp& - m.view.startTime&) * 1000000 ' convert ms to ns

    viewEvent = {
        _dd: {
            format_version: 2,
            session: { plan: 1 },
            document_version: m.view.update
        },
        application: {
            id: m.top.applicationId
        },
        date: m.view.startTime&,
        service: m.top.service,
        session: {
            has_replay: false,
            id: m.session.id,
            type: "user"
        },
        source: agentSource(),
        type: "view",
        version: m.appInfo.GetVersion(),
        view: {
            id: m.view.id,
            url: m.view.url,
            name: m.view.name,
            time_spent: timeSpentNs&,
            action: { count: 0 }, ' TODO RUMM-2435
            error: { count: 0 }, ' TODO RUMM-2435
            resource: { count: 0 }' TODO RUMM-2435
        }
    }

    m.writer.writeEvent = FormatJson(viewEvent)
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
