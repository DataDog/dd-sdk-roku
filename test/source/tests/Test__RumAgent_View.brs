' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__RumAgentView() as object
    this = BaseTestSuite()
    this.Name = "RumAgent [View]"

    this.addTest("WhenStartView_ThenWriteViewEvent", RumAgentViewTest__WhenStartView_ThenWriteViewEvent, RumAgentViewTest__SetUp, RumAgentViewTest__TearDown)
    this.addTest("WhenStartAndStopView_ThenWriteViewEvent", RumAgentViewTest__WhenStartAndStopView_ThenWriteViewEvent, RumAgentViewTest__SetUp, RumAgentViewTest__TearDown)
    this.addTest("WhenStopView_ThenDoNothing", RumAgentViewTest__WhenStopView_ThenDoNothing, RumAgentViewTest__SetUp, RumAgentViewTest__TearDown)
    this.addTest("WhenStartAndStopViewTwice_ThenWriteViewEvent", RumAgentViewTest__WhenStartAndStopViewTwice_ThenWriteViewEvent, RumAgentViewTest__SetUp, RumAgentViewTest__TearDown)
    this.addTest("WhenStopUnknownView_ThenDoNothing", RumAgentViewTest__WhenStopUnknownView_ThenDoNothing, RumAgentViewTest__SetUp, RumAgentViewTest__TearDown)
    this.addTest("WhenStartTwoViews_ThenWriteTwoViewEvent", RumAgentViewTest__WhenStartTwoViews_ThenWriteTwoViewEvent, RumAgentViewTest__SetUp, RumAgentViewTest__TearDown)

    return this
end function


sub RumAgentViewTest__SetUp()
    ' Mocks
    m.testSuite.mockUploader = CreateObject("roSGNode", "MockUploaderTask")
    m.testSuite.mockWriter = CreateObject("roSGNode", "MockWriterTask")

    ' Fake data
    m.testSuite.fakeEndpointHost = IG_GetString(10) + "." + IG_GetString(3)
    m.testSuite.fakeClientToken = "pub" + IG_GetString(32)
    m.testSuite.fakeApplicationId = IG_GetString(32)
    m.testSuite.fakeService = IG_GetString(32)
    m.testSuite.fakeViewName = IG_GetString(32)
    m.testSuite.fakeViewUrl = IG_GetString(32)

    ' Tested Task
    m.testSuite.testedNode = CreateObject("roSGNode", "datadogroku_RumAgent")
    m.testSuite.testedNode.endpointHost = m.testSuite.fakeEndpointHost
    m.testSuite.testedNode.clientToken = m.testSuite.fakeClientToken
    m.testSuite.testedNode.applicationId = m.testSuite.fakeApplicationId
    m.testSuite.testedNode.service = m.testSuite.fakeService
    m.testSuite.testedNode.uploader = m.testSuite.mockUploader
    m.testSuite.testedNode.writer = m.testSuite.mockWriter
end sub


sub RumAgentViewTest__TearDown()
    m.testSuite.Delete("mockUploader")
    m.testSuite.Delete("mockWriter")
    m.testSuite.Delete("testedNode")
end sub


'----------------------------------------------------------------
' Given: a RumAgent
'  When: starting view
'  Then: write a view event
'----------------------------------------------------------------
function RumAgentViewTest__WhenStartView_ThenWriteViewEvent() as string
    ' Given
    startTimestamp& = datadogroku_getTimestamp()

    ' When
    m.testedNode.callFunc("startView", m.fakeViewName, m.fakeViewUrl)
    sleep(30)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent = ParseJson(updates[0])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 1),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 1),
        m.assertEqual(viewEvent.application.id, m.fakeApplicationId),
        m.assertBetween(viewEvent.date, startTimestamp&, startTimestamp& + 5),
        m.assertEqual(viewEvent.service, m.fakeService),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, "4.8.15"),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 0, 5000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function

'----------------------------------------------------------------
' Given: a RumAgent
'  When: starting then stopping a view
'  Then: write a view event
'----------------------------------------------------------------
function RumAgentViewTest__WhenStartAndStopView_ThenWriteViewEvent() as string
    ' Given
    startTimestamp& = datadogroku_getTimestamp()

    ' When
    m.testedNode.callFunc("startView", m.fakeViewName, m.fakeViewUrl)
    sleep(100)
    m.testedNode.callFunc("stopView", m.fakeViewName, m.fakeViewUrl)
    sleep(30)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent = ParseJson(updates[1])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 2),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 2),
        m.assertEqual(viewEvent.application.id, m.fakeApplicationId),
        m.assertBetween(viewEvent.date, startTimestamp&, startTimestamp& + 5),
        m.assertEqual(viewEvent.service, m.fakeService),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, "4.8.15"),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 100000000, 115000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function

'----------------------------------------------------------------
' Given: a RumAgent
'  When: starting a view, then stopping an unknwn view
'  Then: write a view event
'----------------------------------------------------------------
function RumAgentViewTest__WhenStopUnknownView_ThenDoNothing() as string
    ' Given
    startTimestamp& = datadogroku_getTimestamp()

    ' When
    m.testedNode.callFunc("startView", m.fakeViewName, m.fakeViewUrl)
    sleep(100)
    m.testedNode.callFunc("stopView", m.fakeViewName + "nope", m.fakeViewUrl + "nope")
    sleep(30)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent = ParseJson(updates[0])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 1),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 1),
        m.assertEqual(viewEvent.application.id, m.fakeApplicationId),
        m.assertBetween(viewEvent.date, startTimestamp&, startTimestamp& + 5),
        m.assertEqual(viewEvent.service, m.fakeService),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, "4.8.15"),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 0, 5000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function

