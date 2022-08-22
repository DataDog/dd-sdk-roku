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
end sub

sub onBtnSelected()
    m.msgLabel.text = "Clicked on Button" + Str(m.ButtonGroup.buttonSelected)
    ' TODO handle all events
end sub
