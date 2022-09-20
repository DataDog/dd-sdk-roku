' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__WriterTask() as object
    this = BaseTestSuite()
    this.Name = "WriterTask"

    this.addTest("WhenFirstWriteEvent_ThenCreateNewFile", WriterTaskTest__WhenFirstWriteEvent_ThenCreateNewFile, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenEvent_ThenAppendEmptyFile", WriterTaskTest__WhenEvent_ThenAppendEmptyFile, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenEvent_ThenAppendNonEmptyFile", WriterTaskTest__WhenEvent_ThenAppendNonEmptyFile, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenMultipleEvents_ThenAppendFile", WriterTaskTest__WhenMultipleEvents_ThenAppendFile, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenFileTooLarge_ThenWriteInNewFile", WriterTaskTest__WhenFileTooLarge_ThenWriteInNewFile, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenFileTooOld_ThenWriteInNewFile", WriterTaskTest__WhenFileTooOld_ThenWriteInNewFile, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenEmptyEvent_ThenDoNothing", WriterTaskTest__WhenEmptyEvent_ThenDoNothing, WriterTaskTest__SetUp, WriterTaskTest__TearDown)
    this.addTest("WhenEmptyEventWithPreviousFile_ThenDoNothing", WriterTaskTest__WhenEmptyEventWithPreviousFile_ThenDoNothing, WriterTaskTest__SetUp, WriterTaskTest__TearDown)

    return this
end function


sub WriterTaskTest__SetUp()
    ' Mocks

    ' Fake data
    fakeTrackType = IG_GetString(10)
    m.testSuite.fakeSeparator = IG_GetString(2)


    m.testSuite.folderPath = datadogroku_trackFolderPath(fakeTrackType)
    datadogroku_mkdirs(m.testSuite.folderPath)

    ' Tested Node
    m.testSuite.testedTask = CreateObject("roSGNode", "datadogroku_WriterTask")
    m.testSuite.testedTask.trackType = fakeTrackType
    m.testSuite.testedTask.payloadSeparator = m.testSuite.fakeSeparator

end sub


sub WriterTaskTest__TearDown()
    m.testSuite.testedTask.control = "STOP"
    m.testSuite.Delete("testedTask")
    createObject("roFileSystem").Delete(m.testSuite.folderPath)
end sub

'----------------------------------------------------------------
' Given: a writer node, no existing file
'  When: sending an event (as string)
'  Then: a file is created with the given data
'----------------------------------------------------------------
function WriterTaskTest__WhenFirstWriteEvent_ThenCreateNewFile() as string
    ' Given
    fakeEvent = IG_GetString(128)

    ' When
    m.testedTask.writeEvent = fakeEvent
    sleep(15)

    ' Then
    datadogroku_logWarning("rolling assertions")
    filenames = ListDir(m.folderPath)
    if (filenames.count() = 0)
        return "Expected writer to create a file in folder " + m.folderPath
    else if (filenames.count() > 1)
        return "Expected writer to create only one file in folder " + m.folderPath
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.assertEqual(content, fakeEvent)
end function

'----------------------------------------------------------------
' Given: a writer node, an existing empty file
'  When: sending an event (as string)
'  Then: the file is appended with the given data
'----------------------------------------------------------------
function WriterTaskTest__WhenEvent_ThenAppendEmptyFile() as string
    ' Given
    fakeEvent = IG_GetString(128)
    timestamp& = datadogroku_getTimestamp()
    filePath = m.folderPath + "/" + timestamp&.toStr()
    WriteAsciiFile(filePath, "")

    ' When
    m.testedTask.writeEvent = fakeEvent
    sleep(15)

    ' Then
    filenames = ListDir(m.folderPath)
    if (filenames.count() <> 1)
        return "Expected writer to reuse the existing file"
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.multipleAssertions([
        m.assertEqual(filenames[0], timestamp&.toStr()),
        m.assertEqual(content, fakeEvent)
    ])
end function

'----------------------------------------------------------------
' Given: a writer node, an existing non-empty file
'  When: sending an event (as string)
'  Then: the file is appended with a separator and the given data
'----------------------------------------------------------------
function WriterTaskTest__WhenEvent_ThenAppendNonEmptyFile() as string
    ' Given
    previousData = IG_GetString(128)
    fakeEvent = IG_GetString(128)
    timestamp& = datadogroku_getTimestamp()
    filePath = m.folderPath + "/" + timestamp&.toStr()
    WriteAsciiFile(filePath, previousData)

    ' When
    m.testedTask.writeEvent = fakeEvent
    sleep(15)

    ' Then
    filenames = ListDir(m.folderPath)
    if (filenames.count() <> 1)
        return "Expected writer to reuse the existing file"
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.multipleAssertions([
        m.assertEqual(filenames[0], timestamp&.toStr()),
        m.assertEqual(content, previousData + m.fakeSeparator + fakeEvent)
    ])
