' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Main entry point for the test app
' ----------------------------------------------------------------
sub RunUserInterface()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    m.scene = screen.CreateScene("TestScreen")
    screen.show()

    try
        m.scene.testResults = runTests()
    catch e
        m.scene.crash = e
    end try

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


' ----------------------------------------------------------------
' Runs all the tests
' ----------------------------------------------------------------
function runTests() as object
    Runner = TestRunner()

    Runner.SetFunctions([
        TestSuite__FileUtils,
        TestSuite__UploaderTask
    ])

    ' setup logger
    Runner.Logger.SetVerbosity(3) ' 0=basic, 1=normal, 2=verboseFail, 3=verbose
    Runner.Logger.SetEcho(true)
    Runner.Logger.SetJUnit(false)

    ' run all tests to get one single report
    Runner.SetFailFast(false)

    statResult = Runner.Logger.CreateTotalStatistic()
    Runner.Run(statResult)
    return statResult
end function
