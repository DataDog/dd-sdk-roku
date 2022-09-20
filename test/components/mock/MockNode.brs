' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

sub init()
    m.mock = Mock()
end sub

' ----------------------------------------------------------------
' Resets all stubs and recorded calls
' ----------------------------------------------------------------
sub reset()
    m.mock.reset()
end sub

' ----------------------------------------------------------------
' Records a function as being called
' @param functionName (string) the name of the function called
' @param params (object) the parameters for the function
' ----------------------------------------------------------------
sub recordFunctionCall(functionName as string, params as object)
    m.mock.recordFunctionCall(functionName, params)
end sub

' ----------------------------------------------------------------
' Records a field as being updated
' @param fieldname (string) the name of the field
' @param value (dynamic) the value of the field
' ----------------------------------------------------------------
sub recordFieldUpdate(fieldName as string, value as dynamic)
    m.mock.recordFieldUpdate(fieldName, value)
end sub

' ----------------------------------------------------------------
' Prepares the mock to return a given value for a function call
' @param functionName (string) the name of the function to stub
' @param params (object) the parameters for the function. If a
'     parameter is not given, it means any value will be a match
' @param returnValue (dynamic) the value to return
' ----------------------------------------------------------------
sub stubCall(functionName as string, params as object, returnValue as dynamic)
    m.mock.stubCall(functionName, params, returnValue)
end sub

' ----------------------------------------------------------------
' Verifies if the given function was actually called
' @param functionName (string) the name of the function to check
' @param params (object) the parameters for the function. If a
'     parameter is not given, it means any value is a match
' @return (string) an empty string if there is a match, or an error
'     message
' ----------------------------------------------------------------
function assertFunctionCalled(functionName as string, params as object) as string
    return m.mock.assertFunctionCalled(functionName, params)
end function

' ----------------------------------------------------------------
' @param fieldName (string) the name of the field
' @return (object) an array with all the updated values of the field
' ----------------------------------------------------------------
function getFieldUpdates(fieldName as string) as object
    return m.mock.getFieldUpdates(fieldName)
end function

' ----------------------------------------------------------------
' Verifies that the current mock was never called
' @return (string) an empty string if there was no calls, or an error
'     message
' ----------------------------------------------------------------
function assertNoInteractions() as string
    return m.mock.assertNoInteractions()
end function

' ----------------------------------------------------------------
' Returns a previously stubbed value if the parameters match
' @param functionName (string) the name of the function called
' @param params (object) the parameters for the call
' @return (dynamic) the previously stubbed value, or invalid
' ----------------------------------------------------------------
function getStubReturnValue(functionName as string, params as object) as dynamic
    return m.mock.getStubReturnValue(functionName, params)
end function
