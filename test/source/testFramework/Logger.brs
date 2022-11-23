'*****************************************************************
'* Roku Unit Testing Framework
'* Automating test suites for Roku channels.
'*
'* Build Version: 2.1.1
'* Build Date: 05/06/2019
'*
'* Public Documentation is avaliable on GitHub:
'* 		https://github.com/rokudev/unit-testing-framework
'*
'*****************************************************************
'*****************************************************************
'* Licensed under the Apache License Version 2.0
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************

' Functions in this file:
'        Logger
'        Logger__SetVerbosity
'        Logger__SetEcho
'        Logger__SetServerURL
'        Logger__PrintStatistic
'        Logger__SendToServer
'        Logger__CreateTotalStatistic
'        Logger__CreateSuiteStatistic
'        Logger__CreateTestStatistic
'        Logger__AppendSuiteStatistic
'        Logger__AppendTestStatistic
'        Logger__PrintSuiteStatistic
'        Logger__PrintTestStatistic
'        Logger__PrintStart
'        Logger__PrintEnd
'        Logger__PrintSuiteSetUp
'        Logger__PrintSuiteStart
'        Logger__PrintSuiteEnd
'        Logger__PrintSuiteTearDown
'        Logger__PrintTestSetUp
'        Logger__PrintTestStart
'        Logger__PrintTestEnd
'        Logger__PrintTestTearDown

' ----------------------------------------------------------------
' Main function. Create Logger object.

' @return A Logger object.
' ----------------------------------------------------------------
function Logger() as object
    this = {}

    this.verbosityLevel = {
        basic: 0
        normal: 1
        verboseFailed: 2
        verbose: 3
    }

    ' Internal properties
    this.verbosity = this.verbosityLevel.normal
    this.echoEnabled = false
    this.serverURL = ""
    this.jUnitEnabled = false

    ' Interface
    this.SetVerbosity = Logger__SetVerbosity
    this.SetEcho = Logger__SetEcho
    this.SetJUnit = Logger__SetJUnit
    this.SetServer = Logger__SetServer
    this.SetServerURL = Logger__SetServerURL ' Deprecated. Use Logger__SetServer instead.
    this.PrintStatistic = Logger__PrintStatistic
    this.SendToServer = Logger__SendToServer

    this.CreateTotalStatistic = Logger__CreateTotalStatistic
    this.CreateSuiteStatistic = Logger__CreateSuiteStatistic
    this.CreateTestStatistic = Logger__CreateTestStatistic
    this.AppendSuiteStatistic = Logger__AppendSuiteStatistic
    this.AppendTestStatistic = Logger__AppendTestStatistic

    ' Internal functions
    this.PrintSuiteStatistic = Logger__PrintSuiteStatistic
    this.PrintTestStatistic = Logger__PrintTestStatistic
    this.PrintStart = Logger__PrintStart
    this.PrintEnd = Logger__PrintEnd
    this.PrintSuiteSetUp = Logger__PrintSuiteSetUp
    this.PrintSuiteStart = Logger__PrintSuiteStart
    this.PrintSuiteEnd = Logger__PrintSuiteEnd
    this.PrintSuiteTearDown = Logger__PrintSuiteTearDown
    this.PrintTestSetUp = Logger__PrintTestSetUp
    this.PrintTestStart = Logger__PrintTestStart
    this.PrintTestEnd = Logger__PrintTestEnd
    this.PrintTestTearDown = Logger__PrintTestTearDown
    this.PrintJUnitFormat = Logger__PrintJUnitFormat

    return this
end function

' ----------------------------------------------------------------
' Set logging verbosity parameter.

' @param verbosity (integer) A verbosity level.
' Posible values:
'     0 - basic
'     1 - normal
'     2 - verbose failed tests
'     3 - verbose
' Default level: 1
' ----------------------------------------------------------------
sub Logger__SetVerbosity(verbosity = m.verbosityLevel.normal as integer)
    if verbosity >= m.verbosityLevel.basic and verbosity <= m.verbosityLevel.verbose
        m.verbosity = verbosity
    end if
