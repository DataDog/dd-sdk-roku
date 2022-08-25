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
'        TestRunner
'        TestRunner__Run
'        TestRunner__SetTestsDirectory
'        TestRunner__SetTestFilePrefix
'        TestRunner__SetTestSuitePrefix
'        TestRunner__SetTestSuiteName
'        TestRunner__SetTestCaseName
'        TestRunner__SetFailFast
'        TestRunner__GetTestSuitesList
'        TestRunner__GetTestSuiteNamesList
'        TestRunner__GetTestFilesList
'        TestRunner__GetTestNodesList
'        TestRunner__RunNodeTests
'        TestRunner__getFunctionPointer

' ----------------------------------------------------------------
' Main function. Create TestRunner object.

' @return A TestRunner object.
' ----------------------------------------------------------------
function TestRunner() as object
    this = {}
    GetGlobalAA().globalErrorsList = []
    this.isNodeMode = GetGlobalAA().top <> invalid
    this.Logger = Logger()

    ' Internal properties
    this.SKIP_TEST_MESSAGE_PREFIX = "SKIP_TEST_MESSAGE_PREFIX__"
    this.CRASH_TEST_MESSAGE_PREFIX = "CRASH_TEST_MESSAGE_PREFIX__"
    this.nodesTestDirectory = "pkg:/components/tests"
    if this.isNodeMode
        this.testsDirectory = this.nodesTestDirectory
        this.testFilePrefix = m.top.subtype()
    else
        this.testsDirectory = "pkg:/source/tests"
        this.testFilePrefix = "Test__"
    end if
    this.testSuitePrefix = "TestSuite__"
    this.testSuiteName = ""
    this.testCaseName = ""
    this.failFast = false

    ' Interface
    this.Run = TestRunner__Run
    this.SetTestsDirectory = TestRunner__SetTestsDirectory
    this.SetTestFilePrefix = TestRunner__SetTestFilePrefix
    this.SetTestSuitePrefix = TestRunner__SetTestSuitePrefix
    this.SetTestSuiteName = TestRunner__SetTestSuiteName ' Obsolete, will be removed in next versions
    this.SetTestCaseName = TestRunner__SetTestCaseName ' Obsolete, will be removed in next versions
    this.SetFailFast = TestRunner__SetFailFast
    this.SetFunctions = TestRunner__SetFunctions
    this.SetIncludeFilter = TestRunner__SetIncludeFilter
    this.SetExcludeFilter = TestRunner__SetExcludeFilter

    ' Internal functions
    this.GetTestFilesList = TestRunner__GetTestFilesList
    this.GetTestSuitesList = TestRunner__GetTestSuitesList
    this.GetTestNodesList = TestRunner__GetTestNodesList
    this.GetTestSuiteNamesList = TestRunner__GetTestSuiteNamesList
    this.GetIncludeFilter = TestRunner__GetIncludeFilter
    this.GetExcludeFilter = TestRunner__GetExcludeFilter

    return this
end function

' ----------------------------------------------------------------
' Run main test loop.

' @param statObj (object, optional) statistic object to be used in tests
' @param testSuiteNamesList (array, optional) array of test suite function names to be used in tests

