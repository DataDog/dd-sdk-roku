' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__RumViewScope() as object
    this = BaseTestSuite()
    this.Name = "RumViewScope"

    this.addTest("WhenGetContext_ThenReturnsContext", RumViewScopeTest__WhenGetContext_ThenReturnsContext, RumViewScopeTest__SetUp, RumViewScopeTest__TearDown)
    this.addTest("WhenHandleStopViewEvent_ThenWriteViewUpdate", RumViewScopeTest__WhenHandleStopViewEvent_ThenWriteViewUpdate, RumViewScopeTest__SetUp, RumViewScopeTest__TearDown)
    this.addTest("WhenHandleStopViewEventTwice_ThenWriteViewEvent", RumViewScopeTest__WhenHandleStopViewEventTwice_ThenWriteViewEvent, RumViewScopeTest__SetUp, RumViewScopeTest__TearDown)
    this.addTest("WhenHandleStartViewEvent_ThenWriteViewEvent", RumViewScopeTest__WhenHandleStartViewEvent_ThenWriteViewEvent, RumViewScopeTest__SetUp, RumViewScopeTest__TearDown)
    this.addTest("WhenStopUnknownView_ThenDoNothing", RumViewScopeTest__WhenStopUnknownView_ThenDoNothing, RumViewScopeTest__SetUp, RumViewScopeTest__TearDown)

    return this
end function


sub RumViewScopeTest__SetUp()
    ' Mocks
    m.testSuite.mockWriter = CreateObject("roSGNode", "MockWriterTask")
    m.testSuite.mockParentScope = CreateObject("roSGNode", "MockRumScope")

    ' Fake data
    m.testSuite.fakeViewName = IG_GetString(16)
    m.testSuite.fakeViewUrl = "https://" + IG_GetString(32)

    ' Tested Task
    m.testSuite.startTimestamp& = datadogroku_getTimestamp()
    m.testSuite.testedScope = CreateObject("roSGNode", "datadogroku_RumViewScope")
    m.testSuite.testedScope.parentScope = m.testSuite.mockParentScope
    m.testSuite.testedScope.viewName = m.testSuite.fakeViewName
    m.testSuite.testedScope.viewUrl = m.testSuite.fakeViewUrl
end sub


sub RumViewScopeTest__TearDown()
    m.testSuite.Delete("mockWriter")
    m.testSuite.Delete("mockParentScope")
    m.testSuite.Delete("testedScope")
end sub

'----------------------------------------------------------------
' Given: a RumViewScope
'  When: requesting the rum context
'  Then: returns a rum context with parentScope's context plus sessionId
'----------------------------------------------------------------
function RumViewScopeTest__WhenGetContext_ThenReturnsContext() as string
    ' Given
    fakeApplicationId = IG_GetString(32)
    fakeServiceName = IG_GetString(32)
    fakeSessionId = IG_GetString(32)
    fakeParentContext = {
        applicationId: fakeApplicationId,
        serviceName: fakeServiceName,
        sessionId: fakeSessionId
    }
    m.mockParentScope.callFunc("stubCall", "getRumContext", {}, fakeParentContext)

    ' When
    context = m.testedScope.callFunc("getRumContext")

    ' Then
    return m.multipleAssertions([
        m.assertEqual(context.applicationId, fakeApplicationId),
        m.assertEqual(context.serviceName, fakeServiceName),
        m.assertEqual(context.sessionId, fakeSessionId),
        m.assertNotEmpty(context.viewId)
    ])
end function

