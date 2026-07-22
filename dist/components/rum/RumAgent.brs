' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/rum/rumRawEvents.bs"
'import "pkg:/source/rum/rumHelper.bs"
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
' *****************************************************************
' * RumAgent: a background component listening for internal events
' *     to write relevant RUM Events to Datadog.
' *****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    ddLogThread("RumAgent.init()")
    m.port = createObject("roMessagePort")
    m.top.observeFieldScoped("startView", m.port)
    m.top.observeFieldScoped("stopView", m.port)
    m.top.observeFieldScoped("addAction", m.port)
    m.top.observeFieldScoped("addError", m.port)
    m.top.observeFieldScoped("addResource", m.port)
    m.top.observeFieldScoped("addResources", m.port)
    m.top.observeFieldScoped("reportUserActivity", m.port)
    m.top.observeFieldScoped("addConfigTelemetry", m.port)
    m.top.observeFieldScoped("addErrorTelemetry", m.port)
    m.top.observeFieldScoped("addDebugTelemetry", m.port)
    m.top.observeFieldScoped("startOperation", m.port)
    m.top.observeFieldScoped("succeedOperation", m.port)
    m.top.observeFieldScoped("failOperation", m.port)
    m.top.observeFieldScoped("reportOperations", m.port)
    m.top.functionName = "rumAgentLoop"
end sub

