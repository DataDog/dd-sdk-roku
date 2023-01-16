' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/fileUtils.bs"
'import "pkg:/source/timeUtils.bs"
' *****************************************************************
' * MultiTrackUploaderTask: a background loop checking for files available for upload;
' * When a file is ready, it is uploaded, and upon success deleted from disk.
' * It can look into different folders with distinct configurations
' *****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.top.functionName = "uploaderLoop"
    m.top.control = "RUN"
end sub

' ----------------------------------------------------------------
' Main uploader loop
' ----------------------------------------------------------------
sub uploaderLoop()
    ddLogThread("MultiTrackUploaderTask.uploaderLoop()")
    ' Uploader's dependencies
    m.fileSystem = CreateObject("roFileSystem")
    m.deviceInfo = CreateObject("roDeviceInfo")
    while (true)
        ddLogVerbose("Multi Track Uploader loop sync")
        uploadAvailableFiles()
        ddLogVerbose("Nothing else to do, waiting for " + m.top.waitPeriodMs.toStr() + "ms")
        sleep(m.top.waitPeriodMs)
    end while
end sub

' ----------------------------------------------------------------
' Looks for all uploadable files, and upload them one by one
' ----------------------------------------------------------------
sub uploadAvailableFiles()
    tracks = m.top.tracks
    if (tracks <> invalid and GetInterface(tracks, "ifAssociativeArray") <> invalid)
        for each track in tracks
            ddLogVerbose("Checking files to upload for track " + track)
            trackInfo = tracks[track]
            uploadAvailableFilesForTrack(trackInfo)
        end for
    end if
end sub

' ----------------------------------------------------------------
' Looks for all uploadable files for the given track, and upload them one by one
' @param trackInfo (object) the configuration for the current track
' ----------------------------------------------------------------
sub uploadAvailableFilesForTrack(trackInfo as object)
    if (trackInfo.trackType <> invalid)
        folderPath = trackFolderPath(trackInfo.trackType)
        ddLogVerbose("Checking files in folder " + folderPath)
        filenames = ListDir(folderPath)
        for each filename in filenames
            filePath = folderPath + "/" + filename
            if (isFileValidForUpload(filename))
                requestId = m.deviceInfo.GetRandomUUID()
                responseCode = uploadFile(filePath, trackInfo, requestId)
                handleResponse(requestId, responseCode, filePath, trackInfo)
            end if
        end for
    end if
end sub

' ----------------------------------------------------------------
' Verify if the given file is uploadable
' @param path (string) the path of the file to upload
' @return (boolean) if the file is valid for upload
' ----------------------------------------------------------------
function isFileValidForUpload(filename as string) as boolean
    fileTimestamp& = strToLong(filename)
    uploadTimestamp& = fileTimestamp& + 30000
    currentTimestamp& = getTimestamp()
    return (uploadTimestamp& < currentTimestamp&)
end function

' ----------------------------------------------------------------
' Get the upload url for the current track
' @param trackInfo (object) the configuration for the current track
' @return (string) the url to upload the data to
' ----------------------------------------------------------------
function getUploadUrl(trackInfo as object) as string
    url = trackInfo.url
    if (trackInfo.queryParams <> invalid)
        first = true
        for each key in trackInfo.queryParams
            ddLogVerbose("Found query params " + key)
            prefix = ""
            if (first)
                prefix = "?"
            else
                prefix = "&"
            end if
            ' TODO add url encoding of values
            url = url + prefix + key + "=" + trackInfo.queryParams[key]
            first = false
        end for
    else
        ddLogVerbose("No query parameters")
    end if
    return url
end function

' ----------------------------------------------------------------
' Uploads the content of the given file to Datadog
' @param path (string) the path of the file to upload
' @param trackInfo (object) the configuration for the current track
' @param requestId (string) the unique identifier for this request
' @return (integer) the upload status code
' ----------------------------------------------------------------
function uploadFile(path as string, trackInfo as object, requestId as string) as integer
    ensureNetworkClient()
    url = getUploadUrl(trackInfo)
    headers = {}
    headers["Content-Type"] = trackInfo.contentType
    headers["DD-API-KEY"] = m.top.clientToken
    headers["DD-EVP-ORIGIN"] = agentSource()
    headers["DD-EVP-ORIGIN-VERSION"] = sdkVersion()
    headers["DD-REQUEST-ID"] = requestId
    ddLogVerbose("Network request " + requestId + " from " + path + " to " + url)
    result = m.networkClient.callfunc("postFromFile", url, path, headers, trackInfo.payloadPrefix, trackInfo.payloadPostfix)
    return result
