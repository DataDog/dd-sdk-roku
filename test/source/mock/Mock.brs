' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
' Mock
' Handles all mock related logic
'*****************************************************************

' ----------------------------------------------------------------
' Mock constructor
' ----------------------------------------------------------------
function Mock() as object
    instance = {
        calls: [],
        stubs: [],
        fieldUpdates: []
    }

    instance.reset = Mock__reset
    instance.recordFunctionCall = Mock__recordFunctionCall
    instance.recordFieldUpdate = Mock__recordFieldUpdate
    instance.stubCall = Mock__stubCall
    instance.assertFunctionCalled = Mock__assertFunctionCalled
    instance.assertNoInteractions = Mock__assertNoInteractions
    instance.getFieldUpdates = Mock__getFieldUpdates
    instance.getStubReturnValue = Mock__getStubReturnValue

    return instance
end function

' ----------------------------------------------------------------
' Resets all stubs and recorded calls
' ----------------------------------------------------------------
sub Mock__reset()
    m.calls = []
    m.stubs = []
    m.fieldUpdates = []
end sub

' ----------------------------------------------------------------
' Records a function as being called
' @param functionName (string) the name of the function called
' @param params (object) the parameters for the function
' ----------------------------------------------------------------
sub Mock__recordFunctionCall(functionName as string, params as object)
    datadogroku_logInfo("Recording Function Call on mock: " + functionName)
    m.calls.Push({
        functionName: functionName,
        params: params,
        consumed: false
    })
end sub

' ----------------------------------------------------------------
' Records a field as being updated
' @param fieldname (string) the name of the field
' @param value (dynamic) the value of the field
' ----------------------------------------------------------------
sub Mock__recordFieldUpdate(fieldName as string, value as dynamic)
    m.fieldUpdates.Push({
        fieldName: fieldName,
        value: value
    })
end sub

' ----------------------------------------------------------------
' Prepares the mock to return a given value for a function call
' @param functionName (string) the name of the function to stub
' @param params (object) the parameters for the function. If a
'     parameter is not given, it means any value will be a match
' @param returnValue (dynamic) the value to return
' ----------------------------------------------------------------
sub Mock__stubCall(functionName as string, params as object, returnValue as dynamic)
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
' @param times (integer) the expected number of times the method is called (default is 1)
'     a positive value means "exactly" (e.g.: 5 means exactly 5 times)
'     a negative value means "at least the absolute value" (e.g.: -1 means at least once)
' @return (string) an empty string if there is a match, or an error
'     message
' ----------------------------------------------------------------
function Mock__assertFunctionCalled(functionName as string, params as object, times = 1 as integer) as string
    wrongParams = ""
    matchedCalls = 0
    for each call in m.calls
        if (call.functionName = functionName and not call.consumed)
            isMatch = true
            for each param in params
                if (not checkParamMatch(params[param], call.params[param]))
                    wrongParams += chr(10) + " - " + functionName + "() was called with params " + TF_Utils__AsString(call.params)
                    wrongParams += chr(10) + " - - > first mismatched param: " + param
                    isMatch = false
                end if
            end for
            if (isMatch)
                call.consumed = true
                matchedCalls++
            end if
        end if
    end for

    if (times >= 0 and matchedCalls = times)
        ' exact match
        return ""
    else if (times < 0 and matchedCalls >= -times)
        ' at least match
        return ""
    else if (matchedCalls > 0)
        ' invalid count
        if (times >= 0)
            return "Expected exactly " + times.toStr() + " call(s) to " + functionName + " but function was called " + matchedCalls.toStr() + " time(s)"
        else
            return "Expected at least " + (-times).toStr() + " call(s) to " + functionName + " but function was called " + matchedCalls.toStr() + " time(s)"
        end if
    else
        ' no match found, means invalid params
        if (wrongParams = "")
            wrongParams = chr(10) + " - " + functionName + "() was never called"
        end if
        return "Expected call to " + functionName + " with params " + TF_Utils__AsString(params) + wrongParams
    end if
end function

' ----------------------------------------------------------------
' Verifies that the current mock was never called
' @return (string) an empty string if there was no calls, or an error
'     message
' ----------------------------------------------------------------
function Mock__assertNoInteractions() as string
    if (m.calls.count() = 0)
        return ""
    end if

    return "Expected no interactions with mock but mock was called " + m.calls.count().toStr() + " times"
end function

' ----------------------------------------------------------------
' @param fieldName (string) the name of the field
' @return (object) an array with all the updated values of the field
' ----------------------------------------------------------------
function Mock__getFieldUpdates(fieldName as string) as object
    result = []
    for each update in m.fieldUpdates
        if (update.fieldName = fieldName)
            result.Push(update.value)
        end if
    end for
    return result
end function

' ----------------------------------------------------------------
' Returns a previously stubbed value if the parameters match
' @param functionName (string) the name of the function called
' @param params (object) the parameters for the call
' @return (dynamic) the previously stubbed value, or invalid
' ----------------------------------------------------------------
function Mock__getStubReturnValue(functionName as string, params as object) as dynamic
    wrongParams = ""
    for each stub in m.stubs
        if (stub.functionName = functionName)
            isMatch = true
            for each param in params
                if (not checkParamMatch(stub.params[param], params[param]))
                    wrongParams += chr(10) + " - " + functionName + "() was stubbed with params " + TF_Utils__AsString(stub.params)
                    wrongParams += chr(10) + " - - > first mismatched param: " + param
                    isMatch = false
                end if
            end for
            if (isMatch)
                return stub.returnValue
            end if
        end if
    end for

    datadogroku_logWarning("No stub match found for" + functionName + "(" + TF_Utils__AsString(params) + "):" + wrongParams)
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
    else if (actual = invalid)
        return expected = invalid
    else if (TF_Utils__IsString(expected) and TF_Utils__IsString(actual))
        return expected = actual
    else if (TF_Utils__IsSGNode(expected) and TF_Utils__IsSGNode(actual))
        return expected.subtype() = actual.subtype()
    else if (TF_Utils__IsArray(expected) and TF_Utils__IsArray(actual))
        return checkArrayMatch(expected, actual)
    else if (TF_Utils__IsAssociativeArray(expected) and TF_Utils__IsAssociativeArray(actual))
        return checkAssocArrayMatch(expected, actual)
    else if (TF_Utils__IsNumber(expected) and TF_Utils__IsNumber(actual))
        return expected = actual
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
            print "-->> assoc array mismatch for key " + key + " <" + TF_Utils__AsString(expectedValue) + "> != <" + TF_Utils__AsString(actualValue) + "> "
            return false
        end if
    end for
    return true
end function

' ----------------------------------------------------------------
' Verifies whether the two Arrays actually match
' @param expected (object) the expected value to test
' @param actual (object) the actual value used
' @return (boolean) true if objects values match each other
' ----------------------------------------------------------------
function checkArrayMatch(expected as object, actual as object) as boolean
    if (expected.count() <> actual.count())
        return false
    end if

    count = expected.count()

    for i = 0 to count - 1
        expectedValue = expected[i]
        actualValue = actual[i]
        if (not checkParamMatch(expectedValue, actualValue))
            print "-->> array mismatch at index " + i + " <" + TF_Utils__AsString(expectedValue) + "> != <" + TF_Utils__AsString(actualValue) + "> "
            return false
        end if
    end for
    return true
end function
