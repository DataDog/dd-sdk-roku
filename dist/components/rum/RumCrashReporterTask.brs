' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/fileUtils.bs"
' *****************************************************************
' * RumCrashReporterTask : a node capable of writing data to a file on disk
' *****************************************************************
'import "pkg:/source/rum/rumHelper.bs"

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("RumCrashReporterTask.init()")
    m.port = createObject("roMessagePort")
    m.top.functionName = "sendCrashReport"
end sub

' ----------------------------------------------------------------
' Reads the last known view event and send the crash report
' ----------------------------------------------------------------
sub sendCrashReport()
    ddLogThread("RumCrashReporterTask.sendCrashReport()")
    currentSessionlastViewEventFilePath = lastViewEventFilePath(m.top.instanceId)
    unexpectedExitStatus = [
        "EXIT_BRIGHTSCRIPT_CRASH"
        "EXIT_BRIGHTSCRIPT_TIMEOUT"
        "EXIT_GRAPHICS_NOT_RELEASED"
        "EXIT_SIGNAL_TIMEOUT"
        "EXIT_OUT_OF_MEMORY"
        "EXIT_MEM_LIMIT_EXCEEDED_FG"
        "EXIT_MEM_LIMIT_EXCEEDED_BG"
    ]
    keep = false
    for each status in unexpectedExitStatus
        if (m.top.lastExitOrTerminationReason = status)
            keep = true
            exit for
        end if
    end for
    if (not keep)
        ddLogInfo("Last exit status " + m.top.lastExitOrTerminationReason + " is not a crash, ignoring")
    end if
    folderPath = trackFolderPath("rum")
    filenames = ListDir(folderPath)
    for each filename in filenames
        filePath = folderPath + "/" + filename
        ddLogVerbose("RumCrashReporterTask, checking file: " + filename)
        if (filePath = currentSessionlastViewEventFilePath)
            ddLogVerbose("Ignoring current session file: " + filename)
        else if (filename.Left(10) = "_last_view")
            if (keep)
                ddLogVerbose("Found last view file " + filePath)
                sendCrashReportFromViewEventFile(filePath)
            end if
            ddLogVerbose("Deleting file " + filePath)
            DeleteFile(filePath)
        end if
    end for
    ddLogVerbose("RumCrashReporterTask, all checks done")
end sub

' ----------------------------------------------------------------
' Sends a crash report linked to the view stored in the given path
' @param filepath (string) the path to the file holding the last known view event
' ----------------------------------------------------------------
sub sendCrashReportFromViewEventFile(filepath as string)
    ddLogVerbose("Reading file " + filepath)
    lastViewEventJson = ReadAsciiFile(filepath)
    if (lastViewEventJson = "" or lastViewEventJson = invalid)
        ddLogWarning("A crash was detected but the last known view is empty, ignoring")
        return
    end if
    ddLogVerbose("Parsing event from " + filepath)
    lastViewEvent = ParseJson(lastViewEventJson)
    if (lastViewEvent = invalid or lastViewEvent._dd = invalid or lastViewEvent.view = invalid or lastViewEvent.date = invalid)
        ddLogError("A crash was detected but the last view event is invalid")
        ddLogError(lastViewEventJson)
        return
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
        context: m.global.datadogContext
        date: timestamp&
        error: {
            id: CreateObject("roDeviceInfo").GetRandomUUID()
            is_crash: true
            message: "Channel stopped unexpectedly"
            source: "source"
            source_type: agentSource()
            stack: ""
            type: m.top.lastExitOrTerminationReason
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
    m.top.writer.writeEvent = FormatJson(crashEvent)
    sleep(50)
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
    m.top.writer.writeEvent = FormatJson(lastViewEvent)
end sub