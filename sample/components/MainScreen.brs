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

    m.rumAgent = CreateObject("roSGNode", "datadogroku_RumAgent")
    m.rumAgent.endpointHost = "rum.browser-intake-datadoghq.com"
    m.rumAgent.clientToken = m.global.credentials.datadogClientToken
    m.rumAgent.applicationId = m.global.credentials.datadogApplicationId
    m.rumAgent.serviceName = "roku-sample"

    m.errorIdx = 0

    startView()
end sub

sub onBtnSelected()
    m.msgLabel.text = "Clicked on Button" + Str(m.ButtonGroup.buttonSelected)

    if (m.ButtonGroup.buttonSelected = 0)
        startView()
    else if (m.ButtonGroup.buttonSelected = 1)
        stopView()
    else if (m.ButtonGroup.buttonSelected = 2)
        sendError()
    else if (m.ButtonGroup.buttonSelected = 3)
        sendResource()
    end if
end sub

sub startView()
    viewName = "MainScreen"
    viewUrl = "http://example.com/components/MainScreen.brs"
    m.rumAgent.callFunc("startView", viewName, viewUrl)
end sub

sub stopView()
    viewName = "MainScreen"
    viewUrl = "http://example.com/components/MainScreen.brs"
    m.rumAgent.callFunc("stopView", viewName, viewUrl)
end sub

sub sendError()
    m.errorIdx++
    try
        print "About to explode"
        explodingMethod(m.errorIdx)
    catch error
        print "Caught something"
        print error
        m.rumAgent.callFunc("addError", error)
    end try
end sub

sub sendResource()
    task = createObject("roSGNode", "RequestTask")
    task.setField("query", "datadog")
    task.setField("rumAgent", m.rumAgent)
    task.control = "RUN"
end sub