end sub

' ----------------------------------------------------------------
' Set logging echo parameter.

' @param enable (boolean) A echo trigger.
' Posible values: true or false
' Default value: false
' ----------------------------------------------------------------
sub Logger__SetEcho(enable = false as boolean)
    m.echoEnabled = enable
end sub

' ----------------------------------------------------------------
' Set logging JUnit output parameter.

' @param enable (boolean) A JUnit output trigger.
' Posible values: true or false
' Default value: false
' ----------------------------------------------------------------
sub Logger__SetJUnit(enable = false as boolean)
    m.jUnitEnabled = enable
end sub

' ----------------------------------------------------------------
' Set storage server parameters.

' @param url (string) Storage server host.
' Default value: ""
' @param port (string) Storage server port.
' Default value: ""
' ----------------------------------------------------------------
sub Logger__SetServer(host = "" as string, port = "" as string)
    if TF_Utils__IsNotEmptyString(host)
        if TF_Utils__IsNotEmptyString(port)
            m.serverURL = "http://" + host + ":" + port
        else
            m.serverURL = "http://" + host
        end if
    end if
end sub

' ----------------------------------------------------------------
' Set storage server URL parameter.

' @param url (string) A storage server URL.
' Default value: ""
' ----------------------------------------------------------------
sub Logger__SetServerURL(url = "" as string)
    ? "This function is deprecated. Please use Logger__SetServer(host, port)"
end sub

'----------------------------------------------------------------
' Send test results as a POST json payload.
'
' @param statObj (object) stats of the test run.
' Default value: invalid
' ----------------------------------------------------------------
sub Logger__SendToServer(statObj as object)
    if TF_Utils__IsNotEmptyString(m.serverURL) and TF_Utils__IsValid(statObj)
        ? "***"
        ? "***   Sending statsObj to server: "; m.serverURL

        request = CreateObject("roUrlTransfer")
        request.SetUrl(m.serverURL)
        statString = FormatJson(statObj)

        ? "***   Response: "; request.postFromString(statString)
        ? "***"
        ? "******************************************************************"
    end if
end sub

' ----------------------------------------------------------------
' Print statistic object with specified verbosity.

' @param statObj (object) A statistic object to print.
' ----------------------------------------------------------------
sub Logger__PrintStatistic(statObj as object)
    if not m.echoEnabled
        m.PrintStart()

        if m.verbosity = m.verbosityLevel.normal or m.verbosity = m.verbosityLevel.verboseFailed
            for each testSuite in statObj.Suites
                for each testCase in testSuite.Tests
                    if m.verbosity = m.verbosityLevel.verboseFailed and testCase.result = "Fail"
                        m.printTestStatistic(testCase)
                    else
                        ? "***   "; testSuite.Name; ": "; testCase.Name; " - "; testCase.Result
                    end if
                end for
            end for
        else if m.verbosity = m.verbosityLevel.verbose
            for each testSuite in statObj.Suites
                m.PrintSuiteStatistic(testSuite)
            end for
        end if
    end if

    ? "***"
    ? "***   Total  = "; TF_Utils__AsString(statObj.Total); " ; Passed  = "; statObj.Correct; " ; Failed   = "; statObj.Fail; " ; Skipped   = "; statObj.skipped; " ; Crashes  = "; statObj.Crash
    ? "***   Time spent: "; statObj.Time; "ms"
    ? "***"

    m.PrintEnd()

    m.SendToServer(statObj)

    if m.jUnitEnabled
        m.printJUnitFormat(statObj)
    end if
end sub

' ----------------------------------------------------------------
' Create an empty statistic object for totals in output log.

' @return An empty statistic object.
' ----------------------------------------------------------------
function Logger__CreateTotalStatistic() as object
    statTotalItem = {
        Suites: []
        Time: 0
        Total: 0
        Correct: 0
        Fail: 0
        Skipped: 0
        Crash: 0,
        OutputLog: []
    }

    if m.echoEnabled
        m.PrintStart()
    end if

    return statTotalItem