' @return Statistic object if run in node mode, invalid otherwise
' ----------------------------------------------------------------
function TestRunner__Run(statObj = m.Logger.CreateTotalStatistic() as object, testSuiteNamesList = [] as object) as object
    alltestCount = 0
    totalStatObj = statObj
    testSuitesList = m.GetTestSuitesList(testSuiteNamesList)

    globalErrorsList = GetGlobalAA().globalErrorsList
    for each testSuite in testSuitesList
        testCases = testSuite.testCases
        testCount = testCases.Count()
        alltestCount = alltestCount + testCount

        IS_NEW_APPROACH = testSuite.IS_NEW_APPROACH
        ' create dedicated env for each test, so that they will have not global m and don't rely on m.that is set in another suite
        env = {}

        if TF_Utils__IsFunction(testSuite.SetUp)
            m.Logger.PrintSuiteSetUp(testSuite.Name)
            if IS_NEW_APPROACH then
                env.functionToCall = testSuite.SetUp
                env.functionToCall()
            else
                testSuite.SetUp()
            end if
        end if

        suiteStatObj = m.Logger.CreateSuiteStatistic(testSuite.Name)
        ' Initiate empty test statistics object to print results if no tests was run
        testStatObj = m.Logger.CreateTestStatistic("", "Success", 0, 0, "", true)
        for each testCase in testCases
            ' clear all existing errors
            globalErrorsList.clear()

            if m.testCaseName = "" or (m.testCaseName <> "" and LCase(testCase.Name) = LCase(m.testCaseName))
                skipTest = TF_Utils__AsBoolean(testCase.skip)

                if TF_Utils__IsFunction(testCase.SetUp) and not skipTest
                    m.Logger.PrintTestSetUp(testCase.Name)
                    if IS_NEW_APPROACH then
                        env.functionToCall = testCase.SetUp
                        env.functionToCall()
                    else
                        testCase.SetUp()
                    end if
                end if

                testTimer = CreateObject("roTimespan")
                testStatObj = m.Logger.CreateTestStatistic(testCase.Name)

                if skipTest
                    runResult = m.SKIP_TEST_MESSAGE_PREFIX + "Test was skipped according to specified filters"
                else
                    testSuite.testInstance = testCase
                    testSuite.testCase = testCase.Func

                    runResult = ""
                    if IS_NEW_APPROACH then
                        env.functionToCall = testCase.Func

                        if GetInterface(env.functionToCall, "ifFunction") <> invalid
                            if testCase.hasArguments then
                                env.functionToCall(testCase.arg)
                            else
                                env.functionToCall()
                            end if
                        else
                            UTF_fail("Failed to execute test """ + testCase.Name + """ function pointer not found")
                        end if
                    else
                        try
                            runResult = testSuite.testCase()
                        catch e
                            runResult = m.CRASH_TEST_MESSAGE_PREFIX + e.message
                            print "✘ ✘ ✘ ✘ ✘ ✘"
                            print "Crash #" + e.number.ToStr() + ": " + e.message
                            for each frame in e.backtrace
                                print frame.function + " (" + frame.filename + ":" + frame.line_number.ToStr() + ")"
                            end for
                            print "✘ ✘ ✘ ✘ ✘ ✘"
                        end try
                    end if
                end if

                if TF_Utils__IsFunction(testCase.TearDown) and not skipTest
                    m.Logger.PrintTestTearDown(testCase.Name)
                    if IS_NEW_APPROACH then
                        env.functionToCall = testCase.TearDown
                        env.functionToCall()
                    else
                        testCase.TearDown()
                    end if
                end if

                if IS_NEW_APPROACH then
                    if globalErrorsList.count() > 0
                        for each error in globalErrorsList
                            runResult += error + Chr(10) + string(10, "-") + Chr(10)
                        end for
                    end if
                end if

                if runResult <> ""
                    if InStr(0, runResult, m.SKIP_TEST_MESSAGE_PREFIX) = 1
                        testStatObj.result = "Skipped"
                        testStatObj.message = runResult.Mid(Len(m.SKIP_TEST_MESSAGE_PREFIX)) ' remove prefix from the message
                    else
                        if InStr(0, runResult, m.CRASH_TEST_MESSAGE_PREFIX) = 1
                            testStatObj.result = "Crashed"
                            testStatObj.Error.Code = 2
                            testStatObj.Error.Message = runResult.Mid(Len(m.SKIP_TEST_MESSAGE_PREFIX)) ' remove prefix from the message
                        else
                            testStatObj.Result = "Fail"
                            testStatObj.Error.Code = 1
                            testStatObj.Error.Message = runResult
                        end if
                    end if
                else
                    testStatObj.Result = "Success"
                end if

                testStatObj.Time = testTimer.TotalMilliseconds()
                m.Logger.AppendTestStatistic(suiteStatObj, testStatObj)

                if (testStatObj.Result = "Fail" or testStatObj.Result = "Crashed") and m.failFast
                    suiteStatObj.Result = "Fail"
                    exit for
                end if
            end if
        end for

        m.Logger.AppendSuiteStatistic(totalStatObj, suiteStatObj)

        if TF_Utils__IsFunction(testSuite.TearDown)
            m.Logger.PrintSuiteTearDown(testSuite.Name)
            testSuite.TearDown()
        end if

        if (suiteStatObj.Result = "Fail" or suiteStatObj.Result = "Crashed") and m.failFast
            exit for
        end if
    end for

    gthis = GetGlobalAA()
    msg = ""
    if gthis.notFoundFunctionPointerList <> invalid then
        msg = Chr(10) + string(40, "---") + Chr(10)
        if m.isNodeMode
            fileNamesString = ""

            for each testSuiteObject in testSuiteNamesList
                if GetInterface(testSuiteObject, "ifString") <> invalid then
                    fileNamesString += testSuiteObject + ".brs, "
                else if GetInterface(testSuiteObject, "ifAssociativeArray") <> invalid then
                    if testSuiteObject.filePath <> invalid then
                        fileNamesString += testSuiteObject.filePath + ", "
                    end if
                end if
            end for

            msg += Chr(10) + "Create this function below in one of these files"
            msg += Chr(10) + fileNamesString + Chr(10)

            msg += Chr(10) + "sub init()"
        end if
        msg += Chr(10) + "Runner.SetFunctions([" + Chr(10) + "    testCase" + Chr(10) + "])"
        msg += Chr(10) + "For example we think this might resolve your issue"
        msg += Chr(10) + "Runner = TestRunner()"
        msg += Chr(10) + "Runner.SetFunctions(["

        tmpMap = {}
        for each functionName in gthis.notFoundFunctionPointerList
            if tmpMap[functionName] = invalid then
                tmpMap[functionName] = ""
                msg += Chr(10) + "    " + functionName
            end if
        end for

        msg += Chr(10) + "])"
        if m.isNodeMode then
            msg += Chr(10) + "end sub"
        else
            msg += Chr(10) + "Runner.Run()"
        end if
    end if

    if m.isNodeMode
        if msg.Len() > 0 then
            if totalStatObj.notFoundFunctionsMessage = invalid then totalStatObj.notFoundFunctionsMessage = ""
            totalStatObj.notFoundFunctionsMessage += msg
        end if
        return totalStatObj
    else
        testNodes = m.getTestNodesList()
        for each testNodeName in testNodes
            testNode = CreateObject("roSGNode", testNodeName)
            if testNode <> invalid
                testSuiteNamesList = m.GetTestSuiteNamesList(testNodeName)
                if CreateObject("roSGScreen").CreateScene(testNodeName) <> invalid
                    ? "WARNING: Test cases cannot be run in main scene."
                    for each testSuiteName in testSuiteNamesList
                        suiteStatObj = m.Logger.CreateSuiteStatistic(testSuiteName)
                        suiteStatObj.fail = 1
                        suiteStatObj.total = 1
                        m.Logger.AppendSuiteStatistic(totalStatObj, suiteStatObj)
                    end for
                else
                    params = [m, totalStatObj, testSuiteNamesList, m.GetIncludeFilter(), m.GetExcludeFilter()]
                    tmp = testNode.callFunc("TestRunner__RunNodeTests", params)
                    if tmp <> invalid then
                        totalStatObj = tmp
                    end if
                end if
            end if
        end for

        m.Logger.PrintStatistic(totalStatObj)
    end if

    if msg.Len() > 0 or totalStatObj.notFoundFunctionsMessage <> invalid then
        title = ""
        title += Chr(10) + "NOTE: If some your tests haven't been executed this might be due to outdated list of functions"
        title += Chr(10) + "To resolve this issue please execute" + Chr(10) + Chr(10)

        title += msg

        if totalStatObj.notFoundFunctionsMessage <> invalid then
            title += totalStatObj.notFoundFunctionsMessage
        end if
        ? title
    end if
end function

' ----------------------------------------------------------------
' Set testsDirectory property.
' ----------------------------------------------------------------
sub TestRunner__SetTestsDirectory(testsDirectory as string)
    m.testsDirectory = testsDirectory
end sub

' ----------------------------------------------------------------
' Set testFilePrefix property.
' ----------------------------------------------------------------
sub TestRunner__SetTestFilePrefix(testFilePrefix as string)
    m.testFilePrefix = testFilePrefix
end sub

' ----------------------------------------------------------------
' Set testSuitePrefix property.
' ----------------------------------------------------------------
sub TestRunner__SetTestSuitePrefix(testSuitePrefix as string)
    m.testSuitePrefix = testSuitePrefix
end sub

' ----------------------------------------------------------------
' Set testSuiteName property.
' ----------------------------------------------------------------
sub TestRunner__SetTestSuiteName(testSuiteName as string)
    m.testSuiteName = testSuiteName
end sub

' ----------------------------------------------------------------
' Set testCaseName property.
' ----------------------------------------------------------------
sub TestRunner__SetTestCaseName(testCaseName as string)
    m.testCaseName = testCaseName
end sub

' ----------------------------------------------------------------
' Set failFast property.
' ----------------------------------------------------------------
sub TestRunner__SetFailFast(failFast = false as boolean)
    m.failFast = failFast
end sub

' ----------------------------------------------------------------
' Builds an array of test suite objects.

' @param testSuiteNamesList (string, optional) array of names of test suite functions. If not passed, scans all test files for test suites

' @return An array of test suites.
' ----------------------------------------------------------------
function TestRunner__GetTestSuitesList(testSuiteNamesList = [] as object) as object
    result = []

    if testSuiteNamesList.count() > 0
        for each value in testSuiteNamesList
            if TF_Utils__IsString(value) then
                tmpTestSuiteFunction = TestRunner__getFunctionPointer(value)
                if tmpTestSuiteFunction <> invalid then
                    testSuite = tmpTestSuiteFunction()

                    if TF_Utils__IsAssociativeArray(testSuite)
                        result.Push(testSuite)
                    end if
                end if
                ' also we can get AA that will give source code and filePath
                ' Please be aware this is executed in render thread
            else if GetInterface(value, "ifAssociativeArray") <> invalid then
                ' try to use new approach
                testSuite = ScanFileForNewTests(value.code, value.filePath)
                if testSuite <> invalid then
                    result.push(testSuite)
                end if
            else if GetInterface(value, "ifFunction") <> invalid then
                result.Push(value)
            end if
        end for
    else
        testSuiteRegex = CreateObject("roRegex", "^(function|sub)\s(" + m.testSuitePrefix + m.testSuiteName + "[0-9a-z\_]*)\s*\(", "i")
        testFilesList = m.GetTestFilesList()

        for each filePath in testFilesList
            code = TF_Utils__AsString(ReadAsciiFile(filePath))

            if code <> ""
                foundTestSuite = false
                for each line in code.Tokenize(Chr(10))
                    line.Trim()

                    if testSuiteRegex.IsMatch(line)
                        testSuite = invalid
                        functionName = testSuiteRegex.Match(line).Peek()

                        tmpTestSuiteFunction = TestRunner__getFunctionPointer(functionName)
                        if tmpTestSuiteFunction <> invalid then
                            testSuite = tmpTestSuiteFunction()
                            if TF_Utils__IsAssociativeArray(testSuite)
                                result.Push(testSuite)
                                foundTestSuite = true
                            else
                                ' TODO check if we need this
                                ' using new mode
                                '                          testSuite = ScanFileForNewTests(code, filePath)

                                '                          exit for
                            end if
                        end if
                    end if
                end for
                if not foundTestSuite then
                    testSuite = ScanFileForNewTests(code, filePath)
                    if testSuite <> invalid then
                        result.push(testSuite)
                    end if
                end if
            end if
        end for
    end if

    return result
end function

function ScanFileForNewTests(souceCode, filePath)
    foundAnyTest = false
    testSuite = BaseTestSuite()

    allowedAnnotationsRegex = CreateObject("roRegex", "^'\s*@(test|beforeall|beforeeach|afterall|aftereach|repeatedtest|parameterizedtest|methodsource|ignore)\s*|\n", "i")
    voidFunctionRegex = CreateObject("roRegex", "^(function|sub)\s([a-z0-9A-Z_]*)\(\)", "i")
    anyArgsFunctionRegex = CreateObject("roRegex", "^(function|sub)\s([a-z0-9A-Z_]*)\(", "i")

    processors = {
        testSuite: testSuite
        filePath: filePath
        currentLine: ""
        annotations: {}

        functionName: ""

        tests: []

        beforeEachFunc: invalid
        beforeAllFunc: invalid

        AfterEachFunc: invalid
        AfterAllFunc: invalid

        isParameterizedTest: false
        MethodForArguments: ""
        executedParametrizedAdding: false

        test: sub()
            skipTest = m.doSkipTest(m.functionName)
            funcPointer = m.getFunctionPointer(m.functionName)
            m.tests.push({ name: m.functionName, pointer: funcPointer, skip: skipTest })
        end sub

        repeatedtest: sub()
            allowedAnnotationsRegex = CreateObject("roRegex", "^'\s*@(repeatedtest)\((\d*)\)", "i")
            annotationLine = m.annotations["repeatedtest"].line
            if allowedAnnotationsRegex.IsMatch(annotationLine)
                groups = allowedAnnotationsRegex.Match(annotationLine)
                numberOfLoops = groups[2]
                if numberOfLoops <> invalid and TF_Utils__AsInteger(numberOfLoops) > 0 then
                    numberOfLoops = TF_Utils__AsInteger(numberOfLoops)
                    funcPointer = m.getFunctionPointer(m.functionName)
                    for index = 1 to numberOfLoops
                        skipTest = m.doSkipTest(m.functionName)
                        text = " " + index.tostr() + " of " + numberOfLoops.tostr()
                        m.tests.push({ name: m.functionName + text, pointer: funcPointer, skip: skipTest })
                    end for
                end if
            else
                ? "WARNING: Wrong format of repeatedTest(numberOfRuns) "annotationLine
            end if
        end sub

        parameterizedTest: sub()
            m.processParameterizedTests()
        end sub

        methodSource: sub()
            m.processParameterizedTests()
        end sub

        processParameterizedTests: sub()
            ' add test if it was not added already
            if not m.executedParametrizedAdding
                if m.annotations.methodSource <> invalid and m.annotations.parameterizedTest <> invalid then
                    methodAnottation = m.annotations.methodSource.line

                    allowedAnnotationsRegex = CreateObject("roRegex", "^'\s*@(methodsource)\(" + Chr(34) + "([A-Za-z0-9_]*)" + Chr(34) + "\)", "i")

                    if allowedAnnotationsRegex.IsMatch(methodAnottation)
                        groups = allowedAnnotationsRegex.Match(methodAnottation)
                        providerFunction = groups[2]

                        providerFunctionPointer = m.getFunctionPointer(providerFunction)

                        if providerFunctionPointer <> invalid then
                            funcPointer = m.getFunctionPointer(m.functionName)

                            args = providerFunctionPointer()

                            index = 1
                            for each arg in args
                                skipTest = m.doSkipTest(m.functionName)
                                text = " " + index.tostr() + " of " + args.count().tostr()
                                m.tests.push({ name: m.functionName + text, pointer: funcPointer, arg: arg, hasArgs: true, skip: skipTest })
                                index++
                            end for
                        else
                            ? "WARNING: Cannot find function [" providerFunction "]"
                        end if
                    end if
                else
                    ? "WARNING: Wrong format of  @ParameterizedTest \n @MethodSource(providerFunctionName)"
                    ? "m.executedParametrizedAdding = "m.executedParametrizedAdding
                    ? "m.annotations.methodSource = "m.annotations.methodSource
                    ? "m.annotations.parameterizedTest = "m.annotations.parameterizedTest
                    ? ""
                end if
            end if
        end sub

        beforeEach: sub()
            m.beforeEachFunc = m.getFunctionPointer(m.functionName)
        end sub

        beforeAll: sub()
            m.beforeAllFunc = m.getFunctionPointer(m.functionName)
        end sub

        AfterEach: sub()
            m.AfterEachFunc = m.getFunctionPointer(m.functionName)
        end sub

        AfterAll: sub()
            m.AfterAllFunc = m.getFunctionPointer(m.functionName)
        end sub

        ignore: sub()
            funcPointer = m.getFunctionPointer(m.functionName)
            m.tests.push({ name: m.functionName, pointer: funcPointer, skip: true })
        end sub

        doSkipTest: function(name as string)
            includeFilter = []
            excludeFilter = []

            gthis = GetGlobalAA()
            if gthis.IncludeFilter <> invalid then includeFilter.append(gthis.IncludeFilter)
            if gthis.ExcludeFilter <> invalid then excludeFilter.append(gthis.ExcludeFilter)

            ' apply test filters
            skipTest = false
            ' skip test if it is found in exclude filter
            for each testName in excludeFilter
                if TF_Utils__IsNotEmptyString(testName) and LCase(testName.Trim()) = LCase(name.Trim())
                    skipTest = true
                    exit for
                end if
            end for

            ' skip test if it is not found in include filter
            if not skipTest and includeFilter.Count() > 0
                foundInIncludeFilter = false

                for each testName in includeFilter
                    if TF_Utils__IsNotEmptyString(testName) and LCase(testName) = LCase(name)
                        foundInIncludeFilter = true
                        exit for
                    end if
                end for

                skipTest = not foundInIncludeFilter
            end if

            return skipTest
        end function

        buildTests: sub()
            testSuite = m.testSuite
            testSuite.Name = m.filePath
            if m.beforeAllFunc <> invalid then testSuite.SetUp = m.beforeAllFunc
            if m.AfterAllFunc <> invalid then testSuite.TearDown = m.AfterAllFunc
            testSuite.IS_NEW_APPROACH = true

            for each test in m.tests
                ' Add tests to suite's tests collection
                arg = invalid
                hasArgs = false
                if test.hasArgs <> invalid then
                    arg = test.arg
                    hasArgs = true
                end if

                testSuite.addTest(test.name, test.pointer, m.beforeEachFunc, m.AfterEachFunc, arg, hasArgs, test.skip)
            end for
        end sub

        getFunctionPointer: TestRunner__getFunctionPointer
    }

    currentAnottations = []
    index = 0

    for each line in souceCode.Tokenize(Chr(10))
        line = line.Trim()
        if line <> "" ' skipping empty lines
            if allowedAnnotationsRegex.IsMatch(line)
                groups = allowedAnnotationsRegex.Match(line)
                anottationType = groups[1]
                if anottationType <> invalid and processors[anottationType] <> invalid then
                    currentAnottations.push(anottationType)
                    processors.annotations[anottationType] = { line: line, lineIndex: index }
                end if
            else
                if currentAnottations.count() > 0 then
                    isParametrized = anyArgsFunctionRegex.IsMatch(line)
                    properMap = { parameterizedtest: "", methodsource: "" }
                    for each availableAnottation in currentAnottations
                        isParametrized = isParametrized or properMap[availableAnottation] <> invalid
                    end for

                    if voidFunctionRegex.IsMatch(line) or isParametrized then
                        groups = voidFunctionRegex.Match(line)

                        if isParametrized then
                            groups = anyArgsFunctionRegex.Match(line)
                        end if
                        if groups[2] <> invalid then
                            processors.functionName = groups[2]
                            processors.currentLine = line

                            ' process all handlers
                            if isParametrized then processors.executedParametrizedAdding = false
                            for each availableAnottation in currentAnottations
                                processors[availableAnottation]()
                                if isParametrized then processors.executedParametrizedAdding = true
                            end for
                            currentAnottations = []
                            processors.annotations = {}
                            foundAnyTest = true
                        end if
                    else
                        ' invalidating annotation
                        ' TODO print message here that we skipped annotation
                        ? "WARNING: annotation " currentAnottations " isparametrized=" isParametrized " skipped at line " index ":[" line "]"
                        processors.annotations = {}
                        currentAnottations = []
                    end if
                end if
            end if
        end if
        index++
    end for

    processors.buildTests()

    if not foundAnyTest then
        testSuite = invalid
    end if
    return testSuite
end function

function TestRunner__getFunctionPointer(functionName as string) as dynamic
    result = invalid

    gthis = GetGlobalAA()
    if gthis.FunctionsList <> invalid then
        for each value in gthis.FunctionsList
            if Type(value) <> "" and LCase(Type(value)) <> "<uninitialized>" and GetInterface(value, "ifFunction") <> invalid and LCase(value.tostr()) = "function: " + LCase(functionName) then
                result = value
                exit for
            end if
        end for
    end if

    if LCase(Type(result)) = "<uninitialized>" then result = invalid
    if result = invalid then
        if gthis.notFoundFunctionPointerList = invalid then gthis.notFoundFunctionPointerList = []
        gthis.notFoundFunctionPointerList.push(functionName)
    end if

    return result
end function

sub TestRunner__SetFunctions(listOfFunctions as dynamic)
    gthis = GetGlobalAA()

    if gthis.FunctionsList = invalid then
        gthis.FunctionsList = []
    end if
    gthis.FunctionsList.append(listOfFunctions)
end sub

sub TestRunner__SetIncludeFilter(listOfFunctions as dynamic)
    gthis = GetGlobalAA()

    if gthis.IncludeFilter = invalid
        gthis.IncludeFilter = []
    end if

    if TF_Utils__IsArray(listOfFunctions)
        gthis.IncludeFilter.Append(listOfFunctions)
    else if TF_Utils__IsNotEmptyString(listOfFunctions)
        gthis.IncludeFilter.Append(listOfFunctions.Split(","))
    else
        ? "WARNING: Could not parse input parameters for Include Filter. Filter wont be applied."
    end if
end sub

function TestRunner__GetIncludeFilter()
    gthis = GetGlobalAA()

    if gthis.IncludeFilter = invalid
        gthis.IncludeFilter = []
    end if

    return gthis.IncludeFilter
end function

sub TestRunner__SetExcludeFilter(listOfFunctions as dynamic)
    gthis = GetGlobalAA()

    if gthis.ExcludeFilter = invalid
        gthis.ExcludeFilter = []
    end if

    if TF_Utils__IsArray(listOfFunctions)
        gthis.ExcludeFilter.Append(listOfFunctions)
    else if TF_Utils__IsNotEmptyString(listOfFunctions)
        gthis.ExcludeFilter.Append(listOfFunctions.Split(","))
    else
        ? "WARNING: Could not parse input parameters for Exclude Filter. Filter wont be applied."
    end if
end sub

function TestRunner__GetExcludeFilter()
    gthis = GetGlobalAA()

    if gthis.ExcludeFilter = invalid
        gthis.ExcludeFilter = []
    end if

    return gthis.ExcludeFilter
end function

' ----------------------------------------------------------------
' Scans all test files for test suite function names for a given test node.

' @param testNodeName (string) name of a test node, test suites for which are needed

' @return An array of test suite names.
' ----------------------------------------------------------------
function TestRunner__GetTestSuiteNamesList(testNodeName as string) as object
    result = []
    testSuiteRegex = CreateObject("roRegex", "^(function|sub)\s(" + m.testSuitePrefix + m.testSuiteName + "[0-9a-z\_]*)\s*\(", "i")
    testFilesList = m.GetTestFilesList(m.nodesTestDirectory, testNodeName)

    for each filePath in testFilesList
        code = TF_Utils__AsString(ReadAsciiFile(filePath))

        if code <> ""
            foundTestSuite = false
            for each line in code.Tokenize(Chr(10))
                line.Trim()

                if testSuiteRegex.IsMatch(line)
                    functionName = testSuiteRegex.Match(line).Peek()
                    result.Push(functionName)
                    foundTestSuite = true
                end if
            end for

            if not foundTestSuite then
                ' we cannot scan for new tests as we are not in proper scope
                ' so we need to pass some data so this can be executed in render thread
                result.push({ filePath: filePath, code: code })
            end if
        end if
    end for

    return result
end function

' ----------------------------------------------------------------
' Scan testsDirectory and all subdirectories for test files.

' @param testsDirectory (string, optional) A target directory with test files.
' @param testFilePrefix (string, optional) prefix, used by test files

' @return An array of test files.
' ----------------------------------------------------------------
function TestRunner__GetTestFilesList(testsDirectory = m.testsDirectory as string, testFilePrefix = m.testFilePrefix as string) as object
    result = []
    testsFileRegex = CreateObject("roRegex", "^(" + testFilePrefix + ")[0-9a-z\_]*\.brs$", "i")

    if testsDirectory <> ""
        fileSystem = CreateObject("roFileSystem")

        if m.isNodeMode
            ? string(2, Chr(10))
            ? string(10, "!!!")
            ? "Note if you crash here this means that we are in render thread and searching for tests"
            ? "Problem is that file naming is wrong"
            ? "check brs file name they should match pattern ""Test_ExactComponentName_anything.brs"""
            ? "In this case we were looking for "testFilePrefix
            ? string(10, "!!!") string(2, Chr(10))
        end if
        listing = fileSystem.GetDirectoryListing(testsDirectory)

        for each item in listing
            itemPath = testsDirectory + "/" + item
            itemStat = fileSystem.Stat(itemPath)

            if itemStat.type = "directory" then
                result.Append(m.getTestFilesList(itemPath, testFilePrefix))
            else if testsFileRegex.IsMatch(item) then
                result.Push(itemPath)
            end if
        end for
    end if

    return result
end function

' ----------------------------------------------------------------
' Scan nodesTestDirectory and all subdirectories for test nodes.

' @param nodesTestDirectory (string, optional) A target directory with test nodes.

' @return An array of test node names.
' ----------------------------------------------------------------
function TestRunner__GetTestNodesList(testsDirectory = m.nodesTestDirectory as string) as object
    result = []
    testsFileRegex = CreateObject("roRegex", "^(" + m.testFilePrefix + ")[0-9a-z\_]*\.xml$", "i")

    if testsDirectory <> ""
        fileSystem = CreateObject("roFileSystem")
        listing = fileSystem.GetDirectoryListing(testsDirectory)

        for each item in listing
            itemPath = testsDirectory + "/" + item
            itemStat = fileSystem.Stat(itemPath)

            if itemStat.type = "directory" then
                result.Append(m.getTestNodesList(itemPath))
            else if testsFileRegex.IsMatch(item) then
                result.Push(item.replace(".xml", ""))
            end if
        end for
    end if

    return result
end function

' ----------------------------------------------------------------
' Creates and runs test runner. Should be used ONLY within a node.

' @param params (array) parameters, passed from main thread, used to setup new test runner

' @return statistic object.
' ----------------------------------------------------------------
function TestRunner__RunNodeTests(params as object) as object
    this = params[0]

    statObj = params[1]
    testSuiteNamesList = params[2]

    Runner = TestRunner()

    Runner.SetTestSuitePrefix(this.testSuitePrefix)
    Runner.SetTestFilePrefix(this.testFilePrefix)
    Runner.SetTestSuiteName(this.testSuiteName)
    Runner.SetTestCaseName(this.testCaseName)
    Runner.SetFailFast(this.failFast)

    Runner.SetIncludeFilter(params[3])
    Runner.SetExcludeFilter(params[4])

    return Runner.Run(statObj, testSuiteNamesList)
end function
