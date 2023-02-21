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
'     as an integer between 0 and 100
'  - service (string, optional) the name of the service to report in logs and RUM events
'  - version (string, optional) the version of the channel to report in logs and RUM events
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
    if (global.datadogUploader = invalid)
        ddLogInfo("No uploader, creating one")
        uploader = CreateObject("roSGNode", "MultiTrackUploaderTask")
        global.addFields({
            datadogUploader: uploader
        })
        global.datadogUploader.clientToken = configuration.clientToken
    end if
    if (configuration.applicationId = invalid or configuration.applicationId = "")
        ddLogWarning("Trying to initialize the Datadog SDK without a RUM Application Id, please check your configuration.")
        return
    else if (global.datadogRumAgent = invalid)
        ddLogInfo("No RUM agent, creating one")
        global.addFields({
            datadogRumAgent: CreateObject("roSGNode", "RumAgent")
        })
        global.datadogRumAgent.site = configuration.site
        global.datadogRumAgent.clientToken = configuration.clientToken
        global.datadogRumAgent.applicationId = configuration.applicationId
        global.datadogRumAgent.service = service
        global.datadogRumAgent.version = version
        global.datadogRumAgent.uploader = global.datadogUploader
        global.datadogRumAgent.sessionSampleRate = (function(configuration)
                __bsConsequent = configuration.sessionSampleRate
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return 100
                end if
            end function)(configuration)
        global.datadogRumAgent.lastExitOrTerminationReason = launchArgs.lastExitOrTerminationReason
        global.datadogRumAgent.configuration = configuration
        global.datadogRumAgent.deviceName = deviceName
        global.datadogRumAgent.deviceModel = deviceModel
        global.datadogRumAgent.osVersion = deviceOsVersionFull
        global.datadogRumAgent.osVersionMajor = deviceOsVersion.major
    end if
    if (global.datadogLogsAgent = invalid)
        ddLogInfo("No Logs agent, creating one")
        global.addFields({
            datadogLogsAgent: CreateObject("roSGNode", "LogsAgent")
        })
        global.datadogLogsAgent.site = configuration.site
        global.datadogLogsAgent.clientToken = configuration.clientToken
        global.datadogLogsAgent.service = configuration.service
        global.datadogLogsAgent.env = configuration.env
        global.datadogLogsAgent.uploader = global.datadogUploader
        global.datadogLogsAgent.deviceName = deviceName
        global.datadogLogsAgent.deviceModel = deviceModel
        global.datadogLogsAgent.osVersion = deviceOsVersionFull
        global.datadogLogsAgent.osVersionMajor = deviceOsVersion.major
    end if
end sub
' ----------------------------------------------------------------
' The available track types for the uploader/writer
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' The available Datadog sites for the uploader
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
    return "1.0.0-dev"
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
        staging: "https://browser-intake-datad0g.com"
    }
    endpoint = endpoints[site]
    if (endpoint = invalid)
        ddLogError("Unknown site " + site + ", can't find the relevant Datadog endpoint")
        return ""
    end if
    return endpoint
end function