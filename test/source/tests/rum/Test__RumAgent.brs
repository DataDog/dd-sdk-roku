' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__RumAgent() as object
    this = BaseTestSuite()
    this.Name = "RumAgent"

    this.addTest("WhenStartView_ThenDelegateToRumScope", RumAgentTest__WhenStartView_ThenDelegateToRumScope, RumAgentTest__SetUp, RumAgentTest__TearDown)
    this.addTest("WhenStopView_ThenDelegateToRumScope", RumAgentTest__WhenStopView_ThenDelegateToRumScope, RumAgentTest__SetUp, RumAgentTest__TearDown)

    return this
end function


sub RumAgentTest__SetUp()
    ' Mocks
    m.testSuite.mockUploader = CreateObject("roSGNode", "MockUploaderTask")
    m.testSuite.mockWriter = CreateObject("roSGNode", "MockWriterTask")
    m.testSuite.mockRumScope = CreateObject("roSGNode", "MockRumScope")

    ' Fake data
    m.testSuite.fakeEndpointHost = IG_GetString(10) + "." + IG_GetString(3)
    m.testSuite.fakeClientToken = "pub" + IG_GetString(32)
    m.testSuite.fakeApplicationId = IG_GetString(32)
    m.testSuite.fakeServiceName = IG_GetString(32)
    m.testSuite.fakeViewName = IG_GetString(32)
    m.testSuite.fakeViewUrl = IG_GetString(32)

    ' Tested Task
    m.testSuite.testedNode = CreateObject("roSGNode", "datadogroku_RumAgent")
    m.testSuite.testedNode.endpointHost = m.testSuite.fakeEndpointHost
    m.testSuite.testedNode.clientToken = m.testSuite.fakeClientToken
    m.testSuite.testedNode.applicationId = m.testSuite.fakeApplicationId
    m.testSuite.testedNode.serviceName = m.testSuite.fakeServiceName
    m.testSuite.testedNode.uploader = m.testSuite.mockUploader
    m.testSuite.testedNode.writer = m.testSuite.mockWriter
    m.testSuite.testedNode.rumScope = m.testSuite.mockRumScope
end sub


sub RumAgentTest__TearDown()
    m.testSuite.Delete("mockUploader")
    m.testSuite.Delete("mockWriter")
    m.testSuite.Delete("mockRumScope")
    m.testSuite.Delete("testedNode")
end sub

'----------------------------------------------------------------
' Given: a RumAgent
'  When: call the startView method
'  Then: delegates to the root RumScope
'----------------------------------------------------------------
function RumAgentTest__WhenStartView_ThenDelegateToRumScope() as string
    ' Given


    ' When
    m.testedNode.callFunc("startView", m.fakeViewName, m.fakeViewUrl)
    sleep(30)

    ' Then
    expectedArgs = { event: { eventType: "startView", viewName: m.fakeViewName, viewUrl: m.fakeViewUrl }, writer: m.mockWriter }
    return m.mockRumScope.callFunc("assertFunctionCalled", "handleEvent", expectedArgs)
end function

'----------------------------------------------------------------
' Given: a RumAgent
'  When: call the stopView method
'  Then: delegates to the root RumScope
'----------------------------------------------------------------
function RumAgentTest__WhenStopView_ThenDelegateToRumScope() as string
    ' Given


    ' When
    m.testedNode.callFunc("stopView", m.fakeViewName, m.fakeViewUrl)
    sleep(30)

    ' Then
    expectedArgs = { event: { eventType: "stopView", viewName: m.fakeViewName, viewUrl: m.fakeViewUrl }, writer: m.mockWriter }
    return m.mockRumScope.callFunc("assertFunctionCalled", "handleEvent", expectedArgs)
end function



