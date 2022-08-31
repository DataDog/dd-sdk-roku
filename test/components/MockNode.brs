' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

sub init()
    m.calls = []
    m.stubs = []
end sub

' ----------------------------------------------------------------
' Resets all stubs and recorded calls
' ----------------------------------------------------------------
sub reset()
    m.calls = []
    m.stubs = []
end sub

' ----------------------------------------------------------------
' Records a function as being called
' @param functionName (string) the name of the function called
' @param params (object) the parameters for the function
' ----------------------------------------------------------------
sub recordFunctionCall(functionName as string, params as object)
    m.calls.Push({
        functionName: functionName,
        params: params,
        consumed: false
    })
end sub

' ----------------------------------------------------------------
' Prepares the mock to return a given value for a function call
' @param functionName (string) the name of the function to stub
' @param params (object) the parameters for the function. If a
'     parameter is not given, it means any value will be a match
' @param returnValue (dynamic) the value to return
' ----------------------------------------------------------------
sub stubCall(functionName as string, params as object, returnValue as dynamic)
    m.stubs.Push({
        functionName: functionName,
        params: params,
        returnValue: returnValue
    })
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
    wrongParams = ""
    for each call in m.calls
        if (call.functionName = functionName and not call.consumed)
            isMatch = true
            for each param in params
                if (not checkParamMatch(params[param], call.params[param]))
                    wrongParams += chr(10) + " - " + functionName + "() was called with params " + FormatJson(call.params)
                    isMatch = false
                end if
            end for
            if (isMatch)
                call.consumed = true
                return ""
            end if
        end if
    end for

    return "Expected call to " + functionName + " with params " + FormatJson(params) + wrongParams
end function

' ----------------------------------------------------------------
' Verifies that the current mock was never called
' @return (string) an empty string if there was no calls, or an error
'     message
' ----------------------------------------------------------------
function assertNoInteractions() as string
    if (m.calls.count() = 0)
        return ""
    end if

    return "Expected no interactions with mock but mock was called " + m.calls.count().toStr() + " times"
end function

' ----------------------------------------------------------------
' Returns a previously stubbed value if the parameters match
' @param functionName (string) the name of the function called
' @param params (object) the parameters for the call
' @return (dynamic) the previously stubbed value, or invalid
' ----------------------------------------------------------------
function getStubReturnValue(functionName as string, params as object) as dynamic
    for each stub in m.stubs
        if (stub.functionName = functionName)
            isMatch = true
            for each param in params
                if (stub.params[param] <> params[param])
                    isMatch = false
                end if
            end for
            if (isMatch)
                return stub.returnValue
            end if
        end if
    end for
    return invalid
end function

' ----------------------------------------------------------------
' Verifies whether the two values actually match
' @param expected (dynamic) the expected value to test
' @param actual (dynamic) the actual value used
' @return (boolean) true if both values match each other
' ----------------------------------------------------------------
function checkParamMatch(expected as dynamic, actual as dynamic) as boolean
    if (expected = invalid)
        return actual = invalid
    end if

    if (actual = invalid)
        return expected = invalid
    end if

    if (TF_Utils__IsString(expected) and TF_Utils__IsString(actual))
        return expected = actual
    end if

    if (TF_Utils__IsAssociativeArray(expected) and TF_Utils__IsAssociativeArray(actual))
        return checkAssocArrayMatch(expected, actual)
    end if

    expectedType = type(expected)
    actualType = type(actual)
    print "comparing type " + expectedType + " with type " + actualType
    return false
end function

' ----------------------------------------------------------------
' Verifies whether the two Associative Arrays actually match
' @param expected (object) the expected value to test
' @param actual (object) the actual value used
' @return (boolean) true if objects values match each other
' ----------------------------------------------------------------
function checkAssocArrayMatch(expected as object, actual as object) as boolean
    for each key in expected
        expectedValue = expected[key]
        actualValue = actual[key]
        if (not checkParamMatch(expectedValue, actualValue))
            return false
        end if
    end for

    return true
end function

