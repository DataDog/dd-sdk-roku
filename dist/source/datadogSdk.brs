' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Initializes the SDK
' @param configuration (object) an Associative Array with the following fields
'  - clientToken (string) the token used to upload data to Datadog
'  - applicationId (string) the application id to be used in RUM events
'  - site (string) the site to send data to (one of "us1", "us3", "us5", "eu1")
'  - env (string) the name of the environment to report in logs and RUM events
'  - sessionSampleRate (integer) the rate of session to keep and send to Datadog
'     as an integer between 0 and 100 (default is 100)
'  - service (string, optional) the name of the service to report in logs and RUM events
'  - version (string, optional) the version of the channel to report in logs and RUM events
'  - traceSampleRate (integer, optional) the rate of traces to keep when instrumenting network request
'     as an integer between 0 and 100 (default is 100)
'  - tracingHeaderTypes (array) a array of associative arrays. Each array item must have the following entries:
'       - 'host': the host name  for which requests will have a trace generated (e.g.: example.com)
'       - 'header': either a single tracing header type, or an array of tracing header types. When several
'           types are provided for a host, all of them are injected into the request (sharing the same trace
'           and span ids), matching the Datadog Browser SDK `allowedTracingUrls` behavior. Supported values:
'           - "b3": Open Telemetry B3 Single header (cf: https://github.com/openzipkin/b3-propagation#single-header)
'           - "b3multi": Open Telemetry B3 Multiple header (cf: https://github.com/openzipkin/b3-propagation#multiple-headers)
'           - "tracecontext": W3C Trace Context header (cf: https://www.w3.org/TR/trace-context/)
'           - "datadog": Datadog's `x-datadog-*` headers (cf: https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces)
'  - traceContextInjection (string) defines whether the trace context should be injected into all requests or only sampled ones.
'  - ignoredExitEvents (array, optional) an array of exit status strings to ignore when detecting crashes.
'     Any exit status NOT in this list will be reported as a crash. Defaults to:
'     ["EXIT_UNKNOWN", "EXIT_POWER_MODE", "EXIT_IDLE_AUTO_EXIT", "EXIT_DIAL_DELETE", "EXIT_USER_KILL", "EXIT_USER_NAV"]
' @param global (object) the global node available from any node in the scenegraph
' ----------------------------------------------------------------
sub initialize(configuration as object, global as object)
    ddLogThread("initialize")
    launchArgs = (function(configuration)
            __bsConsequent = configuration.launchArgs
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return {}
            end if
        end function)(configuration)
    service = (function(channelServiceName, configuration)
            __bsConsequent = configuration.service
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return channelServiceName()
            end if
        end function)(channelServiceName, configuration)
    version = (function(channelVersion, configuration)
            __bsConsequent = configuration.version
            if __bsConsequent <> invalid then
                return __bsConsequent
            else
                return channelVersion()
            end if
        end function)(channelVersion, configuration)
    deviceInfo = CreateObject("roDeviceInfo")
    deviceName = deviceInfo.GetModelDisplayName()
    deviceModel = deviceInfo.GetModel()
    deviceOsVersion = deviceInfo.GetOSVersion()
    deviceOsVersionFull = deviceOsVersion.major + "." + deviceOsVersion.minor + "." + deviceOsVersion.revision
    ' Standard global fields
    global.addFields({
        datadogContext: {}
        datadogUserInfo: {}
    })
    if (configuration.clientToken = invalid or configuration.clientToken = "")
        ddLogError("Trying to initialize the Datadog SDK without a Client Token, please check your configuration.")
        return
    end if
    datadogUploader = global.datadogUploader
    if (datadogUploader = invalid)
        ddLogInfo("No uploader, creating one")
        datadogUploader = CreateObject("roSGNode", "MultiTrackUploaderTask")
        datadogUploader.clientToken = configuration.clientToken
        datadogUploader.control = "RUN"
        global.addFields({
            datadogUploader: datadogUploader
        })
    end if
    if (configuration.applicationId = invalid or configuration.applicationId = "")
        ddLogWarning("Trying to initialize the Datadog SDK without a RUM Application Id, please check your configuration.")
        return
    else if (global.datadogRumAgent = invalid)
        ddLogInfo("No RUM agent, creating one")
        ' Create the RUM context synchronously so any early log can observe it
        ' before the RumAgent task fills in the rest.
        global.addFields({
            datadogRumContext: {
                applicationId: configuration.applicationId
            }
        })
        rumAgent = CreateObject("roSGNode", "RumAgent")
        rumAgent.setFields({
            site: configuration.site
            env: (function(configuration)
                    __bsConsequent = configuration.env
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return ""
                    end if
                end function)(configuration)
            applicationId: configuration.applicationId
            service: service
            version: version
            uploader: datadogUploader
            sessionSampleRate: (function(configuration)
                    __bsConsequent = configuration.sessionSampleRate
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return 100
                    end if
                end function)(configuration)
            lastExitOrTerminationReason: launchArgs.lastExitOrTerminationReason
            deviceName: deviceName
            deviceModel: deviceModel
            osVersion: deviceOsVersionFull
            osVersionMajor: deviceOsVersion.major
            configuration: configuration
        })
        rumAgent.control = "RUN"
        global.addFields({
            datadogRumAgent: rumAgent
        })
    end if
    if (global.datadogLogsAgent = invalid)
        ddLogInfo("No Logs agent, creating one")
        agent = CreateObject("roSGNode", "LogsAgent")
        agent.setFields({
            site: configuration.site
            env: (function(configuration)
                    __bsConsequent = configuration.env
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return ""
                    end if
                end function)(configuration)
            service: service
            version: version
            uploader: datadogUploader
            deviceName: deviceName
            deviceModel: deviceModel
            osVersion: deviceOsVersionFull
            osVersionMajor: deviceOsVersion.major
        })
        global.addFields({
            datadogLogsAgent: agent
        })
    end if
    if (configuration.ignoredExitEvents <> invalid and configuration.ignoredExitEvents.count() = 0)
        ddLogWarning("configuration.ignoredExitEvents is empty; all exit statuses will be reported as crashes.")
    end if
    global.addFields({
        datadogTraceAgent: {
            traceSampleRate: (function(configuration)
                    __bsConsequent = configuration.traceSampleRate
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return 100
                    end if
                end function)(configuration)
            tracingHeaderTypes: (function(configuration)
                    __bsConsequent = configuration.tracingHeaderTypes
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return {}
                    end if
                end function)(configuration)
            traceContextInjection: (function(configuration)
                    __bsConsequent = configuration.traceContextInjection
                    if __bsConsequent <> invalid then
                        return __bsConsequent
                    else
                        return "sampled"
                    end if
                end function)(configuration)
        }
        datadogIgnoredExitEvents: (function(configuration)
                __bsConsequent = configuration.ignoredExitEvents
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return [
                        "EXIT_UNKNOWN"
                        "EXIT_POWER_MODE"
                        "EXIT_IDLE_AUTO_EXIT"
                        "EXIT_DIAL_DELETE"
                        "EXIT_USER_KILL"
                        "EXIT_USER_NAV"
                    ]
                end if
            end function)(configuration)
    })
