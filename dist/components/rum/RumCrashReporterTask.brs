' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/fileUtils.bs"
'import "pkg:/source/immutableRecords.bs"
'import "pkg:/source/rum/crashStorage.bs"
'import "pkg:/source/rum/viewSnapshots.bs"
' *****************************************************************
' * RumCrashReporterTask : a node capable of writing data to a file on disk
' *****************************************************************
'import "pkg:/source/rum/rumHelper.bs"

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("RumCrashReporterTask.init()")
    m.top.functionName = "sendCrashReport"
end sub

' ----------------------------------------------------------------
' Reads the last known view event and send the crash report
' ----------------------------------------------------------------
sub sendCrashReport()
    ddLogThread("RumCrashReporterTask.sendCrashReport()")
    currentSessionlastViewEventFilePath = lastViewEventFilePath(m.top.instanceId)
    m.lastExitOrTerminationReason = m.top.lastExitOrTerminationReason
    ignoredExitEvents = (function(m)
            __bsConsequent = m.global.datadogIgnoredExitEvents
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return []
            end if
        end function)(m)
    keep = true
    if (m.lastExitOrTerminationReason = "")
        ddLogInfo("Last exit status is empty, ignoring")
        keep = false
    else
        for each status in ignoredExitEvents
            if (m.lastExitOrTerminationReason = status)
                keep = false
                exit for
            end if
        end for
    end if
    if (keep)
        m.lastExitConsoleLog = m.top.lastExitConsoleLog
    else
        ddLogInfo("Last exit status " + m.lastExitOrTerminationReason + " is not a crash, ignoring")
    end if
    folderPath = trackFolderPath("rum")
    filenames = ListDir(folderPath)
    for each filename in filenames
        filePath = folderPath + "/" + filename
        ddLogVerbose("RumCrashReporterTask, checking file: " + filename)
        if (filePath = currentSessionlastViewEventFilePath)
            ddLogVerbose("Ignoring current session file: " + filename)
        else if (filename.Left(10) = "_last_view")
            completed = not keep
            if (keep)
                completed = sendCrashReportFromViewEventFile(filePath)
            end if
            if (completed)
                deleteFileIfPresent(filePath)
            end if
        end if
    end for
    recoverViewSnapshots(folderPath, keep)
    ddLogVerbose("RumCrashReporterTask, all checks done")
end sub

' ----------------------------------------------------------------
' Sends a crash report linked to the view stored in the given path
' @param filepath (string) the path to the file holding the last known view event
' ----------------------------------------------------------------
function sendCrashReportFromViewEventFile(filepath as string) as boolean
    ddLogVerbose("Reading file " + filepath)
    bytes = CreateObject("roByteArray")
    if (not bytes.ReadFile(filepath))
        return false
    end if
    lastViewEventJson = bytes.ToAsciiString()
    lastViewEvent = ParseJson(lastViewEventJson)
    if (not isRecoverableCrashView(lastViewEvent))
        ddLogWarning("Unable to recover invalid last view snapshot")
        return false
    end if
    return persistCrashReportFromView(lastViewEvent)
end function

function persistCrashReportFromView(lastViewEvent as object) as boolean
    if (m.top.writer = invalid)
        return false
    end if
    scope = m.top.writer.storageScope
    if (not isRecordHex(scope, 64))
        return false
    end if
    timeSpentNs& = ((function(lastViewEvent)
            __bsConsequent = lastViewEvent.view.time_spent
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return 0
            end if
        end function)(lastViewEvent)) + millisToNanos(100) ' 100 ms after last known timestamp
    timeSpentMs& = nanosToMillis(timeSpentNs&)
    timestamp& = timeSpentMs& + lastViewEvent.date
    crashEvent = {
        _dd: {
            format_version: 2
            session: {
                plan: 1
            }
        }
        application: {
            id: lastViewEvent.application.id
        }
        context: lastViewEvent.context
        date: timestamp&
        device: lastViewEvent.device
        os: lastViewEvent.os
        error: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            is_crash: true
            message: "Channel stopped unexpectedly"
            source: "source"
            source_type: agentSource()
            stack: m.lastExitConsoleLog
            type: m.lastExitOrTerminationReason
        }
        service: lastViewEvent.service
        session: {
            has_replay: false
            id: lastViewEvent.session.id
            type: "user"
        }
        source: agentSource()
        type: "error"
        usr: lastViewEvent.usr
        version: lastViewEvent.version
        view: {
            id: lastViewEvent.view.id
            url: lastViewEvent.view.url
            name: lastViewEvent.view.name
        }
    }
    ddLogInfo("RumCrashReporterTask, writing crash")
    ' Already on a Task thread: a checked synchronous write is the acknowledgement.
    folder = trackFolderPath("rum")
    first = writeImmutableRecord(folder, scope, FormatJson(crashEvent), m.crashRecordIO)
    if (first.status <> "verified")
        return false
    end if
    lastViewEvent._dd.document_version = ((function(lastViewEvent)
            __bsConsequent = lastViewEvent._dd.document_version
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return 0
            end if
        end function)(lastViewEvent)) + 1
    lastViewEvent.view.error = {
        count: ((function(lastViewEvent)
                __bsConsequent = lastViewEvent.view.error.count
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return 0
                end if
            end function)(lastViewEvent)) + 1
    }
    lastViewEvent.view.crash = {
        count: 1
    }
    lastViewEvent.view.time_spent = timeSpentNs&
    ddLogInfo("RumCrashReporterTask, writing view update")
    second = writeImmutableRecord(folder, scope, FormatJson(lastViewEvent), m.crashRecordIO)
    return second.status = "verified"
end function

sub recoverViewSnapshots(folder as string, keep as boolean)
    if (m.top.writer = invalid)
        return
    end if
    scope = m.top.writer.storageScope
    if (not isRecordHex(scope, 64))
        return
    end if
    io = (function(m, newViewSnapshotIO)
            __bsConsequent = m.snapshotIO
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return newViewSnapshotIO()
            end if
        end function)(m, newViewSnapshotIO)
    currentOwner = viewSnapshotOwner(m.top.instanceId)
    owners = {}
    for each entry in listViewSnapshots(folder, scope, "", io)
        if (entry.owner <> currentOwner)
            if (not owners.DoesExist(entry.owner))
                owners[entry.owner] = []
            end if
            owners[entry.owner].Push(entry)
        end if
    end for
    for each owner in owners
        entries = owners[owner]
        latest = latestViewSnapshot(entries)
        if (latest <> invalid)
            completed = not keep or isViewSnapshotClear(latest.value)
            if (not completed)
                completed = persistCrashReportFromView(latest.value)
            end if
            if (completed)
                pruneViewSnapshots(folder, entries, latest, true, io)
            end if
        end if
    end for
end sub