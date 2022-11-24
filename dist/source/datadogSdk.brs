' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'*****************************************************************
'* "Constants" for the SDK
'*****************************************************************
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