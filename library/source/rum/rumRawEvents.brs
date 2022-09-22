' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
'* Utilities to generate internal RUM events
'*****************************************************************

' ----------------------------------------------------------------
' @param viewName (string) the view name (human-readable)
' @param viewUrl (string) the view url (developer identifier)
' @return (object) an event describing an startView action
' ----------------------------------------------------------------
function startViewEvent(viewName as string, viewUrl as string) as object
    return {
        eventType: "startView",
        viewName: viewName,
        viewUrl: viewUrl
    }
end function

' ----------------------------------------------------------------
' @param viewName (string) the view name (human-readable)
' @param viewUrl (string) the view url (developer identifier)
' @return (object) an event describing an stopView action
' ----------------------------------------------------------------
function stopViewEvent(viewName as string, viewUrl as string) as object
    return {
        eventType: "stopView",
        viewName: viewName,
        viewUrl: viewUrl
    }
end function

' ----------------------------------------------------------------
' @param exception (object) the caught exception
' @return (object) an event describing an addError action
' ----------------------------------------------------------------
function addErrorEvent(exception as object) as object
    return {
        eventType: "addError",
        exception: exception
    }
end function

' ----------------------------------------------------------------
' @param resource (object) the resource object
' @return (object) an event describing an addResource action
' ----------------------------------------------------------------
function addResourceEvent(resource as object) as object
    return {
        eventType: "addResource",
        resource: resource
    }
end function