end function

' ----------------------------------------------------------------
' Handles the response code by deleting or keeping the file for retry.
' @param requestId (string) the unique identifier for this request
' @param responseCode (integer) the HTTP status code of the upload request
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
' @param filePath (string) the path of the file that was uploaded
' @param trackInfo (object) the configuration for the current track
' ----------------------------------------------------------------
sub handleResponse(requestId as string, responseCode as integer, filePath as string, trackInfo as object)
    if (responseCode = 202)
        ddLogInfo("Upload to track " + trackInfo.trackType + " succeeded.")
        retry = false
    else if (responseCode = 400)
        ddLogError("Upload to track " + trackInfo.trackType + " failed, data will be discarded;")
        ddLogError("The intake server returned status code 400 Bad Request, try updating the SDK to the latest version, or contact the support.")
        ddLogError("DD-REQUEST-ID:" + requestId)
        ddLogError("Uploaded data was:" + chr(10) + ReadAsciiFile(filePath))
        retry = false
    else if (responseCode = 401)
        ddLogError("Upload to track " + trackInfo.trackType + " failed, data will be discarded;")
        ddLogError("The intake server returned status code 401 Unauthorized, please check your ClientToken is correct and still valid.")
        retry = false
    else if (responseCode = 403)
        ddLogError("Upload to track " + trackInfo.trackType + " failed, data will be discarded;")
        ddLogError("The intake server returned status code 403 Forbidden, please check your ClientToken is correct and still valid.")
        retry = false
    else if (responseCode = 408)
        ddLogWarning("Upload to track " + trackInfo.trackType + " timed out, we'll retry later")
        retry = true
    else if (responseCode = 413)
        ddLogError("Upload to track " + trackInfo.trackType + " failed, data will be discarded;")
        ddLogError("The intake server returned status code 413 Payload Too Large, please check the number of custom attributes you attached to your events, or contact the support.")
        retry = false
    else if (responseCode = 429)
        ddLogWarning("Upload to track " + trackInfo.trackType + " failed, we'll retry later;")
        ddLogWarning("The intake server returned status code 429 Too Many Requests; if you think this shouldn't happen, please contact the support.")
        retry = true
    else if (responseCode = 500)
        ddLogWarning("Upload to track " + trackInfo.trackType + " failed, we'll retry later;")
        ddLogWarning("The intake server returned status code 500 Internal Server Error; if the issue persists, please contact the support.")
        retry = true
    else if (responseCode = 503)
        ddLogWarning("Upload to track " + trackInfo.trackType + " failed, we'll retry later;")
        ddLogWarning("The intake server returned status code 503 Unavailable; if the issue persists, please contact the support.")
        retry = true
    else if (responseCode >= 500 and responseCode < 600)
        ddLogWarning("Upload to track " + trackInfo.trackType + " failed, we'll retry later;")
        ddLogWarning("The intake server returned status code " + responseCode.toStr() + "; if the issue persists, please contact the support.")
        retry = true
    else if (responseCode >= 400 and responseCode < 500)
        ddLogWarning("Upload to track " + trackInfo.trackType + " failed, data will be discarded;")
        ddLogWarning("The intake server returned status code " + responseCode.toStr() + "; if the issue persists, please contact the support.")
        retry = false
    else
        ddLogWarning("Upload to track " + trackInfo.trackType + " status unknown;")
        ddLogWarning("The intake server returned status code " + responseCode.toStr() + "; if the issue persists, please contact the support.")
        retry = false
    end if
    if (not retry)
        ddLogVerbose("Deleting file at " + filePath)
        if (not DeleteFile(filePath))
            message = "Unable to delete batch file at " + filePath
            ddLogWarning(message)
            m.global.datadogRumAgent.callfunc("addErrorTelemetry", {
                number: 0
                message: message
                backtrace: []
            })
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