end function

'----------------------------------------------------------------
' Given: a writer node, an existing non-empty file
'  When: sending multiple event (as string)
'  Then: the file is appended with a separator between each events
'----------------------------------------------------------------
function WriterTaskTest__WhenMultipleEvents_ThenAppendFile() as string
    ' Given
    fakeEvents = [IG_GetString(128), IG_GetString(128), IG_GetString(128), IG_GetString(128), IG_GetString(128)]
    timestamp& = datadogroku_getTimestamp()
    filePath = m.folderPath + "/" + timestamp&.toStr()
    WriteAsciiFile(filePath, "")

    ' When
    for each fakeEvent in fakeEvents
        m.testedTask.writeEvent = fakeEvent
    end for
    sleep(50)

    ' Then
    datadogroku_logWarning("rolling assertions")
    filenames = ListDir(m.folderPath)
    if (filenames.count() <> 1)
        return "Expected writer to reuse the existing file"
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.multipleAssertions([
        m.assertEqual(filenames[0], timestamp&.toStr()),
        m.assertEqual(content, fakeEvents[0] + m.fakeSeparator + fakeEvents[1] + m.fakeSeparator + fakeEvents[2] + m.fakeSeparator + fakeEvents[3] + m.fakeSeparator + fakeEvents[4])
    ])
end function

'----------------------------------------------------------------
' Given: a writer node, an existing non-empty large file
'  When: sending an event (as string)
'  Then: the file is appended in a new file
'----------------------------------------------------------------
function WriterTaskTest__WhenFileTooLarge_ThenWriteInNewFile() as string
    ' Given
    fakePreviousEvent = IG_GetString(128)
    while (fakePreviousEvent.Len() < 16384)
        fakePreviousEvent += IG_GetString(128)
    end while
    fakeEvent = IG_GetString(128)
    timestamp& = datadogroku_getTimestamp()
    filePath = m.folderPath + "/" + timestamp&.toStr()
    WriteAsciiFile(filePath, fakePreviousEvent)

    ' When
    m.testedTask.writeEvent = fakeEvent
    sleep(15)

    ' Then
    filenames = ListDir(m.folderPath)
    if (filenames.count() <> 2)
        return "Expected writer to create a new file in addition to existing one"
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.multipleAssertions([
        m.assertNotEqual(filenames[0], timestamp&.toStr()),
        m.assertEqual(content, fakeEvent)
    ])
end function

'----------------------------------------------------------------
' Given: a writer node, an existing "old"" file
'  When: sending an event (as string)
'  Then: the file is appended in a new file
'----------------------------------------------------------------
function WriterTaskTest__WhenFileTooOld_ThenWriteInNewFile() as string
    ' Given
    previousData = IG_GetString(128)
    fakeEvent = IG_GetString(128)
    timestamp& = datadogroku_getTimestamp() - 30000
    filePath = m.folderPath + "/" + timestamp&.toStr()
    WriteAsciiFile(filePath, previousData)

    ' When
    m.testedTask.writeEvent = fakeEvent
    sleep(15)

    ' Then
    filenames = ListDir(m.folderPath)
    if (filenames.count() <> 2)
        return "Expected writer to create a new file in addition to existing one"
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.multipleAssertions([
        m.assertNotEqual(filenames[0], timestamp&.toStr()),
        m.assertEqual(content, fakeEvent)
    ])
end function

'----------------------------------------------------------------
' Given: a writer node, no previous file
'  When: sending an empty event (as string)
'  Then: the file is appended in a new file
'----------------------------------------------------------------
function WriterTaskTest__WhenEmptyEvent_ThenDoNothing() as string
    ' Given

    ' When
    m.testedTask.writeEvent = ""
    sleep(15)

    ' Then
    filenames = ListDir(m.folderPath)
    return m.multipleAssertions([
        m.assertEqual(filenames.count(), 0, "Expected write to ignore empty event")
    ])
end function

'----------------------------------------------------------------
' Given: a writer node, an existing file
'  When: sending an empty event (as string)
'  Then: the file is appended in a new file
'----------------------------------------------------------------
function WriterTaskTest__WhenEmptyEventWithPreviousFile_ThenDoNothing() as string
    ' Given
    timestamp& = datadogroku_getTimestamp()
    filePath = m.folderPath + "/" + timestamp&.toStr()
    previousData = IG_GetString(128)
    WriteAsciiFile(filePath, previousData)

    ' When
    m.testedTask.writeEvent = ""
    sleep(15)

    ' Then
    filenames = ListDir(m.folderPath)
    if (filenames.count() <> 1)
        return "Expected writer to ignore empty"
    end if
    content = ReadAsciiFile(m.folderPath + "/" + filenames[0])
    return m.multipleAssertions([
        m.assertEqual(filenames[0], timestamp&.toStr()),
        m.assertEqual(content, previousData)
    ])
end function