end function

' ----------------------------------------------------------------
' Create an empty statistic object for test suite with specified name.

' @param name (string) A test suite name for statistic object.

' @return An empty statistic object for test suite.
' ----------------------------------------------------------------
function Logger__CreateSuiteStatistic(name as string) as object
    statSuiteItem = {
        Name: name
        Tests: []
        Time: 0
        Total: 0
        Correct: 0
        Fail: 0
        Skipped: 0
        Crash: 0
        OutputLog: []
    }

    if m.echoEnabled
        if m.verbosity = m.verbosityLevel.verbose
            m.PrintSuiteStart(name)
        end if
    end if

    return statSuiteItem
end function

' ----------------------------------------------------------------
' Create statistic object for test with specified name.

' @param name (string) A test name.
' @param result (string) A result of test running.
' Posible values: "Success", "Fail".
' Default value: "Success"
' @param time (integer) A test running time.
' Default value: 0
' @param errorCode (integer) An error code for failed test.
' Posible values:
'     252 (&hFC) : ERR_NORMAL_END
'     226 (&hE2) : ERR_VALUE_RETURN
'     233 (&hE9) : ERR_USE_OF_UNINIT_VAR
'     020 (&h14) : ERR_DIV_ZERO
'     024 (&h18) : ERR_TM
'     244 (&hF4) : ERR_RO2
'     236 (&hEC) : ERR_RO4
'     002 (&h02) : ERR_SYNTAX
'     241 (&hF1) : ERR_WRONG_NUM_PARAM
' Default value: 0
' @param errorMessage (string) An error message for failed test.

' @return A statistic object for test.
' ----------------------------------------------------------------
function Logger__CreateTestStatistic(name as string, result = "Success" as string, time = 0 as integer, errorCode = 0 as integer, errorMessage = "" as string, isInit = false as boolean) as object
    statTestItem = {
        Name: name
        Result: result
        Time: time
        PerfData: {}
        Error: {
            Code: errorCode
            Message: errorMessage
        }
    }

    if m.echoEnabled and not isInit
        if m.verbosity = m.verbosityLevel.verbose
            m.PrintTestStart(name)
        end if
    end if

    return statTestItem
end function

' ----------------------------------------------------------------
' Append test statistic to test suite statistic.

' @param statSuiteObj (object) A target test suite object.
' @param statTestObj (object) A test statistic to append.
' ----------------------------------------------------------------
sub Logger__AppendTestStatistic(statSuiteObj as object, statTestObj as object)
    if TF_Utils__IsAssociativeArray(statSuiteObj) and TF_Utils__IsAssociativeArray(statTestObj)
        statSuiteObj.Tests.Push(statTestObj)

        if TF_Utils__IsInteger(statTestObj.time)
            statSuiteObj.Time = statSuiteObj.Time + statTestObj.Time
        end if

        statSuiteObj.Total = statSuiteObj.Total + 1

        testStatusSymbol = "?"
        if LCase(statTestObj.result) = "success"
            testStatusSymbol = "✓"
            statSuiteObj.Correct++
        else if LCase(statTestObj.result) = "fail"
            testStatusSymbol = "×"
            statSuiteObj.Fail++
        else if LCase(statTestObj.result) = "skipped"
            testStatusSymbol = "⚬"
            statSuiteObj.skipped++
        else if LCase(statTestObj.result) = "crashed"
            testStatusSymbol = "☠"
            statSuiteObj.crash++
        end if

        if (statTestObj.Error.Message <> "")
            statSuiteObj.OutputLog.Append([testStatusSymbol + " " + statSuiteObj.Name + " - " + statTestObj.name])
            statSuiteObj.OutputLog.Append([statTestObj.Error.Message])
            statSuiteObj.OutputLog.Append([string(16, "- ")])
        else if LCase(statTestObj.result) = "skipped"
            statSuiteObj.OutputLog.Append([testStatusSymbol + " " + statSuiteObj.Name + " - " + statTestObj.name])
            statSuiteObj.OutputLog.Append(["Skipped: " + statTestObj.Message])
            statSuiteObj.OutputLog.Append([string(16, "- ")])
        end if

        if m.echoEnabled
            if m.verbosity = m.verbosityLevel.normal
                ? "***   "; statSuiteObj.Name; ": "; statTestObj.Name; " - "; statTestObj.Result
            else if m.verbosity = m.verbosityLevel.verbose
                m.PrintTestStatistic(statTestObj)
            end if
        end if
    end if