end sub
' ----------------------------------------------------------------
' The available tracing header types that can be injected into http requests.
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' The available track types for the uploader/writer
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' The available Datadog sites for the uploader
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' Defines whether the trace context should be injected into all requests or only sampled ones.
' ----------------------------------------------------------------


' ----------------------------------------------------------------
' @return (string) the service name of the library
' ----------------------------------------------------------------
function sdkServiceName() as string
    return "dd-sdk-roku"
end function

' ----------------------------------------------------------------
' @return (string) the version of the library
' TODO generate this from the package.json
' ----------------------------------------------------------------
function sdkVersion() as string
    return "1.5.0"
end function

' ----------------------------------------------------------------
' @return (string) the service name of the host channel
' (read from the manifest)
' ----------------------------------------------------------------
function channelServiceName() as string
    title = LCase(CreateObject("roAppInfo").GetTitle()) ' use lowercase version of title
    titleLen = title.Len()
    serviceName = ""
    for i = 1 to (titleLen)
        c = Asc(Mid(title, i, 1))
        ' allowed characters :
        '   - 45
        '   "." 46
        '   / 47
        '   "0-9" 48 to 57
        '   ":" 58
        '   "_" 95
        '   "a-z" 97 to 122
        if (c < 45 or (c > 58 and c < 95) or c = 96 or c > 122)
            serviceName = serviceName + "_"
        else
            serviceName = serviceName + chr(c)
        end if
    end for
    return serviceName
end function

' ----------------------------------------------------------------
' @return (string) the version of the host channel
' (read from the manifest)
' ----------------------------------------------------------------
function channelVersion() as string
    return CreateObject("roAppInfo").GetVersion()
end function

' ----------------------------------------------------------------
' @return (string) the source to report in events
' ----------------------------------------------------------------
function agentSource() as string
    return "roku"
end function

' ----------------------------------------------------------------
' @param site (Site) the site to use
' @param track (Track) the track to use
' @return (string) the upload url for the given track and site
' ----------------------------------------------------------------
function getIntakeUrl(site as object, track as object) as string
    return getEndpoint(site) + "/api/v2/" + track
end function

' ----------------------------------------------------------------
' @param site (Site) the site to use
' @return (string) the endpoint for the given track and site
' ----------------------------------------------------------------
function getEndpoint(site as object) as string
    endpoints = {
        us1: "https://browser-intake-datadoghq.com"
        us3: "https://browser-intake-us3-datadoghq.com"
        us5: "https://browser-intake-us5-datadoghq.com"
        eu1: "https://browser-intake-datadoghq.eu"
        ap1: "https://browser-intake-ap1-datadoghq.com"
        ap2: "https://browser-intake-ap2-datadoghq.com"
        staging: "https://browser-intake-datad0g.com"
    }
    endpoint = endpoints[site]
    if (endpoint = invalid)
        ddLogError("Unknown site " + site + ", can't find the relevant Datadog endpoint")
        return ""
    end if
    return endpoint
end function