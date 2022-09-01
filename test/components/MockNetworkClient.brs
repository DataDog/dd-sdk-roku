' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.


'*****************************************************************
'* MockNetworkClient: a mock for the NetworkClient component.
'*****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
end sub

' ----------------------------------------------------------------
' @see NetworkClient.brs
' ----------------------------------------------------------------
function postFromFile(url as string, filePath as string, headers as object) as integer
    recordFunctionCall("postFromFile", { url: url, filePath: filePath, headers: headers })
    returnValue = getStubReturnValue("postFromFile", { url: url, filePath: filePath })
    if (returnValue <> invalid)
        return returnValue
    else
        return -1
    end if
end function