end sub

' ----------------------------------------------------------------
' Append suite statistic to total statistic object.

' @param statTotalObj (object) A target total statistic object.
' @param statSuiteObj (object) A test suite statistic object to append.
' ----------------------------------------------------------------
sub Logger__AppendSuiteStatistic(statTotalObj as object, statSuiteObj as object)
    if TF_Utils__IsAssociativeArray(statTotalObj) and TF_Utils__IsAssociativeArray(statSuiteObj)
        statTotalObj.Suites.Push(statSuiteObj)
        statTotalObj.Time = statTotalObj.Time + statSuiteObj.Time

        if TF_Utils__IsInteger(statSuiteObj.Total)
            statTotalObj.Total = statTotalObj.Total + statSuiteObj.Total
        end if

        if TF_Utils__IsInteger(statSuiteObj.Correct)
            statTotalObj.Correct = statTotalObj.Correct + statSuiteObj.Correct
        end if

        if TF_Utils__IsInteger(statSuiteObj.Fail)
            statTotalObj.Fail = statTotalObj.Fail + statSuiteObj.Fail
        end if

        if TF_Utils__IsInteger(statSuiteObj.skipped)
            statTotalObj.skipped += statSuiteObj.skipped
        end if

        if TF_Utils__IsInteger(statSuiteObj.Crash)
            statTotalObj.Crash = statTotalObj.Crash + statSuiteObj.Crash
        end if

        if (TF_Utils__IsArray(statSuiteObj.OutputLog))
            statTotalObj.OutputLog.Append(statSuiteObj.OutputLog)
        end if

        if m.echoEnabled
            if m.verbosity = m.verbosityLevel.verbose
                m.PrintSuiteStatistic(statSuiteObj)
            end if
        end if
    end if
end sub

' ----------------------------------------------------------------
' Print test suite statistic.

' @param statSuiteObj (object) A target test suite object to print.
' ----------------------------------------------------------------
sub Logger__PrintSuiteStatistic(statSuiteObj as object)
    if not m.echoEnabled
        m.PrintSuiteStart(statSuiteObj.Name)

        for each testCase in statSuiteObj.Tests
            m.PrintTestStatistic(testCase)
        end for
    end if

    ? "==="
    ? "===   Total  = "; TF_Utils__AsString(statSuiteObj.Total); " ; Passed  = "; statSuiteObj.Correct; " ; Failed   = "; statSuiteObj.Fail; " ; Skipped   = "; statSuiteObj.skipped; " ; Crashes  = "; statSuiteObj.Crash;
    ? " Time spent: "; statSuiteObj.Time; "ms"
    ? "==="

    m.PrintSuiteEnd(statSuiteObj.Name)
end sub

' ----------------------------------------------------------------
' Print test statistic.

' @param statTestObj (object) A target test object to print.
' ----------------------------------------------------------------
sub Logger__PrintTestStatistic(statTestObj as object)
    if not m.echoEnabled
        m.PrintTestStart(statTestObj.Name)
    end if

    ? "---   Result:        "; statTestObj.Result
    ? "---   Time:          "; statTestObj.Time

    if LCase(statTestObj.result) = "skipped"
        if Len(statTestObj.message) > 0
            ? "---   Message: "; statTestObj.message
        end if
    else if LCase(statTestObj.Result) <> "success"
        ? "---   Error Code:    "; statTestObj.Error.Code
        ? "---   Error Message: "; statTestObj.Error.Message
    end if

    m.PrintTestEnd(statTestObj.Name)
end sub

