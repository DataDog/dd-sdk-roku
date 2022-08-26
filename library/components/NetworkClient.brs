' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
'* NetworkClient: a wrapper around Roku's.
'*****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.roUrlTransfer = CreateObject("roUrlTransfer")
end sub


' ----------------------------------------------------------------
' POST method to send the contents of the specified file to the
'     provided URL.
' @param url (string) the URL to be used for the transfer request
' @param filePath (string) the file's path
' @return (integer) the HTTP response code (any response body is
'     discarded)
' ----------------------------------------------------------------
function postFromFile(url as string, filePath as string, headers as object) as integer
    return -1
end function