'----------------------------------------------------------------
' Given: a RumAgent
'  When: starting then stopping a view twice
'  Then: write a view event but ignores the second stop
'----------------------------------------------------------------
function RumAgentViewTest__WhenStartAndStopViewTwice_ThenWriteViewEvent() as string
    ' Given
    startTimestamp& = datadogroku_getTimestamp()

    ' When
    m.testedNode.callFunc("startView", m.fakeViewName, m.fakeViewUrl)
    sleep(100)
    m.testedNode.callFunc("stopView", m.fakeViewName, m.fakeViewUrl)
    sleep(100)
    m.testedNode.callFunc("stopView", m.fakeViewName, m.fakeViewUrl)
    sleep(30)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent = ParseJson(updates[1])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 2),
        m.assertNotInvalid(viewEvent),
        m.assertEqual(viewEvent._dd.document_version, 2),
        m.assertEqual(viewEvent.application.id, m.fakeApplicationId),
        m.assertBetween(viewEvent.date, startTimestamp&, startTimestamp& + 5),
        m.assertEqual(viewEvent.service, m.fakeService),
        m.assertEqual(viewEvent.session.has_replay, false),
        m.assertNotEmpty(viewEvent.session.id),
        m.assertEqual(viewEvent.session.type, "user"),
        m.assertEqual(viewEvent.source, "roku"),
        m.assertEqual(viewEvent.type, "view"),
        m.assertEqual(viewEvent.version, "4.8.15"),
        m.assertNotEmpty(viewEvent.view.id),
        m.assertEqual(viewEvent.view.name, m.fakeViewName),
        m.assertBetween(viewEvent.view.time_spent, 100000000, 115000000),
        m.assertEqual(viewEvent.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function

'----------------------------------------------------------------
' Given: a RumAgent
'  When: stopping a view (not started)
'  Then: does nothing
'----------------------------------------------------------------
function RumAgentViewTest__WhenStopView_ThenDoNothing() as string
    ' When
    m.testedNode.callFunc("stopView", m.fakeViewName, m.fakeViewUrl)
    sleep(30)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    return m.assertEqual(updates.count(), 0)
end function



'----------------------------------------------------------------
' Given: a RumAgent
'  When: starting a view then starting another one
'  Then: write a view event for both
'----------------------------------------------------------------
function RumAgentViewTest__WhenStartTwoViews_ThenWriteTwoViewEvent() as string
    ' Given
    startTimestamp& = datadogroku_getTimestamp()
    fakeViewName2 = IG_GetString(32)
    fakeViewUrl2 = IG_GetString(32)

    ' When
    m.testedNode.callFunc("startView", m.fakeViewName, m.fakeViewUrl)
    sleep(100)
    m.testedNode.callFunc("startView", fakeViewName2, fakeViewUrl2)
    sleep(30)

    ' Then
    updates = m.mockWriter.callFunc("getFieldUpdates", "writeEvent")
    viewEvent1 = ParseJson(updates[1])
    viewEvent2 = ParseJson(updates[2])
    return m.multipleAssertions([
        m.assertEqual(updates.count(), 3),
        m.assertNotInvalid(viewEvent1),
        m.assertEqual(viewEvent1._dd.document_version, 2),
        m.assertEqual(viewEvent1.application.id, m.fakeApplicationId),
        m.assertBetween(viewEvent1.date, startTimestamp&, startTimestamp& + 5),
        m.assertEqual(viewEvent1.service, m.fakeService),
        m.assertEqual(viewEvent1.session.has_replay, false),
        m.assertNotEmpty(viewEvent1.session.id),
        m.assertEqual(viewEvent1.session.type, "user"),
        m.assertEqual(viewEvent1.source, "roku"),
        m.assertEqual(viewEvent1.type, "view"),
        m.assertEqual(viewEvent1.version, "4.8.15"),
        m.assertNotEmpty(viewEvent1.view.id),
        m.assertEqual(viewEvent1.view.name, m.fakeViewName),
        m.assertBetween(viewEvent1.view.time_spent, 100000000, 115000000),
        m.assertEqual(viewEvent1.view.url, m.fakeViewUrl),
        ' TODO RUMM-2435 assert action count, resource count, error count
        m.assertNotInvalid(viewEvent2),
        m.assertEqual(viewEvent2._dd.document_version, 1),
        m.assertEqual(viewEvent2.application.id, m.fakeApplicationId),
        m.assertBetween(viewEvent2.date, startTimestamp& + 100, startTimestamp& + 200),
        m.assertEqual(viewEvent2.service, m.fakeService),
        m.assertEqual(viewEvent2.session.has_replay, false),
        m.assertNotEmpty(viewEvent2.session.id),
        m.assertEqual(viewEvent2.session.type, "user"),
        m.assertEqual(viewEvent2.source, "roku"),
        m.assertEqual(viewEvent2.type, "view"),
        m.assertEqual(viewEvent2.version, "4.8.15"),
        m.assertNotEmpty(viewEvent2.view.id),
        m.assertEqual(viewEvent2.view.name, fakeViewName2),
        m.assertBetween(viewEvent2.view.time_spent, 0, 5000000),
        m.assertEqual(viewEvent2.view.url, fakeViewUrl2),
        ' TODO RUMM-2435 assert action count, resource count, error count
    ])
end function
