' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Main entry point for the test app
' @param args (dynamic) arguments passed by the OS when starting the channel
' ----------------------------------------------------------------
sub RunUserInterface(args as dynamic)
    if ((args.mediaType <> invalid) and (args.contentId <> invalid))
        datadogroku_logInfo("Test app launched with deeplink: " + args.contentId + "/" + args.mediaType)
    end if

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    m.scene = screen.CreateScene("TestScreen")
    screen.show()
    m.scene.signalBeacon("AppLaunchComplete")

    try
        m.scene.testResults = runTests()
    catch e
        m.scene.crash = e
    end try

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

' ----------------------------------------------------------------
' Runs all the tests
' ----------------------------------------------------------------
function runTests() as object
    Runner = TestRunner()

    Runner.SetFunctions([
        TestSuite__FileUtils,
        TestSuite__UploaderTask,
        TestSuite__WriterTask,
        TestSuite__RumAgent,
        TestSuite__RumApplicationScope,
        TestSuite__RumSessionScope,
        TestSuite__RumViewScope
    ])

    ' setup logger
    Runner.Logger.SetVerbosity(0) ' 0=basic, 1=normal, 2=verboseFail, 3=verbose
    Runner.Logger.SetEcho(true)
    Runner.Logger.SetJUnit(false)

    ' run all tests to get one single report
    Runner.SetFailFast(false)

    statResult = Runner.Logger.CreateTotalStatistic()
    Runner.Run(statResult)
    return statResult
end function