' ----------------------------------------------------------------
' Main RumAgent loop
' ----------------------------------------------------------------
sub rumAgentLoop()
    ddLogThread("RumAgent.rumAgentLoop()")
    setup()
    while (true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if (msgType = "roSGNodeEvent")
            fieldName = msg.getField()
            if (fieldName = "startView")
                __onStartView(msg.getData())
            else if (fieldName = "stopView")
                __onStopView(msg.getData())
            else if (fieldName = "addAction")
                __onAddAction(msg.getData())
            else if (fieldName = "addError")
                __onAddError(msg.getData())
            else if (fieldName = "addResource")
                __onAddResource(msg.getData())
            else if (fieldName = "addResources")
                __onAddResources(msg.getData())
            else if (fieldName = "reportUserActivity")
                __onReportUserActivity(msg.getData())
            else if (fieldName = "addConfigTelemetry")
                __onAddConfigTelemetry(msg.getData())
            else if (fieldName = "addErrorTelemetry")
                __onAddErrorTelemetry(msg.getData())
            else if (fieldName = "addDebugTelemetry")
                __onAddDebugTelemetry(msg.getData())
            else if (fieldName = "startOperation")
                __onStartOperation(msg.getData())
            else if (fieldName = "succeedOperation")
                __onSucceedOperation(msg.getData())
            else if (fieldName = "failOperation")
                __onFailOperation(msg.getData())
            else if (fieldName = "reportOperations")
                __onReportOperations(msg.getData())
            end if
        else
            ddLogWarning("Unexpected message " + msgType + ": " + FormatJson(msg))
        end if
    end while
end sub

sub setup()
    ' 1. Cache injected dependencies
    fields = m.top.getFields()
    m.uploader = fields.uploader
    m.writer = fields.writer 'allow tests to inject a mock
    m.rumScope = fields.rumScope 'allow tests to inject a mock
    m.telemetryScope = fields.telemetryScope 'allow tests to inject a mock
    m.applicationId = fields.applicationId
    m.instanceId = fields.instanceId
    m.service = fields.service
    m.version = fields.version
    m.deviceName = fields.deviceName
    m.deviceModel = fields.deviceModel
    m.osVersion = fields.osVersion
    m.osVersionMajor = fields.osVersionMajor
    m.sessionSampleRate = fields.sessionSampleRate
    m.env = fields.env
    m.site = fields.site
    m.lastExitOrTerminationReason = fields.lastExitOrTerminationReason
    m.configuration = fields.configuration
    ' 2. Create internal scopes
    ddLogVerbose("RumAgent.instanceId:" + m.instanceId)
    if (m.rumScope = invalid) 'skipped in tests (mock pre-injected)
        ddLogVerbose("Creating RumApplicationScope")
        m.rumScope = CreateObject("roSGNode", "RumApplicationScope")
        m.rumScope.setFields({
            applicationId: m.applicationId
            service: m.service
            version: m.version
            deviceName: m.deviceName
            deviceModel: m.deviceModel
            osVersion: m.osVersion
            osVersionMajor: m.osVersionMajor
            sessionSampleRate: m.sessionSampleRate
        })
        m.top.rumScope = m.rumScope
    end if
    if (m.telemetryScope = invalid) 'skipped in tests (mock pre-injected)
        ddLogVerbose("Creating RumTelemetryScope")
        m.telemetryScope = CreateObject("roSGNode", "RumTelemetryScope")
        m.top.telemetryScope = m.telemetryScope
    end if
    ' 3. Register our track on the shared uploader
    trackId = "rum_" + m.top.threadInfo().node.address
    tracks = (function(m)
            __bsConsequent = m.uploader.tracks
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(m)
    tracks[trackId] = {
        url: getIntakeUrl(m.site, "rum")
        trackType: "rum"
        payloadPrefix: ""
        payloadPostfix: ""
        contentType: "text/plain;charset=UTF-8"
        queryParams: {
            ddsource: agentSource()
            ddtags: "sdk_version:" + sdkVersion() + ",env:" + m.env
        }
    }
    m.uploader.setFields({
        tracks: tracks
    })
    ' 4. Configure writer
    if (m.writer = invalid) 'skipped in tests (mock pre-injected)
        ddLogVerbose("Creating WriterTask")
        m.writer = CreateObject("roSGNode", "WriterTask")
        m.top.writer = m.writer
    end if
    m.writer.setFields({
        trackType: "rum"
        payloadSeparator: chr(10)
    })
    ' 5. One-time launch-side effects
    ' On RokuOS 13+, sendCrash reads the exit code from roAppManager.GetLastExitInfo()
    ' regardless of the launch-options value, so it must always be invoked.
    sendCrash((function(m)
            __bsConsequent = m.lastExitOrTerminationReason
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return ""
            end if
        end function)(m))
    if (m.configuration <> invalid and m.configuration.Count() > 0)
        addConfigTelemetry(m.configuration)
    end if
end sub

' ----------------------------------------------------------------
' Starts a view
' @param name (string) the view name (human-readable)
' @param url (string) the view url (developer identifier)
' @param context (object) an assocarray of custom attributes to add to the view
' ----------------------------------------------------------------
sub startView(name as string, url as string, context = {} as object)
    m.top.startView = startViewEvent(name, url, context)
end sub

' ----------------------------------------------------------------
' Private: Handles startView field change event
' @param event (object) the startView event data
' ----------------------------------------------------------------
sub __onStartView(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
    m.rumScope.callfunc("handleEvent", keepAliveEvent(), m.writer)
end sub

' ----------------------------------------------------------------
' Stops a view
' @param name (string) the view name (human-readable)
' @param url (string) the view url (developer identifier)
' @param context (object) an assocarray of custom attributes to add to the view
' ----------------------------------------------------------------
sub stopView(name as string, url as string, context = {} as object)
    m.top.stopView = stopViewEvent(name, url, context)
end sub

' ----------------------------------------------------------------
' Private: Handles stopView field change event
' @param event (object) the stopView event data
' ----------------------------------------------------------------
sub __onStopView(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Adds an action
' @param action (object) the action to track
' @param context (object) an assocarray of custom attributes to add to the view
' ----------------------------------------------------------------
sub addAction(action as object, context = {} as object)
    m.top.addAction = addActionEvent(action, context)
end sub

' ----------------------------------------------------------------
' Private: Handles addAction field change event
' @param event (object) the addAction event data
' ----------------------------------------------------------------
sub __onAddAction(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Adds an error
' @param exception (object) the caught exception object
' @param context (object) an assocarray of custom attributes to add to the view
' ----------------------------------------------------------------
sub addError(exception as object, context = {} as object)
    m.top.addError = addErrorEvent(exception, context)
end sub

' ----------------------------------------------------------------
' Private: Handles addError field change event
' @param event (object) the addError event data
' ----------------------------------------------------------------
sub __onAddError(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Adds a resource
' @param resource (object) the tracked resource object (as retrieved from the roSystemLog)
' @param context (object) an assocarray of custom attributes to add to the view
' ----------------------------------------------------------------
sub addResource(resource as object, context = {} as object)
    m.top.addResource = addResourceEvent(resource, context)
end sub

' ----------------------------------------------------------------
' Private: Handles addResource field change event
' @param event (object) the addResource event data
' ----------------------------------------------------------------
sub __onAddResource(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Reports a batch of resources in a single rendezvous
' @param events (dynamic) an array of pre-built resource events, or invalid
' ----------------------------------------------------------------
sub __onAddResources(events as dynamic)
    if (events <> invalid and m.rumScope <> invalid)
        for each event in events
            ' The batch path bypasses the typed addResource(resource as object) wrapper,
            ' so guard that each item carries a resource assocarray before forwarding;
            ' a missing/invalid resource would otherwise crash the RUM scope.
            if (type(event) = "roAssociativeArray" and type(event.resource) = "roAssociativeArray")
                m.rumScope.callfunc("handleEvent", event, m.writer)
            else
                ddLogError("RumAgent: addResources received a malformed resource event, ignoring")
            end if
        end for
    end if
end sub

' ----------------------------------------------------------------
' Reports user activity to keep the current session alive. This
' refreshes the session's inactivity clock (renewing it if it has
' already expired) and, when a view is active, emits a view update
' so the session/view duration is extended in Datadog.
' Intended for apps with an existing high-frequency engagement
' signal (e.g. video playback position, GPS fix, sensor reading).
' @param _ph (dynamic) no-op argument: callFunc always passes one
'   argument, so a zero-param function would never be invoked
' ----------------------------------------------------------------
sub reportUserActivity(_ph = invalid as dynamic)
    m.top.reportUserActivity = userActivityEvent()
end sub

' ----------------------------------------------------------------
' Private: Handles reportUserActivity field change event
' @param event (object) the reportUserActivity event data
' ----------------------------------------------------------------
sub __onReportUserActivity(event as object)
    nowMs& = event.timestamp
    if (m.lastUserActivityMs <> invalid and (nowMs& - m.lastUserActivityMs) < m.top.keepAliveDelayMs)
        ddLogVerbose("Ignoring throttled reportUserActivity")
        return
    end if
    m.lastUserActivityMs = nowMs&
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Private: Handles sendCrash field change event
' @param lastExitOrTerminationReason (string) the last exit or termination reason
' ----------------------------------------------------------------
sub sendCrash(lastExitOrTerminationReason as string)
    crashReporter = CreateObject("roSGNode", "RumCrashReporterTask")
    exitReason = lastExitOrTerminationReason
    consoleLog = ""
    if (m.osVersionMajor.toInt() >= 13)
        lastExitInfo = createObject("roAppManager").GetLastExitInfo()
        if (lastExitInfo <> invalid)
            exitReason = lastExitInfo.exit_code
            consoleLog = lastExitInfo.console_log
        end if
    end if
    crashReporter.setFields({
        writer: m.writer
        lastExitOrTerminationReason: exitReason
        lastExitConsoleLog: consoleLog
        instanceId: m.instanceId
    })
    crashReporter.control = "RUN"
end sub

' ----------------------------------------------------------------
' Adds a telemetry config event
' @param configuration (object) the configuration information
' ----------------------------------------------------------------
sub addConfigTelemetry(configuration as object)
    m.top.addConfigTelemetry = addTelemetryConfigEvent(configuration)
end sub

' ----------------------------------------------------------------
' Private: Handles addConfigTelemetry field change event
' @param event (object) the addConfigTelemetry event data
' ----------------------------------------------------------------
sub __onAddConfigTelemetry(event as object)
    m.telemetryScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Adds a telemetry error event
' @param exception (object) the caught exception object
' ----------------------------------------------------------------
sub addErrorTelemetry(exception as object)
    m.top.addErrorTelemetry = addTelemetryErrorEvent(exception)
end sub

' ----------------------------------------------------------------
' Private: Handles addErrorTelemetry field change event
' @param event (object) the addErrorTelemetry event data
' ----------------------------------------------------------------
sub __onAddErrorTelemetry(event as object)
    m.telemetryScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Adds a telemetry debug event
' @param message (string) the message to send
' ----------------------------------------------------------------
sub addDebugTelemetry(message as string)
    m.top.addDebugTelemetry = addTelemetryDebugEvent(message)
end sub

' ----------------------------------------------------------------
' Private: Handles addDebugTelemetry field change event
' @param event (object) the addDebugTelemetry event data
' ----------------------------------------------------------------
sub __onAddDebugTelemetry(event as object)
    m.telemetryScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Starts a feature operation
' @param name (string) the operation name (e.g.: "login", "checkout")
' @param operationKey (dynamic) the operation key for distinguishing parallel
'     operations, or invalid for unkeyed operations
' @param context (object) an assocarray of custom attributes to add to the event
' ----------------------------------------------------------------
sub startOperation(name as string, operationKey = invalid as dynamic, context = {} as object)
    if (not __isValidOperationName(name))
        ' Backend rejects blank/empty names with its own non-empty
        ' precondition; drop client-side to match.
        ddLogError("RumAgent: startOperation called with blank name, ignoring")
        return
    end if
    if (not __operationNameMatchesBackendPattern(name))
        ' Warn but still emit: the backend is the source of truth on the
        ' character-set policy. Dropping client-side would force a customer
        ' SDK bump if the rule is ever relaxed.
        ddLogWarning("RumAgent: startOperation name '" + name + "' does not match the backend-accepted pattern [\w.@$-]* (letters, digits, _ . @ $ -). The event will still be sent and may be rejected by the backend.")
    end if
    if (not __isValidOperationKeyType(operationKey))
        ddLogError("RumAgent: startOperation called with invalid operationKey, ignoring")
        return
    end if
    if (__isOperationKeyBlank(operationKey))
        ' Warn but still emit: operationKey is optional, so a malformed value
        ' is never grounds to drop the step (canonical cross-SDK behavior).
        ddLogWarning("RumAgent: startOperation operationKey cannot be empty or contain only whitespace, but was '" + operationKey + "'. The event will still be sent.")
    end if
    m.top.startOperation = startFeatureOperationEvent(name, operationKey, context)
end sub

' ----------------------------------------------------------------
' Private: Handles startOperation field change event
' @param event (object) the startOperation event data
' ----------------------------------------------------------------
sub __onStartOperation(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Succeeds a feature operation
' @param name (string) the operation name (e.g.: "login", "checkout")
' @param operationKey (dynamic) the operation key for distinguishing parallel
'     operations, or invalid for unkeyed operations
' @param context (object) an assocarray of custom attributes to add to the event
' ----------------------------------------------------------------
sub succeedOperation(name as string, operationKey = invalid as dynamic, context = {} as object)
    if (not __isValidOperationName(name))
        ddLogError("RumAgent: succeedOperation called with blank name, ignoring")
        return
    end if
    if (not __operationNameMatchesBackendPattern(name))
        ' Warn but still emit — see startOperation comment.
        ddLogWarning("RumAgent: succeedOperation name '" + name + "' does not match the backend-accepted pattern [\w.@$-]* (letters, digits, _ . @ $ -). The event will still be sent and may be rejected by the backend.")
    end if
    if (not __isValidOperationKeyType(operationKey))
        ddLogError("RumAgent: succeedOperation called with invalid operationKey, ignoring")
        return
    end if
    if (__isOperationKeyBlank(operationKey))
        ' Warn but still emit — see startOperation comment.
        ddLogWarning("RumAgent: succeedOperation operationKey cannot be empty or contain only whitespace, but was '" + operationKey + "'. The event will still be sent.")
    end if
    m.top.succeedOperation = succeedFeatureOperationEvent(name, operationKey, context)
end sub

' ----------------------------------------------------------------
' Private: Handles succeedOperation field change event
' @param event (object) the succeedOperation event data
' ----------------------------------------------------------------
sub __onSucceedOperation(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Fails a feature operation
' @param name (string) the operation name (e.g.: "login", "checkout")
' @param failureReason (string) the failure reason (use "error", "abandoned", or "other")
' @param operationKey (dynamic) the operation key for distinguishing parallel
'     operations, or invalid for unkeyed operations
' @param context (object) an assocarray of custom attributes to add to the event
' ----------------------------------------------------------------
sub failOperation(name as string, failureReason as string, operationKey = invalid as dynamic, context = {} as object)
    if (not __isValidOperationName(name))
        ddLogError("RumAgent: failOperation called with blank name, ignoring")
        return
    end if
    if (not __operationNameMatchesBackendPattern(name))
        ' Warn but still emit — see startOperation comment.
        ddLogWarning("RumAgent: failOperation name '" + name + "' does not match the backend-accepted pattern [\w.@$-]* (letters, digits, _ . @ $ -). The event will still be sent and may be rejected by the backend.")
    end if
    if (not __isValidOperationKeyType(operationKey))
        ddLogError("RumAgent: failOperation called with invalid operationKey, ignoring")
        return
    end if
    if (__isOperationKeyBlank(operationKey))
        ' Warn but still emit — see startOperation comment.
        ddLogWarning("RumAgent: failOperation operationKey cannot be empty or contain only whitespace, but was '" + operationKey + "'. The event will still be sent.")
    end if
    if (not __isValidFailureReason(failureReason))
        ddLogError("RumAgent: failOperation called with invalid failureReason '" + failureReason + "', ignoring")
        return
    end if
    m.top.failOperation = failFeatureOperationEvent(name, operationKey, failureReason, context)
end sub

' ----------------------------------------------------------------
' Private: Handles failOperation field change event
' @param event (object) the failOperation event data
' ----------------------------------------------------------------
sub __onFailOperation(event as object)
    m.rumScope.callfunc("handleEvent", event, m.writer)
end sub

' ----------------------------------------------------------------
' Reports a batch of operations in a single rendezvous
' @param events (dynamic) an array of pre-built operation events, or invalid
' ----------------------------------------------------------------
sub __onReportOperations(events as dynamic)
    if (events <> invalid and m.rumScope <> invalid)
        for each event in events
            if (__isValidOperationEvent(event))
                if (not __operationNameMatchesBackendPattern(event.name))
                    ddLogWarning("RumAgent: reportOperations name '" + event.name + "' does not match the backend-accepted pattern [\w.@$-]* (letters, digits, _ . @ $ -). The event will still be sent and may be rejected by the backend.")
                end if
                if (__isOperationKeyBlank(event.operationKey))
                    ddLogWarning("RumAgent: reportOperations operationKey cannot be empty or contain only whitespace, but was '" + event.operationKey + "'. The event will still be sent.")
                end if
                m.rumScope.callfunc("handleEvent", event, m.writer)
            else
                ddLogError("RumAgent: reportOperations received an invalid operation event, ignoring")
            end if
        end for
    end if
end sub

' ----------------------------------------------------------------
' Returns true if a batched operation event carries a fundamentally valid
' name, operationKey type and (for fail events) failureReason. Mirrors only
' the hard-drop checks the single-item startOperation/succeedOperation/
' failOperation methods run before dispatching, which the batch path bypasses
' by taking pre-built events. Without it a bad key (e.g. a non-string) would
' crash the task in __operationLookupKey. Character-set / blank-key issues
' are warn-and-emit, not drop, and are handled separately in
' __onReportOperations after this returns true.
' @param event (dynamic) the pre-built operation event to validate
' @return (boolean) whether the event is safe to forward
' ----------------------------------------------------------------
function __isValidOperationEvent(event as dynamic) as boolean
    if (type(event) <> "roAssociativeArray")
        return false
    end if
    if (not __isValidOperationName(event.name))
        return false
    end if
    if (not __isValidOperationKeyType(event.operationKey))
        return false
    end if
    ' start/succeed events carry no failureReason (invalid is fine); fail events do
    if (event.failureReason <> invalid and not __isValidFailureReason(event.failureReason))
        return false
    end if
    return true
end function

' ----------------------------------------------------------------
' Returns true if the operation name is valid (a non-blank string after
' trimming). Accepts dynamic so it can guard pre-built batch events as well as
' the typed single-item callers.
' @param name (dynamic) the operation name to validate
' @return (boolean) whether the name is valid
' ----------------------------------------------------------------
function __isValidOperationName(name as dynamic) as boolean
    if (type(name) <> "roString" and type(name) <> "String")
        return false
    end if
    return name.Trim().Len() > 0
end function

' ----------------------------------------------------------------
' Returns true if the operation name matches the backend's server-side
' `[\w.@$-]*` validation regex. operation_key is a separate parameter
' and is not subject to this rule. The `*` quantifier means an empty
' string also matches.
' @param name (string) the operation name to validate
' @return (boolean) whether the name matches the backend pattern
' ----------------------------------------------------------------
function __operationNameMatchesBackendPattern(name as string) as boolean
    regex = CreateObject("roRegex", "^[\w.@$-]*$", "")
    return regex.IsMatch(name)
end function

' ----------------------------------------------------------------
' Returns true if the operationKey is of an acceptable type:
'   - invalid is VALID (means unkeyed operation)
'   - a string (blank or not) is VALID — blankness is checked separately
'     by __isOperationKeyBlank and only warns, never drops (operationKey
'     is optional, so a malformed value is never grounds to drop the step)
'   - non-string, non-invalid values are INVALID
' @param operationKey (dynamic) the operation key to validate
' @return (boolean) whether the key's type is acceptable
' ----------------------------------------------------------------
function __isValidOperationKeyType(operationKey as dynamic) as boolean
    if (operationKey = invalid)
        return true
    end if
    return (type(operationKey) = "roString" or type(operationKey) = "String")
end function

' ----------------------------------------------------------------
' Returns true if operationKey was provided as a string but is empty or
' whitespace-only after trimming. Does not flag `invalid` (unkeyed) as
' blank. Callers should only invoke this after __isValidOperationKeyType
' has confirmed the key is a string or invalid.
' @param operationKey (dynamic) the operation key to check
' @return (boolean) whether the key is a blank/whitespace-only string
' ----------------------------------------------------------------
function __isOperationKeyBlank(operationKey as dynamic) as boolean
    if (type(operationKey) <> "roString" and type(operationKey) <> "String")
        return false
    end if
    return operationKey.Trim().Len() = 0
end function

' ----------------------------------------------------------------
' Returns true if the failureReason is a known FailureReason value. Accepts
' dynamic so it can guard pre-built batch events as well as the typed
' single-item callers.
' @param reason (dynamic) the failure reason to validate
' @return (boolean) whether the failure reason is valid
' ----------------------------------------------------------------
function __isValidFailureReason(reason as dynamic) as boolean
    if (type(reason) <> "roString" and type(reason) <> "String")
        return false
    end if
    return (reason = "error" or reason = "abandoned" or reason = "other")
end function