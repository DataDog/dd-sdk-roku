' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
'* NetworkClient: a wrapper around Roku's URL Transfer implementation.
'*****************************************************************

' ----------------------------------------------------------------
' Initialize the component
' ----------------------------------------------------------------
sub init()
    m.urlTransfer = CreateObject("roUrlTransfer")
end sub


' ----------------------------------------------------------------
' POST method to send the contents of the specified file to the
'     provided URL.
' @param url (string) the URL to be used for the transfer request
' @param filePath (string) the file's path
' @param headers (object) an AssocArray with the headers to use
' @param payloadPrefix (string) a prefix to append before the payload
' @param payloadPostfix (string) a postfix to append after the payload
' @return (integer) the HTTP response code (any response body is
'     discarded)
' ----------------------------------------------------------------
function postFromFile(url as string, filePath as string, headers as object, payloadPrefix as string, payloadPostfix as string) as integer
    payload = payloadPrefix + ReadAsciiFile(filePath) + payloadPostfix

    m.urlTransfer.SetUrl(url)
    m.urlTransfer.SetRequest("POST")
    m.urlTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt") ' required for SSL

    for each header in headers
        m.urlTransfer.AddHeader(header, headers[header])
    end for

    return m.urlTransfer.PostFromString(payload)
end function
