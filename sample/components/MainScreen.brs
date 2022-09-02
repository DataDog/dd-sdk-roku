' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

sub init()
    m.top.backgroundURI = "pkg:/images/main_bg_hd.jpg"
    m.top.setFocus(true)
    m.titleLabel = m.top.findNode("titleLabel")
    m.msgLabel = m.top.findNode("messageLabel")
    m.titleLabel.font.size = 64

    m.ButtonGroup = m.top.findNode("mainButtonGroup")
    m.ButtonGroup.setFocus(true)
    m.ButtonGroup.observeField("buttonSelected", "onBtnSelected")

    m.uploader = CreateObject("roSGNode", "datadogroku_UploaderTask")
    m.uploader.endpointHost = "rum.browser-intake-datadoghq.com"
    m.uploader.trackType = "rum"
    m.uploader.clientToken = m.global.credentials.datadogClientToken
    m.uploader.control = "run"

    m.writer = CreateObject("roSGNode", "datadogroku_WriterTask")
    m.writer.trackType = "rum"
    m.writer.payloadSeparator = chr(10)
    m.writer.control = "run"

end sub

sub onBtnSelected()
    m.msgLabel.text = "Clicked on Button" + Str(m.ButtonGroup.buttonSelected)

    if (m.ButtonGroup.buttonSelected = 0)
        writeViewEvent()
        ' TODO handle all events
    else if (m.ButtonGroup.buttonSelected = 1)

    end if
end sub

sub writeViewEvent()
    timestamp& = datadogroku_getTimestamp()
    appInfo = CreateObject("roAppInfo")
    deviceInfo = CreateObject("roDeviceInfo")

    viewEvent = {
        date: timestamp&,
        type: "view",
        application: {
            id: m.global.credentials.datadogApplicationId
        },
        service: "roku-channel-" + appInfo.GetID(),
        session: {
            id: deviceInfo.GetRandomUUID(),
            type: "user",
            has_replay: false
        },
        source: datadogroku_agentSource(),
        version: appInfo.GetVersion(),
        view: {
            id: deviceInfo.GetRandomUUID(),
            url: "pkg:/root",
            name: "I am 'root",
            time_spent: 1, '
            action: { count: 0 },
            error: { count: 0 },
            resource: { count: 0 }
        },
        _dd: {
            format_version: 2,
            session: { plan: 1 },
            document_version: 1
        }
    }
    ' eventAsString = FormatJson(viewEvent)
    ' m.writer.callFunc("writeEvent", eventAsString)
    m.writer.writeEvent = FormatJson(viewEvent)
end sub
