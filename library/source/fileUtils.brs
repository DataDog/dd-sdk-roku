' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
'* Common file I/O utility functions
'*****************************************************************

' ----------------------------------------------------------------
' Create a directory (and all intermediate directories), similar
' to the `mkdir -p` command in linux
' @param path (string) the path to a folder
' @return (boolean) true if the directory was created or already exists
' ----------------------------------------------------------------
function mkdirs(path as string) as boolean
    logVerbose("mkdirs(" + path + ")")

    fileSystem = CreateObject("roFileSystem")

    ' Early exist, dir already exists
    if (fileSystem.Exists(path))
        logInfo("Folder already exists: " + path)
        return true
    end if


    ' Early exit, path contains invalid chars
    folderPath = CreateObject("roPath", path)
    if (not folderPath.IsValid())
        logWarning("Can't make folder, path is invalid: " + path)
        return false
    end if

    folderData = folderPath.Split()

    ' Ensure parent exists
    if (folderData.parent <> "" and folderData.parent <> (folderData.phy + "/"))
        if (not mkdirs(folderData.parent))
            return false
        end if
    end if

    ' Create dir
    if (not CreateDirectory(path))
        logWarning("Failed to create directory " + path)
        return true
    end if

    return true
end function
