' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Main entry point for the sample app
' @param args (dynamic) arguments passed by the OS when starting the channel
' ----------------------------------------------------------------
sub RunUserInterface(args as dynamic)
    datadogroku_logThread("RunUserInterface")
    if ((args.mediaType <> invalid) and (args.contentId <> invalid))
        datadogroku_logInfo("Sample app launched with deeplink: " + args.contentId + "/" + args.mediaType)
    end if

    screen = CreateObject("roSGScreen")

    credentials = parseJson(readAsciiFile("pkg:/credentials.json"))
    m.global = screen.getGlobalNode()
    m.global.addFields({
        credentials: credentials
    })

    m.port = CreateObject("roMessagePort")

    screen.setMessagePort(m.port)
    scene = screen.CreateScene("MainScreen")
    screen.show()
    scene.signalBeacon("AppLaunchComplete")

    ' Handle roInput (deeplink changes at runtime)
    input = CreateObject("roInput")
    input.setMessagePort(m.port)

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if (msgType = "roSGScreenEvent")
            if (msg.isScreenClosed())
                return
            end if
        else if (msgType = "roInputEvent")
            print "Received input event"; msg.getInfo()
        end if
    end while

end sub
