' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
' *****************************************************************
' * : a node capable of writing data to a file on disk
' *****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("WriterTask.init()")
    m.port = createObject("roMessagePort")
    m.top.observeFieldScoped("writeEvent", m.port)
    m.top.functionName = "writerLoop"
    m.top.control = "RUN"
end sub

' ----------------------------------------------------------------
' Main writer loop
' ----------------------------------------------------------------
sub writerLoop()
    ddLogThread("WriterTask.writerLoop()")
    m.fileSystem = CreateObject("roFileSystem")
    while (true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if (msgType = "roSGNodeEvent")
            fieldName = msg.getField()
            if (fieldName = "writeEvent")
                eventData = msg.getData()
                onWriteEvent(eventData)
            else
                ddLogWarning(fieldName + " not handled")
            end if
        end if
    end while
end sub

' ----------------------------------------------------------------
' Writes an event to a writeable file to be uploaded
' @param event (string) the event serialized to string
' ----------------------------------------------------------------
sub onWriteEvent(event as string)
    ddLogThread("WriterTask.onWriteEvent()")
    if (event = "")
        ' Ignore empty event
        return
    end if
    filePath = getWriteableFile(event.Len())
    ddLogVerbose("Got file: " + filePath)
    if (m.fileSystem.Exists(filePath))
        fileSize = m.fileSystem.Stat(filePath).size
        if (fileSize > 0)
            AppendAsciiFile(filePath, m.top.payloadSeparator)
        end if
    end if
    AppendAsciiFile(filePath, event)
    ddLogVerbose(event)
end sub

' ----------------------------------------------------------------
' Returns the path to an existing or new writeable file
' @param eventSize (string) the size of the event to write
' @return (string) the path to a valid writeable file
' ----------------------------------------------------------------
function getWriteableFile(eventSize as integer) as string
    folderPath = trackFolderPath(m.top.trackType)
    folderExists = m.fileSystem.Exists(folderPath)
    if (not folderExists)
        ddLogVerbose("Folder for track " + m.top.trackType + " doesn't exist")
        mkdirs(folderPath)
    end if
    currentTimestamp& = getTimestamp()
    filenames = ListDir(folderPath).ToArray()
    filenames.Sort("r")
    if (filenames.count() > 0)
        lastFilename = filenames[0]
        fileTimestamp& = strToLong(lastFilename)
        uploadTimestamp& = fileTimestamp& + 25000
        if ((uploadTimestamp& > currentTimestamp&))
            lastFilePath = folderPath + "/" + lastFilename
            lastFileSize = m.fileSystem.Stat(lastFilePath).size
            if (lastFileSize + m.top.payloadSeparator.Len() + eventSize < m.top.maxBatchSize)
                return folderPath + "/" + lastFilename
            end if
        end if
    end if
    return folderPath + "/" + currentTimestamp&.toStr()
end function