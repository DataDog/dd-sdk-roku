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

'     BaseTestSuite
'     BTS__AddTest
'     BTS__CreateTest
'     BTS__MultipleAssertions

' ----------------------------------------------------------------
' Main function. Create BaseTestSuite object.

' @return A BaseTestSuite object.
' ----------------------------------------------------------------
function BaseTestSuite()
    this = {}
    this.global = m.global
    this.Name = "BaseTestSuite"
    this.SKIP_TEST_MESSAGE_PREFIX = "SKIP_TEST_MESSAGE_PREFIX__"
    ' Test Cases methods
    this.testCases = []
    this.IS_NEW_APPROACH = false
    this.addTest = BTS__AddTest
    this.createTest = BTS__CreateTest
    this.StorePerformanceData = BTS__StorePerformanceData

    ' Assertion methods which determine test failure or skipping
    this.skip = BTS__Skip
    this.fail = BTS__Fail
    this.multipleAssertions = BTS__MultipleAssertions

    ' Type Comparison Functionality
    this.eqValues = TF_Utils__EqValues
    this.eqAssocArrays = TF_Utils__EqAssocArray
    this.eqArrays = TF_Utils__EqArray
    this.baseComparator = TF_Utils__BaseComparator

    return this
end function

' ----------------------------------------------------------------
' Add a test to a suite's test cases array.

' @param name (string) A test name.
' @param func (object) A pointer to test function.
' @param setup (object) A pointer to setup function.
' @param teardown (object) A pointer to teardown function.
' @param arg (dynamic) A test function arguments.
' @param hasArgs (boolean) True if test function has parameters.
' @param skip (boolean) Skip test run.
' ----------------------------------------------------------------
sub BTS__AddTest(name as string, func as object, setup = invalid as object, teardown = invalid as object, arg = invalid as dynamic, hasArgs = false as boolean, skip = false as boolean)
    m.testCases.Push(m.createTest(name, func, setup, teardown, arg, hasArgs, skip))
end sub

' ----------------------------------------------------------------
' Create a test object.

' @param name (string) A test name.
' @param func (object) A pointer to test function.
' @param setup (object) A pointer to setup function.
' @param teardown (object) A pointer to teardown function.
' @param arg (dynamic) A test function arguments.
' @param hasArgs (boolean) True if test function has parameters.
' @param skip (boolean) Skip test run.
'
' @return TestCase object.
' ----------------------------------------------------------------
function BTS__CreateTest(name as string, func as object, setup = invalid as object, teardown = invalid as object, arg = invalid as dynamic, hasArgs = false as boolean, skip = false as boolean) as object
    return {
        Name: name
        Func: func
        SetUp: setup
        TearDown: teardown
        TestSuite: m

        perfData: {}

        hasArguments: hasArgs
        arg: arg

        skip: skip
    }
end function

'----------------------------------------------------------------
' Store performance data to current test instance.
'
' @param name (string) A property name.
' @param value (Object) A value of data.
'----------------------------------------------------------------
sub BTS__StorePerformanceData(name as string, value as object)
    timestamp = StrI(CreateObject("roDateTime").AsSeconds())
    m.testInstance.perfData.Append({
        name: {
            "value": value
            "timestamp": timestamp
        }
    })
    ' print performance data to console
    ? "PERF_DATA: " + m.testInstance.Name + ": " + timestamp + ": " + name + "|" + TF_Utils__AsString(value)
end sub

' ----------------------------------------------------------------
' Assertion methods which determine test failure or skipping
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' Should be used to skip test cases. To skip test you must return the result of this method invocation.

' @param message (string) Optional skip message.
' Default value: "".

' @return A skip message, with a specific prefix added, in order to runner know that this test should be skipped.
' ----------------------------------------------------------------
function BTS__Skip(message = "" as string) as string
    ' add prefix so we know that this test is skipped, but not failed
    return m.SKIP_TEST_MESSAGE_PREFIX + message
end function

' ----------------------------------------------------------------
' Fail immediately, with the given message

' @param msg (string) An error message.
' Default value: "Error".

' @return An error message.
' ----------------------------------------------------------------
function BTS__Fail(msg = "Error" as string) as string
    return msg
end function

' ----------------------------------------------------------------
' Fail if the array contains at least one non empty string.

' @param item (objec) An array of strings to check.

' @return An error message.
' ----------------------------------------------------------------
function BTS__MultipleAssertions(assertions as object) as string
    failedAssertions = 0
    combinedMsg = ""
    for each assertion in assertions
        if (not TF_Utils__IsString(assertion))
            return "Expected assertions to be strings but found type " + type(assertion) + chr(10) + FormatJson(assertions)
        end if

        if (assertion <> "")
            failedAssertions++
            if (failedAssertions > 1)
                combinedMsg = combinedMsg + ";" + chr(10) + assertion
            else
                combinedMsg = assertion
            end if
        end if
    end for

    if (failedAssertions = 0)
        return ""
    else if (failedAssertions = 1)
        return combinedMsg
    else
        return failedAssertions.toStr() + " failed assertions: " + chr(10) + combinedMsg
    end if
end function
