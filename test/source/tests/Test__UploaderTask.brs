' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
' * UploaderTask: a background loop checking for files available for upload;
' * When a file is ready, it is uploaded, and upon success deleted from disk.
'----------------------------------------------------------------

'*****************************************************************


'----------------------------------------------------------------
' Main setup function.
' @return (object) a configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__UploaderTask() as object
    this = BaseTestSuite()
    this.Name = "UploaderTask"

    this.addTest("WhenInit_UploadsExistingFile_202", UploaderTaskTest__WhenInit_UploadsExistingFile_202, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_400", UploaderTaskTest__WhenInit_UploadsExistingFile_400, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_401", UploaderTaskTest__WhenInit_UploadsExistingFile_401, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_403", UploaderTaskTest__WhenInit_UploadsExistingFile_403, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_408", UploaderTaskTest__WhenInit_UploadsExistingFile_408, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_413", UploaderTaskTest__WhenInit_UploadsExistingFile_413, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_429", UploaderTaskTest__WhenInit_UploadsExistingFile_429, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_4xx", UploaderTaskTest__WhenInit_UploadsExistingFile_4xx, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_500", UploaderTaskTest__WhenInit_UploadsExistingFile_500, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_503", UploaderTaskTest__WhenInit_UploadsExistingFile_503, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_UploadsExistingFile_5xx", UploaderTaskTest__WhenInit_UploadsExistingFile_5xx, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)
    this.addTest("WhenInit_IgnoreRecentFile", UploaderTaskTest__WhenInit_IgnoreRecentFile, UploaderTaskTest__SetUp, UploaderTaskTest__TearDown)

    return this
end function


sub UploaderTaskTest__SetUp()
    ' Mocks
    m.testSuite.mockNetworkClient = CreateObject("roSGNode", "MockNetworkClient")

    ' Fake data
    m.testSuite.fakeTrackType = IG_GetString(10)
    m.testSuite.fakeEndpointHost = IG_GetString(10) + "." + IG_GetString(3)
    m.testSuite.fakeClientToken = "pub" + IG_GetString(32)
    m.testSuite.fakeWaitPeriodMs = 50

    ' Tested Task
    m.testSuite.testedTask = CreateObject("roSGNode", "datadogroku_UploaderTask")
    m.testSuite.testedTask.trackType = m.testSuite.fakeTrackType
    m.testSuite.testedTask.endpointHost = m.testSuite.fakeEndpointHost
    m.testSuite.testedTask.clientToken = m.testSuite.fakeClientToken
    m.testSuite.testedTask.waitPeriodMs = m.testSuite.fakeWaitPeriodMs
    m.testSuite.testedTask.networkClient = m.testSuite.mockNetworkClient
    ' sleep(10)
end sub


sub UploaderTaskTest__TearDown()
    m.testSuite.testedTask.control = "STOP"
    m.testSuite.Delete("mockNetworkClient")
    m.testSuite.Delete("testedTask")
end sub

'----------------------------------------------------------------
' Given: an uploader and an uploadable file
'  When: waiting for the loop to run
'  Then: the file is uploaded and deleted
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_202() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 202)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertFalse(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to be deleted")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, an invalid file (400)
'  When: waiting for the loop to run
'  Then: the file is uploaded and deleted
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_400() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 400)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertFalse(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to be deleted")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, an invalid token (401)
'  When: waiting for the loop to run
'  Then: the file is uploaded and deleted
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_401() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 401)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertFalse(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to be deleted")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, an invalid token (403)
'  When: waiting for the loop to run
'  Then: the file is uploaded and deleted
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_403() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 403)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertFalse(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to be deleted")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, an slow network (408)
'  When: waiting for the loop to run
'  Then: the file is uploaded and kept for retry
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_408() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 408)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertTrue(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to still be present")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file but too large (413)
'  When: waiting for the loop to run
'  Then: the file is uploaded and deleted
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_413() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 413)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertFalse(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to be deleted")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file but too many requests (429)
'  When: waiting for the loop to run
'  Then: the file is uploaded and kept for retry
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_429() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 429)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertTrue(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to still be present")
    ])
end function


'----------------------------------------------------------------
' Given: an uploader and an uploadable file but too large (4xx)
'  When: waiting for the loop to run
'  Then: the file is uploaded and deleted
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_4xx() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    responseCode = IG_GetOneOf([402, IG_GetIntegerInRange(404, 407), IG_GetIntegerInRange(409, 412), IG_GetIntegerInRange(414, 428), IG_GetIntegerInRange(430, 499)])
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, responseCode)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertFalse(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to be deleted")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, server failing (500)
'  When: waiting for the loop to run
'  Then: the file is uploaded and kept for retry
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_500() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 500)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertTrue(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to still be present")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, server overloaded (503)
'  When: waiting for the loop to run
'  Then: the file is uploaded and kept for retry
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_503() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, 503)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertTrue(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to still be present")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and an uploadable file, unknown server error (5xx)
'  When: waiting for the loop to run
'  Then: the file is uploaded and kept for retry
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_UploadsExistingFile_5xx() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    filePath = folderPath + "/" + IG_GetInteger(65536).toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    responseCode = IG_GetIntegerInRange(500, 599)
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, responseCode)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertFunctionCalled", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }),
        m.assertTrue(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to still be present")
    ])
end function

'----------------------------------------------------------------
' Given: an uploader and a non-uploadable file
'  When: waiting for the loop to run
'  Then: the file is not uploaded and kept
'----------------------------------------------------------------
function UploaderTaskTest__WhenInit_IgnoreRecentFile() as string
    ' Given
    folderPath = "cachefs:/datadog/v1/" + m.fakeTrackType
    expectedUrl = "https://" + m.fakeEndpointHost + "/api/v2/" + m.fakeTrackType
    expectedHeaders = buildExpectedHeaders(m.fakeClientToken)
    datadogroku_mkdirs(folderPath)
    currentTimeStamp& = datadogroku_getTimestamp()
    filePath = folderPath + "/" + currentTimeStamp&.toStr()
    WriteAsciiFile(filePath, IG_GetString(128))
    responseCode = IG_GetIntegerInRange(500, 599)
    m.mockNetworkClient.callFunc("stubCall", "postFromFile", { url: expectedUrl, filePath: filePath, headers: expectedHeaders }, responseCode)

    ' When
    sleep(75)

    ' Then
    return m.multipleAssertions([
        m.mockNetworkClient.callFunc("assertNoInteractions"),
        m.assertTrue(CreateObject("roFileSystem").Exists(filePath), "Expected file " + filePath + " to still be present")
    ])
end function

'----------------------------------------------------------------
' Utility building the expected headers for each requests
' @return (object) an associative array with the upload request
'     headers
'----------------------------------------------------------------
function buildExpectedHeaders(clientToken as string) as object
    headers = {}
    headers["Content-Type"] = "application/json"
    headers["DD-API-KEY"] = clientToken
    headers["DD-EVP-ORIGIN"] = datadogroku_agentSource()
    headers["DD-EVP-ORIGIN-VERSION"] = datadogroku_sdkVersion()
    return headers
end function
