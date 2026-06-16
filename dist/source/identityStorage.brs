' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/internalLogger.bs"
' ****************************************************************
' * Persistent storage for SDK identity values (anonymous_id, ...).
' * Backed by the per-channel Roku registry.
' ****************************************************************

' ----------------------------------------------------------------
' Reads the persisted Datadog anonymous id from the Roku registry.
' @return (string) the stored value, or "" when absent.
' ----------------------------------------------------------------
function readDatadogAnonymousId() as string
    section = CreateObject("roRegistrySection", "datadog")
    if (section = invalid or not section.Exists("anonymous_id"))
        return ""
    end if
    return section.Read("anonymous_id")
end function

' ----------------------------------------------------------------
' Persists the Datadog anonymous id to the Roku registry so it
' survives channel relaunches (browser-cookie equivalent).
' @param anonymousId (string) the value to store.
' ----------------------------------------------------------------
sub writeDatadogAnonymousId(anonymousId as string)
    section = CreateObject("roRegistrySection", "datadog")
    if (section = invalid)
        ddLogWarning("Unable to persist anonymous_id: registry section unavailable")
        return
    end if
    section.Write("anonymous_id", anonymousId)
    section.Flush()
end sub

' ----------------------------------------------------------------
' Removes any persisted Datadog anonymous id from the Roku registry.
' Called when anonymous user tracking is disabled, so the identifier
' does not outlive the integrator's consent state.
' ----------------------------------------------------------------
sub clearDatadogAnonymousId()
    section = CreateObject("roRegistrySection", "datadog")
    if (section = invalid or not section.Exists("anonymous_id"))
        return
    end if
    section.Delete("anonymous_id")
    section.Flush()
end sub