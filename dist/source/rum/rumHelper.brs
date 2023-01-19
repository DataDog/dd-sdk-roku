' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/fileUtils.bs"
'*****************************************************************
'* Utilities to inspect RUM events
'*****************************************************************

' ----------------------------------------------------------------
' Verifies if the given resource object is valid
' @param resource (object) the resource object
' @return (boolean) whether the resource object is valid
' ----------------------------------------------------------------
function isValidResource(resource as object) as boolean
    status = resource.status
    if (status = "ok" or status = "" or status = invalid)
        return (resource.url <> invalid and resource.transferTime <> invalid)
    end if
    return false
end function

' ----------------------------------------------------------------
' Computes the path the the copy of the last view event
' @param instanceId (string) the current SDK instance id (renewed
' at every initialization)
' @return (string) the file path where the event should be stored
' ----------------------------------------------------------------
function lastViewEventFilePath(instanceId as string) as string
    folderPath = trackFolderPath("rum")
    return folderPath + "/_last_view_" + instanceId
end function