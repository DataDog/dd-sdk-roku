' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ****************************************************************
' * RumScope: generic Rum Scope (interface)
' ****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    logVerbose("RumScope::init()")
end sub

' ----------------------------------------------------------------
' Returns the current context from this scope
' @returns (object) the current context
' ----------------------------------------------------------------
function getRumContext() as object
    logVerbose("RumScope::getRumContext()")
    return invalid
end function

' ----------------------------------------------------------------
' Handles an internal event
' @param event (object) the event to handle
' @param writer (object) the writer node (see WriterTask.brs)
' ----------------------------------------------------------------
sub handleEvent(event as object, writer as object)
    logVerbose("RumScope::handleEvent(" + FormatJson(event) + ", writer)")
end sub

' ----------------------------------------------------------------
' Returns information about whether the current scope can handle more events or not
' @return (boolean) `true` if this scope expects more event, `false` if it's complete
' ----------------------------------------------------------------
function isActive() as boolean
    logVerbose("RumScope::isActive()")
    ' TODO
    return invalid
end function