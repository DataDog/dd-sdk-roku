' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__RumApplicationScope() as object
    this = BaseTestSuite()
    this.Name = "RumApplicationScope"

    this.addTest("WhenHandleEvent_ThenCreatesSessionScope", RumApplicationScopeTest__WhenHandleEvent_ThenCreatesSessionScope, RumApplicationScopeTest__SetUp, RumApplicationScopeTest__TearDown)
    this.addTest("WhenGetContext_ThenReturnsContext", RumApplicationScopeTest__WhenGetContext_ThenReturnsContext, RumApplicationScopeTest__SetUp, RumApplicationScopeTest__TearDown)
    this.addTest("WhenHandleEvent_ThenDelegateToSessionScope", RumApplicationScopeTest__WhenHandleEvent_ThenDelegateToSessionScope, RumApplicationScopeTest__SetUp, RumApplicationScopeTest__TearDown)

    return this
end function


sub RumApplicationScopeTest__SetUp()
    ' Mocks
    m.testSuite.mockWriter = CreateObject("roSGNode", "MockWriterTask")

    ' Fake data
    m.testSuite.fakeApplicationId = IG_GetString(32)
    m.testSuite.fakeServiceName = IG_GetString(32)

    ' Tested Task
    m.testSuite.testedScope = CreateObject("roSGNode", "datadogroku_RumApplicationScope")
    m.testSuite.testedScope.applicationId = m.testSuite.fakeApplicationId
    m.testSuite.testedScope.serviceName = m.testSuite.fakeServiceName
end sub


sub RumApplicationScopeTest__TearDown()
    m.testSuite.Delete("mockWriter")
    m.testSuite.Delete("testedScope")
end sub

'----------------------------------------------------------------
' Given: a RumApplicationScope
'  When: handle any event
'  Then: creates a child session scope
'----------------------------------------------------------------
function RumApplicationScopeTest__WhenHandleEvent_ThenCreatesSessionScope() as string
    ' Given
    fakeEvent = { mock: "event" }
    fakeWriter = { mock: "writer" }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, fakeWriter)

    ' Then
    sessionScope = m.testedScope.sessionScope
    return m.assertEqual(sessionScope.subtype(), "datadogroku_RumSessionScope")
end function

'----------------------------------------------------------------
' Given: a RumApplicationScope
'  When: requesting the rum context
'  Then: returns a rum context with applicationId and serviceName
'----------------------------------------------------------------
function RumApplicationScopeTest__WhenGetContext_ThenReturnsContext() as string
    ' Given

    ' When
    context = m.testedScope.callFunc("getRumContext")

    ' Then
    return m.multipleAssertions([
        m.assertEqual(context.applicationId, m.fakeApplicationId),
        m.assertEqual(context.serviceName, m.fakeServiceName),
        m.assertEqual(context.applicationVersion, "4.8.15")
    ])
end function

'----------------------------------------------------------------
' Given: a RumApplicationScope
'  When: calling handleEvent
'  Then: delegates the event to the child scope
'----------------------------------------------------------------
function RumApplicationScopeTest__WhenHandleEvent_ThenDelegateToSessionScope() as string
    ' Given
    mockScope = CreateObject("roSGNode", "MockRumScope")
    m.testedScope.sessionScope = mockScope
    fakeEvent = { mock: "event" }
    fakeWriter = { mock: "writer" }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, fakeWriter)

    ' Then
    return m.multipleAssertions([
        mockScope.callFunc("assertFunctionCalled", "handleEvent", { event: fakeEvent, writer: fakeWriter })
    ])
end function