' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Main entry point for the sample app
' ----------------------------------------------------------------
sub RunUserInterface()
    datadogroku_logThread("RunUserInterface")

    screen = CreateObject("roSGScreen")

    credentials = parseJson(readAsciiFile("pkg:/credentials.json"))
    m.global = screen.getGlobalNode()
    m.global.addFields({
        credentials: credentials
    })

    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    screen.CreateScene("MainScreen")
    screen.show()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if (msgType = "roSGScreenEvent")
            if (msg.isScreenClosed())
                return
            end if
        end if
    end while

end sub