' ----------------------------------------------------------------
' Print testting start message.
' ----------------------------------------------------------------
sub Logger__PrintStart()
    ? ""
    ? "******************************************************************"
    ? "******************************************************************"
    ? "*************            Start testing               *************"
    ? "******************************************************************"
end sub

' ----------------------------------------------------------------
' Print testing end message.
' ----------------------------------------------------------------
sub Logger__PrintEnd()
    ? "******************************************************************"
    ? "*************             End testing                *************"
    ? "******************************************************************"
    ? "******************************************************************"
    ? ""
end sub

' ----------------------------------------------------------------
' Print test suite SetUp message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteSetUp(sName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "================================================================="
        ? "===   SetUp "; sName; " suite."
        ? "================================================================="
    end if
end sub

' ----------------------------------------------------------------
' Print test suite start message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteStart(sName as string)
    ? "================================================================="
    ? "===   Start "; sName; " suite:"
    ? "==="
end sub

' ----------------------------------------------------------------
' Print test suite end message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteEnd(sName as string)
    ? "==="
    ? "===   End "; sName; " suite."
    ? "================================================================="
end sub

' ----------------------------------------------------------------
' Print test suite TearDown message.
' ----------------------------------------------------------------
sub Logger__PrintSuiteTearDown(sName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "================================================================="
        ? "===   TearDown "; sName; " suite."
        ? "================================================================="
    end if
end sub

' ----------------------------------------------------------------
' Print test setUp message.
' ----------------------------------------------------------------
sub Logger__PrintTestSetUp(tName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "----------------------------------------------------------------"
        ? "---   SetUp "; tName; " test."
        ? "----------------------------------------------------------------"
    end if
end sub

' ----------------------------------------------------------------
' Print test start message.
' ----------------------------------------------------------------
sub Logger__PrintTestStart(tName as string)
    ? "----------------------------------------------------------------"
    ? "---   Start "; tName; " test:"
    ? "---"
end sub

' ----------------------------------------------------------------
' Print test end message.
' ----------------------------------------------------------------
sub Logger__PrintTestEnd(tName as string)
    ? "---"
    ? "---   End "; tName; " test."
    ? "----------------------------------------------------------------"
end sub

' ----------------------------------------------------------------
' Print test TearDown message.
' ----------------------------------------------------------------
sub Logger__PrintTestTearDown(tName as string)
    if m.verbosity = m.verbosityLevel.verbose
        ? "----------------------------------------------------------------"
        ? "---   TearDown "; tName; " test."
        ? "----------------------------------------------------------------"
    end if
end sub

sub Logger__PrintJUnitFormat(statObj as object)
    ' TODO finish report
    xml = CreateObject("roXMLElement")
    xml.SetName("testsuites")
    for each testSuiteAA in statObj.suites
        testSuite = xml.AddElement("testsuite")
        ' name="FeatureManagerTest" time="13.923" tests="2" errors="0" skipped="0" failures="0"
        testSuite.AddAttribute("name", testSuiteAA.name)
        testSuite.AddAttribute("time", testSuiteAA.time.toStr())
        testSuite.AddAttribute("tests", testSuiteAA.Tests.count().toStr())

        skippedNum = 0
        failedNum = 0
        for each testAA in testSuiteAA.Tests
            test = testSuite.AddElement("testcase")
            test.AddAttribute("name", testAA.name)
            test.AddAttribute("time", testAA.time.toStr())

            if LCase(testAA.result) = "skipped" then
                test.AddElement("skipped")
                skippedNum++
            else if LCase(testAA.Result) <> "success"
                failure = test.AddElement("failure")
                failure.AddAttribute("message", testAA.error.message)
                failure.AddAttribute("type", testAA.error.code.tostr())
                failedNum++
            end if
        end for
        testSuite.AddAttribute("errors", failedNum.tostr())
        testSuite.AddAttribute("skipped", skippedNum.tostr())
    end for

    ? "******************************************************************"
    ? "*************             JUnit report               *************"
    ? "******************************************************************"
    ? ""
    ? xml.GenXML(true)
    ? ""
    ? "******************************************************************"
end sub

