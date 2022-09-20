' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__RumSessionScope() as object
    this = BaseTestSuite()
    this.Name = "RumSessionScope"

    this.addTest("WhenGetContext_ThenReturnsContext", RumSessionScopeTest__WhenGetContext_ThenReturnsContext, RumSessionScopeTest__SetUp, RumSessionScopeTest__TearDown)
    this.addTest("WhenHandleStartViewEvent_ThenCreateViewScope", RumSessionScopeTest__WhenHandleStartViewEvent_ThenCreateViewScope, RumSessionScopeTest__SetUp, RumSessionScopeTest__TearDown)
    this.addTest("WhenHandleAnyEvent_ThenDelegateToViewScope", RumSessionScopeTest__WhenHandleAnyEvent_ThenDelegateToViewScope, RumSessionScopeTest__SetUp, RumSessionScopeTest__TearDown)
    this.addTest("WhenActiveViewNotActive_ThenDiscardIt", RumSessionScopeTest__WhenActiveViewNotActive_ThenDiscardIt, RumSessionScopeTest__SetUp, RumSessionScopeTest__TearDown)
    ' TODO RUMM-2478 Test session update logic

    return this
end function


sub RumSessionScopeTest__SetUp()
    ' Mocks
    m.testSuite.mockWriter = CreateObject("roSGNode", "MockWriterTask")
    m.testSuite.mockParentScope = CreateObject("roSGNode", "MockRumScope")

    ' Fake data

    ' Tested Task
    m.testSuite.testedScope = CreateObject("roSGNode", "datadogroku_RumSessionScope")
    m.testSuite.testedScope.parentScope = m.testSuite.mockParentScope
end sub


sub RumSessionScopeTest__TearDown()
    m.testSuite.Delete("mockWriter")
    m.testSuite.Delete("mockParentScope")
    m.testSuite.Delete("testedScope")
end sub

'----------------------------------------------------------------
' Given: a RumSessionScope
'  When: requesting the rum context
'  Then: returns a rum context with parentScope's context plus sessionId
'----------------------------------------------------------------
function RumSessionScopeTest__WhenGetContext_ThenReturnsContext() as string
    ' Given
    fakeApplicationId = IG_GetString(32)
    fakeServiceName = IG_GetString(32)
    fakeVersion = IG_GetString(16)
    fakeParentContext = {
        applicationId: fakeApplicationId,
        serviceName: fakeServiceName,
        applicationVersion: fakeVersion
    }
    m.mockParentScope.callFunc("stubCall", "getRumContext", {}, fakeParentContext)

    ' When
    context = m.testedScope.callFunc("getRumContext")

    ' Then
    return m.multipleAssertions([
        m.assertEqual(context.applicationId, fakeApplicationId),
        m.assertEqual(context.serviceName, fakeServiceName),
        m.assertEqual(context.applicationVersion, fakeVersion),
        m.assertNotEmpty(context.sessionId)
    ])
end function

'----------------------------------------------------------------
' Given: a RumSessionScope
'  When: calling handleEvent (type=startView)
'  Then: create a child View scope
'----------------------------------------------------------------
function RumSessionScopeTest__WhenHandleStartViewEvent_ThenCreateViewScope() as string
    ' Given
    fakeViewName = IG_GetString(16)
    fakeViewUrl = "https://" + IG_GetString(16)
    fakeEvent = { mock: "event", eventType: "startView", viewName: fakeViewName, viewUrl: fakeViewUrl }
    fakeWriter = { mock: "writer" }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, fakeWriter)

    ' Then
    activeView = m.testedScope.activeView
    return m.multipleAssertions([
        m.assertNotInvalid(activeView),
        m.assertEqual(activeView.subtype(), "datadogroku_RumViewScope"),
        m.assertEqual(activeView.viewName, fakeViewName),
        m.assertEqual(activeView.viewUrl, fakeViewUrl)
    ])
end function

'----------------------------------------------------------------
' Given: a RumSessionScope
'  When: calling handleEvent (type=any)
'  Then: delegates the event to the child scope
'----------------------------------------------------------------
function RumSessionScopeTest__WhenHandleAnyEvent_ThenDelegateToViewScope() as string
    ' Given
    mockScope = CreateObject("roSGNode", "MockRumScope")
    mockScope.callFunc("stubCall", "isActive", {}, true)
    m.testedScope.activeView = mockScope
    fakeEvent = { mock: "event", eventType: "any" }
    fakeWriter = { mock: "writer" }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, fakeWriter)

    ' Then
    return m.multipleAssertions([
        m.assertEqual(m.testedScope.activeView.subtype(), "MockRumScope"),
        mockScope.callFunc("assertFunctionCalled", "handleEvent", { event: fakeEvent, writer: fakeWriter })
    ])
end function


'----------------------------------------------------------------
' Given: a RumSessionScope
'  When: calling handleEvent (type=any) and activeView.isActive() returns false
'  Then: discard the activeView
'----------------------------------------------------------------
function RumSessionScopeTest__WhenActiveViewNotActive_ThenDiscardIt() as string
    ' Given
    mockScope = CreateObject("roSGNode", "MockRumScope")
    m.testedScope.activeView = mockScope
    fakeEvent = { mock: "event", eventType: "any" }
    fakeWriter = { mock: "writer" }
    mockScope.callFunc("stubCall", "isActive", {}, false)

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, fakeWriter)

    ' Then
    return m.multipleAssertions([
        m.assertEqual(m.testedScope.activeView, invalid),
        mockScope.callFunc("assertFunctionCalled", "handleEvent", { event: fakeEvent, writer: fakeWriter })
    ])
end function
