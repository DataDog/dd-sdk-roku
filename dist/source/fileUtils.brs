' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/internalLogger.bs"
'*****************************************************************
'* Common file I/O utility functions
'*****************************************************************

' ----------------------------------------------------------------
' Computes the path where data should be stored for the given track type
' @param trackType (string) the type of events
' @param version (integer) the data event version
' @return (string) true if the directory was created or already exists
' ----------------------------------------------------------------
function trackFolderPath(trackType as string, version = 1 as integer) as string
    return "cachefs:/datadog/v" + version.toStr() + "/" + trackType
end function

' ----------------------------------------------------------------
' Makes sure the parent folder for the given path exists (e.g. to
' be able to write to the path)
' @param path (string) the path to a file or folder
' @return (string) true if the directory was created or already exists
' ----------------------------------------------------------------
function mkParentDirs(path as string) as boolean
    ddLogVerbose("mkParentDirs(" + path + ")")
    ' Early exit, path contains invalid chars
    dirPath = CreateObject("roPath", path)
    if (not dirPath.IsValid())
        message = "Can't make parent directory, path is invalid: " + path
        ddLogWarning(message)
        return false
    end if
    folderData = dirPath.Split()
    return mkDirs(folderData.parent)
end function

' ----------------------------------------------------------------
' Create a directory (and all intermediate directories), similar
' to the `mkdir -p` command in linux
' @param path (string) the path to a folder
' @return (boolean) true if the directory was created or already exists
' ----------------------------------------------------------------
function mkDirs(path as string) as boolean
    ddLogVerbose("mkDirs(" + path + ")")
    fileSystem = CreateObject("roFileSystem")
    ' Early exist, dir already exists
    if (fileSystem.Exists(path))
        ddLogInfo("Folder already exists: " + path)
        return true
    end if
    ' Early exit, path contains invalid chars
    dirPath = CreateObject("roPath", path)
    if (not dirPath.IsValid())
        message = "Can't make directory, path is invalid: " + path
        ddLogWarning(message)
        if (m.global.datadogRumAgent <> invalid)
            m.global.datadogRumAgent.callfunc("addErrorTelemetry", {
                number: 0
                message: message
                backtrace: []
            })
        end if
        return false
    end if
    folderData = dirPath.Split()
    ' Ensure parent exists
    if (folderData.parent <> "" and folderData.parent <> (folderData.phy + "/"))
        if (not mkDirs(folderData.parent))
            return false
        end if
    end if
    ' Create dir
    if (not CreateDirectory(path))
        message = "Failed to create directory " + path
        ddLogWarning(message)
        if (m.global.datadogRumAgent <> invalid)
            m.global.datadogRumAgent.callfunc("addErrorTelemetry", {
                number: 0
                message: message
                backtrace: []
            })
        end if
        return false
    end if
    return true
end function

' ----------------------------------------------------------------
' Appends the given text string to a file. If the file doesn't exist
'     then it is created.
' @param filepath (string) the path to the file to be appended
' @param text (string) the text to append
' @return (string) whether the file was successfully appended
' ----------------------------------------------------------------
function AppendAsciiFile(filepath as string, text as string) as boolean
    ddLogVerbose("Appending bytes to " + filepath)
    byteArray = CreateObject("roByteArray")
    byteArray.FromAsciiString(text)
    return byteArray.AppendFile(filepath)
end function

' ----------------------------------------------------------------
' Converts the given string into a long value
' @param s (string) a string with only a number in decimal format
' @return (longinteger) the value as a long integer
' ----------------------------------------------------------------
function strToLong(s as string) as longinteger
    value& = 0
    length = Len(s)
    for i = 1 to (length)
        char = Mid(s, i, 1)
        value& = (value& * 10) + StrToI(char)
    end for
    return value&
end function