'----------------------------------------------------------------
' Given: a RumViewScope
'  When: handling an event (stopView)
'  Then: writes a view event
'----------------------------------------------------------------
function RumViewScopeTest__WhenHandleStopViewEvent_ThenWriteViewUpdate() as string
    ' Given
    fakeApplicationId = IG_GetString(32)
    fakeApplicationVersion = IG_GetString(32)
    fakeServiceName = IG_GetString(32)
    fakeSessionId = IG_GetString(32)
    fakeParentContext = {
        applicationId: fakeApplicationId,
        serviceName: fakeServiceName,
        sessionId: fakeSessionId,
        applicationVersion: fakeApplicationVersion
    }
    m.mockParentScope.callFunc("stubCall", "getRumContext", {}, fakeParentContext)
    fakeEvent = { mock: "event", eventType: "stopView", viewName: m.fakeViewName, viewUrl: m.fakeViewUrl }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, m.mockWriter)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    if (updates.count() = 0)
        return "Expected writeEvent to be updated"
    end if
    viewEvent = ParseJson(updates[0])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 1),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 1),
        m.assertEqual(viewEvent.application.id, fakeApplicationId),
        m.assertBetween(viewEvent.date, m.startTimestamp&, m.startTimestamp& + 5),
        m.assertEqual(viewEvent.service, fakeServiceName),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, fakeApplicationVersion),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 1000000, 10000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function

'----------------------------------------------------------------
' Given: a RumViewScope
'  When: handling an event (stopView) twice
'  Then: write a view event but ignores the second stop
'----------------------------------------------------------------
function RumViewScopeTest__WhenHandleStopViewEventTwice_ThenWriteViewEvent() as string
    ' Given
    fakeApplicationId = IG_GetString(32)
    fakeApplicationVersion = IG_GetString(32)
    fakeServiceName = IG_GetString(32)
    fakeSessionId = IG_GetString(32)
    fakeParentContext = {
        applicationId: fakeApplicationId,
        serviceName: fakeServiceName,
        sessionId: fakeSessionId,
        applicationVersion: fakeApplicationVersion
    }
    m.mockParentScope.callFunc("stubCall", "getRumContext", {}, fakeParentContext)
    fakeEvent = { mock: "event", eventType: "stopView", viewName: m.fakeViewName, viewUrl: m.fakeViewUrl }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, m.mockWriter)
    m.testedScope.callFunc("handleEvent", fakeEvent, m.mockWriter)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent = ParseJson(updates[0])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 1),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 1),
        m.assertEqual(viewEvent.application.id, fakeApplicationId),
        m.assertBetween(viewEvent.date, m.startTimestamp&, m.startTimestamp& + 5),
        m.assertEqual(viewEvent.service, fakeServiceName),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, fakeApplicationVersion),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 1000000, 10000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function

'----------------------------------------------------------------
' Given: a RumViewScope
'  When: handling an event (stopView for an unknown view)
'  Then: do nothing
'----------------------------------------------------------------
function RumViewScopeTest__WhenStopUnknownView_ThenDoNothing() as string
    ' Given
    fakeEvent = { mock: "event", eventType: "stopView", viewName: m.fakeViewName + IG_GetString(8), viewUrl: m.fakeViewUrl + IG_GetString(8) }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, m.mockWriter)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 0)
    ])
end function

'----------------------------------------------------------------
' Given: a RumViewScope
'  When: handling an event (startView) twice
'  Then: write a view event and consider this view stopped
'----------------------------------------------------------------
function RumViewScopeTest__WhenHandleStartViewEvent_ThenWriteViewEvent() as string
    ' Given
    fakeApplicationId = IG_GetString(32)
    fakeApplicationVersion = IG_GetString(32)
    fakeServiceName = IG_GetString(32)
    fakeSessionId = IG_GetString(32)
    fakeParentContext = {
        applicationId: fakeApplicationId,
        serviceName: fakeServiceName,
        sessionId: fakeSessionId,
        applicationVersion: fakeApplicationVersion
    }
    m.mockParentScope.callFunc("stubCall", "getRumContext", {}, fakeParentContext)
    fakeEvent = { mock: "event", eventType: "startView", viewName: IG_GetString(32), viewUrl: IG_GetString(32) }

    ' When
    m.testedScope.callFunc("handleEvent", fakeEvent, m.mockWriter)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent = ParseJson(updates[0])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 1),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 1),
        m.assertEqual(viewEvent.application.id, fakeApplicationId),
        m.assertBetween(viewEvent.date, m.startTimestamp&, m.startTimestamp& + 5),
        m.assertEqual(viewEvent.service, fakeServiceName),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, fakeApplicationVersion),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 1000000, 10000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function
