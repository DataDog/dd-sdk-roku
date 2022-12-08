' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Initializes the SDK
' @param configuration (object) an Associative Array with the following fields
'  - clientToken (string) the token used to upload data to Datadog
'  - applicationId (string) the application id to be used in RUM events
'  - site (string) the site to send data to (one of "us1", "us3", "us5", "eu1")
'  - service (string) the name of the service to report in logs and RUM events
'  - env (string) the name of the environment to report in logs and RUM events
' ----------------------------------------------------------------
sub initialize(configuration as object)
    ' Standard global fields
    m.global.addFields({
        datadogVerbosity: 0
        datadogContext: {}
        datadogUserInfo: {}
    })
    if (m.global.datadogUploader = invalid)
        ddLogInfo("No uploader, creating one")
        m.global.addFields({
            datadogUploader: CreateObject("roSGNode", "MultiTrackUploaderTask")
        })
        m.global.datadogUploader.clientToken = configuration.clientToken
    end if
    if (m.global.datadogRumAgent = invalid)
        ddLogInfo("No RUM agent, creating one")
        m.global.addFields({
            datadogRumAgent: CreateObject("roSGNode", "RumAgent")
        })
        m.global.datadogRumAgent.site = configuration.site
        m.global.datadogRumAgent.clientToken = configuration.clientToken
        m.global.datadogRumAgent.applicationId = configuration.applicationId
        m.global.datadogRumAgent.service = configuration.service
        m.global.datadogRumAgent.uploader = m.global.datadogUploader
    end if
    if (m.global.datadogLogsAgent = invalid)
        ddLogInfo("No Logs agent, creating one")
        m.global.addFields({
            datadogLogsAgent: CreateObject("roSGNode", "LogsAgent")
        })
        m.global.datadogLogsAgent.site = configuration.site
        m.global.datadogLogsAgent.clientToken = configuration.clientToken
        m.global.datadogLogsAgent.service = configuration.service
        m.global.datadogLogsAgent.env = configuration.env
        m.global.datadogLogsAgent.uploader = m.global.datadogUploader
    end if
end sub
' ----------------------------------------------------------------
' The available track types for the uploader/writer
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' The available Datadog sites for the uploader
' ----------------------------------------------------------------


' ----------------------------------------------------------------
' @return (string) the version of the library
' TODO generate this from the package.json
' ----------------------------------------------------------------
function sdkVersion() as string
    return "1.0.0-dev"
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
    return getEndpoint(site, track) + "/api/v2/" + track
end function

' ----------------------------------------------------------------
' @param site (Site) the site to use
' @param track (Track) the track to use
' @return (string) the endpoint for the given track and site
' ----------------------------------------------------------------
function getEndpoint(site as object, track as object) as string
    endpoints = {
        rum: {
            us1: "https://rum.browser-intake-datadoghq.com"
            us3: "https://rum.browser-intake-us3-datadoghq.com"
            us5: "https://rum.browser-intake-us5-datadoghq.com"
            eu1: "https://rum-http-intake.logs.datadoghq.eu"
        }
        logs: {
            us1: "https://logs.browser-intake-datadoghq.com"
            us3: "https://logs.browser-intake-us3-datadoghq.com"
            us5: "https://logs.browser-intake-us5-datadoghq.com"
            eu1: "https://mobile-http-intake.logs.datadoghq.eu"
        }
    }
    trackEndpoints = endpoints[track]
    if (trackEndpoints = invalid)
        ddLogError("Unknown track " + track + ", can't find the relevant Datadog endpoint")
        return ""
    end if
    endpoint = trackEndpoints[site]
    if (endpoint = invalid)
        ddLogError("Unknown site " + site + ", can't find the relevant Datadog endpoint")
        return ""
    end if
    return endpoint
end function