' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Main entry point for the test app
' ----------------------------------------------------------------
sub RunUserInterface(args)
    print "Running test app"

    Runner = TestRunner()

    Runner.SetFunctions([
        TestSuite__Main
    ])

    ' setup logger
    Runner.Logger.SetVerbosity(1) ' 0=basic, 1=normal, 2=verboseFail, 3=verbose
    Runner.Logger.SetEcho(false)
    Runner.Logger.SetJUnit(false)

    ' run all tests to get one single report
    Runner.SetFailFast(false)

    Runner.Run()
end sub
