' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Trigger an exception
' @param errorIndex (integer) the index of the error to trigger (between 0 and 8)
' ----------------------------------------------------------------
sub explodingMethod(errorIndex as integer)
    errorType = errorIndex mod 8
    x = 1
    y = 0

    if (errorType = 0)
        print x.foo ' &h02 Syntax Error
    else if (errorType = 1)
        print recursiveSub() ' &hDF Stack overflow.
    else if (errorType = 2)
        print (x / y) ' &h14 Divide by Zero.
    else if (errorType = 3)
        subWithNoParam(x, y) ' &hF1: Wrong number of function parameters.
    else if (errorType = 4)
        x.foo() ' &hF4 Member function not found in object or interface
    else if (errorType = 5)
        functionDoesntExist() ' &hE0 Function Call Operator ( ) attempted on non-function.
    else if (errorType = 6)
        print (x << 33) ' &h1E Invalid Bitwise Shift.
    else if (errorType = 7)
        print unknownVar.value ' &hEC 'Dot' Operator attempted with invalid BrightScript Component or interface reference.
    end if
end sub

' ---------------------------------------------------------------
' A no-op method with no parameter
' ---------------------------------------------------------------
sub subWithNoParam()
end sub

' ---------------------------------------------------------------
' A recursive method, which will trigger a stack overflow
' ---------------------------------------------------------------
function recursiveSub() as string
    return recursiveSub()
end function

