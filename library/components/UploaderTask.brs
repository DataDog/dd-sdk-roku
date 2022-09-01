' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
' * UploaderTask: a background loop checking for files available for upload;
' * When a file is ready, it s uploaded, and upon success deleted from disk.
'*****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ' Uploader's dependencies
    m.fileSystem = CreateObject("roFileSystem")
    m.deviceInfo = CreateObject("roDeviceInfo")

    ' start the uploader's loop
    m.top.functionName = "uploaderLoop"
end sub

' ----------------------------------------------------------------
' Main uploader loop
' ----------------------------------------------------------------
sub uploaderLoop()
    logVerbose("Starting Uploader loop")
    while (true)
        logVerbose("Uploader loop sync")
        uploadAvailableFiles()
        logVerbose("Nothing else to do, waiting for " + m.top.waitPeriodMs.toStr() + "ms")
        sleep(m.top.waitPeriodMs)
    end while
end sub

' ----------------------------------------------------------------
' Looks for all uploadable files, and upload them one by one
' ----------------------------------------------------------------
sub uploadAvailableFiles()
    folderPath = "cachefs:/datadog/v1/" + m.top.trackType
    logInfo("Checking uploadable files in " + folderPath)

    folderExists = m.fileSystem.Exists(folderPath)
    if (not folderExists)
        logInfo("Folder for track " + m.top.trackType + " doesn't exist")
        mkdirs(folderPath)
    end if

    filenames = ListDir(folderPath)

    for each filename in filenames
        filePath = folderPath + "/" + filename
        if (isFileValidForUpload(filename))
            responseCode = uploadFile(filePath)
            handleResponse(responseCode, filePath)
        else
            logVerbose("Can't upload " + filename + " yet")
        end if
    end for
end sub

' ----------------------------------------------------------------
' Verify if the given file is uploadable
' @param path (string) the path of the file to upload
' @return (boolean) if the file is valid for upload
' ----------------------------------------------------------------
function isFileValidForUpload(filename as string) as boolean
    ' Roku's String.toInt() method only convert to integer (32bits) but timestamps are long
    ' Weirdly, ParseJson will return the proper value
    fileTimestamp& = ParseJson(filename)
    uploadTimestamp& = fileTimestamp& + 30000
    currentTimestamp& = getTimestamp()
    return (uploadTimestamp& < currentTimestamp&)
end function

' ----------------------------------------------------------------
' Uploads the content of the given file to Datadog
' @param path (string) the path of the file to upload
' @return (integer) the upload status code
' ----------------------------------------------------------------
function uploadFile(path as string) as integer
    ensureNetworkClient()

    url = "https://" + m.top.endpointHost + "/api/v2/" + m.top.trackType
    headers = {}
    headers["Content-Type"] = "application/json"
    headers["DD-API-KEY"] = m.top.clientToken
    headers["DD-EVP-ORIGIN"] = agentSource()
    headers["DD-EVP-ORIGIN-VERSION"] = sdkVersion()
    headers["DD-REQUEST-ID"] = m.deviceInfo.GetRandomUUID()

    result = m.networkClient.callFunc("postFromFile", url, path, headers)
    return result
end function

' ----------------------------------------------------------------
' Handles the response code by deleting or keeping the file for retry.
' - 202 Accepted: the request has been accepted for processing
' - 400 Bad Request: the server cannot or will not process the request (client error).
'     The client SHOULD NOT retry this request.
' - 401 Unauthorized: the request lacks valid authentication credentials.
'     The client SHOULD NOT retry this request.
' - 403 Forbidden: the server understood the request but refuses to authorize it (invalid credentials, …).
'     The client SHOULD NOT retry this request.
' - 408 Request Timeout:
'     The client SHOULD retry this request.
' - 413 Payload Too Large: the request entity is larger than limits defined by server.
'     The client SHOULD NOT retry this request.
' - 429 Too Many Requests: the user has sent too many requests in a given amount of time.
'     The client SHOULD retry this request.
' - 500 Internal Server Error: the server encountered an unexpected condition.
'     The client SHOULD retry this request.
' - 503 Service Unavailable: the server is not ready to handle the request probably because it is overloaded.
'     The client SHOULD retry this request.
' @param path (string) the path of the file that was uploaded
' ----------------------------------------------------------------
sub handleResponse(responseCode as integer, filePath as string)
    if (responseCode = 202)
        logInfo("Upload from " + filePath + " to track " + m.top.trackType + " succeeded.")
        retry = false
    else if (responseCode = 400)
        logError("Upload from " + filePath + " to track " + m.top.trackType + " failed, data will be discarded;")
        logError("The intake server returned status code 400 Bad Request, try updating the SDK to the latest version, or contact the support.")
        retry = false
    else if (responseCode = 401)
        logError("Upload from " + filePath + " to track " + m.top.trackType + " failed, data will be discarded;")
        logError("The intake server returned status code 401 Unauthorized, please check your ClientToken is correct and still valid.")
        retry = false
    else if (responseCode = 403)
        logError("Upload from " + filePath + " to track " + m.top.trackType + " failed, data will be discarded;")
        logError("The intake server returned status code 403 Forbidden, please check your ClientToken is correct and still valid.")
        retry = false
    else if (responseCode = 408)
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " timed out, we'll retry later")
        retry = true
    else if (responseCode = 413)
        logError("Upload from " + filePath + " to track " + m.top.trackType + " failed, data will be discarded;")
        logError("The intake server returned status code 413 Payload Too Large, please check the number of custom attributes you attached to your events, or contact the support.")
        retry = false
    else if (responseCode = 429)
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " failed, we'll retry later;")
        logWarning("The intake server returned status code 429 Too Many Requests; if you think this shouldn't happen, please contact the support.")
        retry = true
    else if (responseCode = 500)
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " failed, we'll retry later;")
        logWarning("The intake server returned status code 500 Internal Server Error; if the issue persits, please contact the support.")
        retry = true
    else if (responseCode = 503)
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " failed, we'll retry later;")
        logWarning("The intake server returned status code 503 Unavailable; if the issue persits, please contact the support.")
        retry = true
    else if (responseCode >= 500 and responseCode < 600)
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " failed, we'll retry later;")
        logWarning("The intake server returned status code " + responseCode.toStr() + "; if the issue persits, please contact the support.")
        retry = true
    else if (responseCode >= 400 and responseCode < 500)
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " failed, data will be discarded;")
        logWarning("The intake server returned status code " + responseCode.toStr() + "; if the issue persits, please contact the support.")
        retry = false
    else
        logWarning("Upload from " + filePath + " to track " + m.top.trackType + " status unknown;")
        logWarning("The intake server returned status code " + responseCode.toStr() + "; if the issue persits, please contact the support.")
        retry = false
    end if

    if (not retry)
        logVerbose("Deleting file at " + filePath)
        if (not DeleteFile(filePath))
            logWarning("Unable to delete file at " + filePath)
        end if
    end if
end sub

' ----------------------------------------------------------------
' Sets the internal network client from the top node's field,
' or instantiate one.
' ----------------------------------------------------------------
sub ensureNetworkClient()
    if (m.networkClient = invalid)
        if (m.top.networkClient <> invalid)
            m.networkClient = m.top.networkClient
        else
            m.networkClient = CreateObject("roSGNode", "NetworkClient")
        end if
    end if
end sub
