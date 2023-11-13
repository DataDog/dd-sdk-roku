' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'import "pkg:/source/datadogSdk.bs"
'import "pkg:/source/internalLogger.bs"
'import "pkg:/source/timeUtils.bs"
' *****************************************************************
' * DdUrlTransfer: a class wrapping a roUrlTransfer component.
' *
' * Note: this class can only wrap synchronous network calls.
' * Async calls will require manual instrumentation for now
' *****************************************************************
function __DdUrlTransfer_builder()
    instance = {}
    ' ----------------------------------------------------------------
    ' Constructor
    ' @param global (object) the global node available from any node in the scenegraph
    ' ----------------------------------------------------------------
    instance.new = sub(global as object)
        m.roUrlTransfer = CreateObject("roUrlTransfer")
        m.global = global
        m.datadogRumAgent = global.datadogRumAgent
        m.traceSampleRate = global.datadogTraceAgent.traceSampleRate
        m.tracingHeaderTypes = global.datadogTraceAgent.tracingHeaderTypes
        m.headers = {}
    end sub
    ' ----------------------------------------------------------------
    ' Sets the traced hosts.
    '
    ' @param tracingHeaderTypes (array) a array of associative arrays. Each array item must have a the following entries:
    '   - 'host': the host name  for which requests will have a trace generated (e.g.: example.com)
    '   - 'header': one of the supported tracing header types :
    '       - "b3": Open Telemetry B3 Single header (cf: https://github.com/openzipkin/b3-propagation#single-header)
    '       - "b3multi": Open Telemetry B3 Multiple header (cf: https://github.com/openzipkin/b3-propagation#multiple-headers)
    '       - "tracecontext": W3C Trace Context header (cf: https://www.w3.org/TR/trace-context/#tracestate-header)
    '       - "datadog": Datadog's `x-datadog-*` header (cf: https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces)
    ' ----------------------------------------------------------------
    instance.SetTracingHeaderTypes = sub(tracingHeaderTypes = [] as object)
        m.tracingHeaderTypes = tracingHeaderTypes
    end sub
    ' ----------------------------------------------------------------
    ' Sets the tracing sample rate.
    '
    ' @param traceSampleRate (double) The sampling rate to add
    ' trace headers to the request, between 0 and 100
    ' ----------------------------------------------------------------
    instance.SettraceSampleRate = sub(traceSampleRate as double)
        m.traceSampleRate = traceSampleRate
    end sub
    ' *****************************************************************
    ' * ifUrlTransfer: interface that transfers data to or from remote
    ' * servers specified by URLs
    ' *****************************************************************
    ' ----------------------------------------------------------------
    ' Returns a unique number for this object that can be used to identify
    ' whether events originated from this object.
    '
    ' @return (integer) A unique number for the object
    ' ----------------------------------------------------------------
    instance.GetIdentity = function() as integer
        return m.roUrlTransfer.GetIdentity()
    end function
    ' ----------------------------------------------------------------
    ' Sets the URL to use for the transfer request.
    '
    ' @param url (string) The URL to be used for the transfer request
    ' ----------------------------------------------------------------
    instance.SetUrl = sub(url as string)
        m.roUrlTransfer.SetUrl(url)
    end sub
    ' ----------------------------------------------------------------
    ' Returns the current URL.
    '
    ' @return (string) The Url
    ' ----------------------------------------------------------------
    instance.GetUrl = function() as string
        return m.roUrlTransfer.GetUrl()
    end function
    ' ----------------------------------------------------------------
    ' Changes the request method from the normal GET, HEAD or POST to the value passed as a string.
    '
    ' @param req (string) The request method to be used
    ' ----------------------------------------------------------------
    instance.SetRequest = sub(req as string)
        m.roUrlTransfer.SetRequest(req)
    end sub
    ' ----------------------------------------------------------------
    ' Returns the current request method.
    '
    ' @return (string) The request method
    ' ----------------------------------------------------------------
    instance.GetRequest = function() as string
        return m.roUrlTransfer.GetRequest()
    end function
    ' ----------------------------------------------------------------
    ' Connects to the remote service as specified in the URL and returns
    ' the response body as a string. This function waits for the transfer
    ' to complete and it may block for a long time. This calls discards
    ' the headers and response codes. If that information is required,
    ' use the AsyncGetToString() method.
    '
    ' @return (string) The response body
    ' ----------------------------------------------------------------
    instance.GetToString = function() as string
        timer = CreateObject("roTimespan")
        port = CreateObject("roMessagePort")
        m.roUrlTransfer.SetMessagePort(port)
        url = m.roUrlTransfer.GetUrl()
        m._traceRequest()
        timer.Mark()
        result = m.roUrlTransfer.AsyncGetToString()
        if (not result)
            return ""
        end if
        while (true)
            msg = wait(5000, port)
            if (msg <> invalid)
                msgType = type(msg)
                if (msgType = "roUrlEvent")
                    if (msg.GetInt() = 1) ' transfer complete
                        durationMs& = timer.TotalMilliseconds()
                        transferTime# = millisToSec(durationMs&)
                        response = msg.GetString()
                        bytesDownloaded = Len(response)
                        httpCode = msg.GetResponseCode()
                        status = "ok"
                        if (httpCode < 0)
                            status = msg.GetFailureReason()
                        end if
                        resource = {
                            url: url
                            method: "GET"
                            transferTime: transferTime#
                            httpCode: httpCode
                            status: status
                            bytesDownloaded: bytesDownloaded
                            traceId: m.traceId
                            spanId: m.spanId
                        }
                        m.datadogRumAgent.callfunc("addResource", resource)
                        return response
                    else
                        ddLogWarning("Got roUrlEvent " + FormatJson(msg))
                    end if
                else
                    ddLogWarning("Got unexpected msg " + FormatJson(msg))
                end if
            end if
        end while
        return ""
    end function
    ' ----------------------------------------------------------------
    ' Connect to the remote service as specified in the URL and write
    ' the response body to a file on the Roku device's filesystem. This
    ' function does not return until the exchange is complete and may
    ' block for a long time. The HTTP response code from the server is
    ' returned. It is not possible to access any of the response headers.
    ' If this information is required use the AsyncGetToFile() method instead.
    '
    ' @param filename (string) The file on the Roku device's filesystem
    ' to which the response body is to be written
    '
    ' @return (string) The HTTP response code
    ' ----------------------------------------------------------------
    instance.GetToFile = function(filename as string) as integer
        timer = CreateObject("roTimespan")
        port = CreateObject("roMessagePort")
        m.roUrlTransfer.SetMessagePort(port)
        url = m.roUrlTransfer.GetUrl()
        m._traceRequest()
        timer.Mark()
        result = m.roUrlTransfer.AsyncGetToFile(filename)
        if (not result)
            return -1
        end if
        while (true)
            msg = wait(5000, port)
            if (msg <> invalid)
                msgType = type(msg)
                if (msgType = "roUrlEvent")
                    if (msg.GetInt() = 1) ' transfer complete
                        durationMs& = timer.TotalMilliseconds()
                        transferTime# = millisToSec(durationMs&)
                        httpCode = msg.GetResponseCode()
                        status = "ok"
                        bytesDownloaded = CreateObject("roFileSystem").Stat(filename).size
                        if (httpCode < 0)
                            status = msg.GetFailureReason()
                            bytesDownloaded = invalid
                        end if
                        resource = {
                            url: url
                            method: "GET"
                            transferTime: transferTime#
                            httpCode: httpCode
                            status: status
                            bytesDownloaded: bytesDownloaded
                            traceId: m.traceId
                            spanId: m.spanId
                        }
                        m.datadogRumAgent.callfunc("addResource", resource)
                        return httpCode
                    else
                        ddLogWarning("Got roUrlEvent " + FormatJson(msg))
                    end if
                else
                    ddLogWarning("Got unexpected msg " + FormatJson(msg))
                end if
            end if
        end while
        return -1
    end function
    ' ----------------------------------------------------------------
    ' Uses the HTTP POST method to send the supplied string to the current
    ' URL. The HTTP response code is returned. Any response body is discarded
    '
    ' @param request (string) The POST request to be sent
    '
    ' @return (integer) The HTTP response code.
    ' ----------------------------------------------------------------
    instance.PostFromString = function(request as string) as integer
        timer = CreateObject("roTimespan")
        port = CreateObject("roMessagePort")
        m.roUrlTransfer.SetMessagePort(port)
        url = m.roUrlTransfer.GetUrl()
        m._traceRequest()
        timer.Mark()
        result = m.roUrlTransfer.AsyncPostFromString(request)
        if (not result)
            return -1
        end if
        while (true)
            msg = wait(5000, port)
            if (msg <> invalid)
                msgType = type(msg)
                if (msgType = "roUrlEvent")
                    if (msg.GetInt() = 1) ' transfer complete
                        durationMs& = timer.TotalMilliseconds()
                        transferTime# = millisToSec(durationMs&)
                        httpCode = msg.GetResponseCode()
                        status = "ok"
                        if (httpCode < 0)
                            status = msg.GetFailureReason()
                        end if
                        resource = {
                            url: url
                            method: "POST"
                            transferTime: transferTime#
                            httpCode: httpCode
                            status: status
                            traceId: m.traceId
                            spanId: m.spanId
                        }
                        m.datadogRumAgent.callfunc("addResource", resource)
                        return httpCode
                    else
                        ddLogWarning("Got roUrlEvent " + FormatJson(msg))
                    end if
                else
                    ddLogWarning("Got unexpected msg " + FormatJson(msg))
                end if
            end if
        end while
        return -1
    end function
    ' ----------------------------------------------------------------
    ' Uses the HTTP POST method to send the contents of the specified
    ' file to the current URL. The HTTP response code is returned. Any
    ' response body is discarded
    '
    ' @param filename (string) The file containing the POST request to be sent
    '
    ' @return (integer) The HTTP response code.
    ' ----------------------------------------------------------------
    instance.PostFromFile = function(filename as string) as integer
        timer = CreateObject("roTimespan")
        port = CreateObject("roMessagePort")
        m.roUrlTransfer.SetMessagePort(port)
        url = m.roUrlTransfer.GetUrl()
        m._traceRequest()
        timer.Mark()
        result = m.roUrlTransfer.AsyncPostFromFile(filename)
        if (not result)
            return -1
        end if
        while (true)
            msg = wait(5000, port)
            if (msg <> invalid)
                msgType = type(msg)
                if (msgType = "roUrlEvent")
                    if (msg.GetInt() = 1) ' transfer complete
                        durationMs& = timer.TotalMilliseconds()
                        transferTime# = millisToSec(durationMs&)
                        httpCode = msg.GetResponseCode()
                        status = "ok"
                        if (httpCode < 0)
                            status = msg.GetFailureReason()
                        end if
                        resource = {
                            url: url
                            method: "POST"
                            transferTime: transferTime#
                            httpCode: httpCode
                            status: status
                            traceId: m.traceId
                            spanId: m.spanId
                        }
                        m.datadogRumAgent.callfunc("addResource", resource)
                        return httpCode
                    else
                        ddLogWarning("Got roUrlEvent " + FormatJson(msg))
                    end if
                else
                    ddLogWarning("Got unexpected msg " + FormatJson(msg))
                end if
            end if
        end while
        return -1
    end function
    ' ----------------------------------------------------------------
    ' Returns the body of the response even if the HTTP status code indicates
    ' that an error occurred.
    '
    ' @param retain (booleanà A flag specifying whether to return the response
    ' body when there is an HTTP error response code.
    '
    ' @return (boolean) A flag indicating whether the operation was successful
    ' ----------------------------------------------------------------
    instance.RetainBodyOnError = function(retain as boolean) as boolean
        return m.roUrlTransfer.RetainBodyOnError(retain)
    end function
    ' ----------------------------------------------------------------
    ' Enables HTTP authentication using the specified user name and password.
    '
    ' HTTP basic authentication is intentionally disabled because it is
    ' inherently insecure. HTTP digest authentication is supported.
    '
    ' @param
    ' @param user string The user name to be authenticated
    ' @param password string The password to be authenticated
    ' @return (boolean) A flag indicating whether the operation was successful
    ' ----------------------------------------------------------------
    instance.SetUserAndPassword = function(user as string, password as string) as boolean
        return m.roUrlTransfer.SetUserAndPassword(user, password)
    end function
    ' ----------------------------------------------------------------
    ' Terminates the transfer automatically if the transfer rate drops
    ' below the specified rate (bytes_per_second) over a specific interval
    ' (period_in_seconds).
    '
    ' @param bytes_per_second (integer) The minimum transfer rate required
    ' to transfer data.
    ' @param period_in_seconds (integer) The interval to be used for
    ' averaging bytes_per_second. For large file transfers and a small
    ' bytes_per_second, averaging over fifteen minutes or even longer might
    ' be appropriate. If the transfer is being done over the internet,
    ' setting this to a small number because it may cause temporary drops
    ' in performance if network problems occur.
    '
    ' @return (boolean) A flag indicating whether the operation was successful
    ' ----------------------------------------------------------------
    instance.SetMinimumTransferRate = function(bytes_per_second as integer, period_in_seconds as integer) as boolean
        return m.roUrlTransfer.SetMinimumTransferRate(bytes_per_second, period_in_seconds)
    end function
    ' ----------------------------------------------------------------
    ' If any of the roUrlEvent functions indicate failure then this function
    ' may provide more information regarding the failure.
    '
    ' @return (string) Failure reason.
    ' ----------------------------------------------------------------
    instance.GetFailureReason = function() as string
        return m.roUrlTransfer.GetFailureReason()
    end function
    ' ----------------------------------------------------------------
    ' Enables gzip encoding of transfers
    '
    ' @param retain (boolean) A flag specifying whether to enable gzip
    ' encoding of transfers
    '
    ' @return (boolean) A flag indicating whether this operation was successful.
    ' ----------------------------------------------------------------
    instance.EnableEncodings = function(enable as boolean) as boolean
        return m.roUrlTransfer.EnableEncodings(enable)
    end function
    ' ----------------------------------------------------------------
    ' URL encodes the specified string per RFC 3986 and return the encoded string
    '
    ' @param text (string) The string to be URL - encoded
    '
    ' @return (string) The URL - encoded string.
    ' ----------------------------------------------------------------
    instance.Escape = function(text as string) as string
        return m.roUrlTransfer.Escape(text)
    end function
    ' ----------------------------------------------------------------
    ' Decodes the specified string per RFC 3986 and returns the unencoded string.
    '
    ' @param text (string) The string to be URL - decoded
    '
    ' @return (string) The decoded string.
    ' ----------------------------------------------------------------
    instance.Unescape = function(text as string) as string
        return m.roUrlTransfer.Unescape(text)
    end function
    ' ----------------------------------------------------------------
    ' Enables automatic resumption of AsyncGetToFile and GetToFile requests
    '
    ' @param enable (boolean) A flag specifying whether to automatically
    ' resume AsyncGetToFile and GetToFile requests
    '
    ' @return (boolean) A flag indicating whether the operation was successful
    ' ----------------------------------------------------------------
    instance.EnableResume = function(enable as boolean) as boolean
        return m.roUrlTransfer.EnableResume(enable)
    end function
    ' ----------------------------------------------------------------
    ' Verifies that the certificate has a chain of trust up to a valid
    ' root certificate using CURLOPT_SSL_VERIFYPEER.
    '
    ' @param enable (boolean) A flag specifying whether to verify a certificate has a chain - of - trust up to a valid root certificate
    ' @return (boolean) A flag indicating whether the operation was successful
    ' ----------------------------------------------------------------
    instance.EnablePeerVerification = function(enable as boolean) as boolean
        return m.roUrlTransfer.EnablePeerVerification(enable)
    end function
    ' ----------------------------------------------------------------
    ' Verifies that the certificate belongs to the host using CURLOPT_SSL_VERIFYHOST.
    '
    ' @param enable (boolean) A flag specifying whether to verify a certificate belonging to the host.
    '
    ' @return (boolean) A flag indicating whether the operation was successful
    ' ----------------------------------------------------------------
    instance.EnableHostVerification = function(enable as boolean) as boolean
        return m.roUrlTransfer.EnableHostVerification(enable)
    end function
    ' ----------------------------------------------------------------
    ' An optional function that enables HTTP/2 support. If version is
    ' set to "http2", HTTP/2 will be used for all underlying transfers.
    '
    ' This must be set on a roUrlTransfer instance prior to any data transfer.
    ' The HTTP version used by an instance cannot be changed after the
    ' instance's first use.
    '
    ' For the HTTP/2 connection sharing feature, all roUrlTransfers
    ' should be made from the same thread.
    '
    ' SetHttpVersion does not impact the connection made by the Roku
    ' Media player, which will always use HTTP/1.x.
    '
    ' @param version (string) The http version to be used (for example,
    ' "http2" for HTTP/2). "AUTO" is the default value, which causes the
    ' underlying roUrlTransfer connection to auto-negotiate HTTP/1.x or
    ' HTTP/2, depending on the agreement reached by client and server.
    ' ----------------------------------------------------------------
    instance.SetHttpVersion = sub(version as string)
        m.roUrlTransfer.SetHttpVersion(version)
    end sub
    ' *****************************************************************
    ' * ifHttpAgent: interface to modify the way that URLs are accessed
    ' *****************************************************************
    ' ----------------------------------------------------------------
    ' Adds the specified HTTP header to the list of headers that will
    ' be sent in the HTTP request.
    '
    ' Certain well known headers such as User - Agent, Content - Length,
    ' and so on are automatically sent. The application may override the
    ' values for these headers if needed (for example, some servers may
    ' require a specific user agent string).
    '
    ' @param name (string) The name of the HTTP header to be added to
    ' the list of headers.
    ' If "x-roku-reserved-dev-id" is passed as the name, the value parameter
    ' is ignored and in its place, the devid of the currently running
    ' channel is used as the value. This allows the developer's server
    ' to know which client app is talking to it.
    ' Any other headers with names beginning with "x-roku-reserved-"
    ' are reserved and may not be set.
    '
    ' @return (boolean) A flag indicating whether the HTTP header was
    ' successfully added.
    ' ----------------------------------------------------------------
    instance.AddHeader = function(name as string, value as string) as boolean
        headerValues = (function(m, name)
                __bsConsequent = m.headers[name]
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return []
                end if
            end function)(m, name)
        headerValues.Push(value)
        m.headers[name] = headerValues
        return m.roUrlTransfer.AddHeader(name, value)
    end function
    ' ----------------------------------------------------------------
    ' Sets the HTTP headers to be sent in the HTTP request.
    '
    ' @param nameValueMap (object) An associative array containing the
    ' HTTP headers and values to be included in the HTTP request.
    '
    ' if "x-roku-reserved-dev-id" is passed as a key, the value parameter
    ' is ignored and in its place, the devid of the currently running
    ' channel is used as the value. This allows the developer's server
    ' to know which client app is talking to it.
    ' Any other headers with names beginning with "x-roku-reserved-" are
    ' reserved and may not be set.
    '
    ' @return (boolean) A flag indicating whether the HTTP header was
    ' successfully set.
    ' ----------------------------------------------------------------
    instance.SetHeaders = function(nameValueMap as object) as boolean
        m.headers = {}
        for each key in nameValueMap
            m.headers[key] = nameValueMap[key]
        end for
        return m.roUrlTransfer.SetHeaders(nameValueMap)
    end function
    ' ----------------------------------------------------------------
    ' Initializes the object to be sent to the Roku client certificate.
    '
    ' The Roku Developer Dashboard includes a link for downloading the
    ' RokuTV Certification Authority. This CA can be passed to a channel
    ' through this function.
    '
    ' @return (boolean) A flag indicating whether the object sent to to
    ' the Roku client certificate was successfully initialized.
    ' ----------------------------------------------------------------
    instance.InitClientCertificates = function() as boolean
        return m.roUrlTransfer.InitClientCertificates()
    end function
    ' ----------------------------------------------------------------
    ' Set the certificates file used for SSL to the specified .pem file.
    '
    ' @param path (string) The directory path of the .pem file to be used.
    '
    ' @return (boolean) A flag indicating whether the certificate was
    ' successfully set.
    ' ----------------------------------------------------------------
    instance.SetCertificatesFile = function(path as string) as boolean
        return m.roUrlTransfer.SetCertificatesFile(path)
    end function
    ' ----------------------------------------------------------------
    ' Sets the maximum depth of the certificate chain that will be accepted.
    '
    ' @param depth (integer) The maximum depth to be used.
    ' ----------------------------------------------------------------
    instance.SetCertificatesDepth = sub(depth as integer)
        m.roUrlTransfer.SetCertificatesDepth(depth)
    end sub
    ' ----------------------------------------------------------------
    ' Enables any Set-Cookie headers returned from the request to be
    ' interpreted and the resulting cookies to be added to the cookie cache.
    ' ----------------------------------------------------------------
    instance.EnableCookies = sub()
        m.roUrlTransfer.EnableCookies()
    end sub
    ' ----------------------------------------------------------------
    ' Returns any cookies from the cookie cache that match the specified
    ' domain and path. Expired cookies are not returned.
    '
    ' @param domain (string) The domain of the cookies to be retrieved.
    ' to match all domains, provide an empty string.
    ' @param path (string) The path of the cookies to be retrieved.
    '
    ' @return (object) An Array of AssociativeArrays, where each associative
    ' array represents a cookie. The AssociativeArrays contain the following
    ' key-value pairs:
    '  - Version (integer) Cookie version number
    '  - Domain (string) Domain to which cookie applies
    '  - Path (string) Path to which cookie applies
    '  - Name (string) Name of the cookie
    '  - Value (string) Value of the cookie
    '  - Expires (roDateTime) Cookie expiration date, if any
    ' ----------------------------------------------------------------
    instance.GetCookies = function(domain as string, path as string) as object
        return m.roUrlTransfer.GetCookies(domain, path)
    end function
    ' ----------------------------------------------------------------
    ' Adds the specified cookies to the cookie cache.
    ' @param cookies (object) An Array of AssociativeArrays, where each
    ' associative array represents a cookie to be added. Each associative
    ' array must contain the following key-value pairs:
    '  - Version (integer) Cookie version number
    '  - Domain (string) Domain to which cookie applies
    '  - Path (string) Path to which cookie applies
    '  - Name (string) Name of the cookie
    '  - Value (string) Value of the cookie
    '  - Expires (roDateTime) Cookie expiration date, if any
    '
    ' @return (boolean) A flag indicating whether the cookies were successfully added to the cache.
    ' ----------------------------------------------------------------
    instance.AddCookies = function(cookies as object) as boolean
        return m.roUrlTransfer.AddCookies(cookies)
    end function
    ' ----------------------------------------------------------------
    ' Removes all cookies from the cookie cache.
    ' ----------------------------------------------------------------
    instance.ClearCookies = sub()
        m.roUrlTransfer.ClearCookies()
    end sub
    ' ----------------------------------------------------------------
    ' (Internal) generates a trace and span id and update the request
    ' headers
    ' ----------------------------------------------------------------
    instance._traceRequest = sub()
        rndTrace = (Rnd(101) - 1) ' Rnd(n) returns a number between 1 and n (both inclusive)
        isSampledIn = rndTrace < m.traceSampleRate
        headerType = getTracedHeaderType(m.roUrlTransfer.GetUrl(), m.tracingHeaderTypes)
        if (headerType <> invalid)
            ddLogInfo("Tracing request to " + m.roUrlTransfer.GetUrl() + " with headers " + headerType)
            if (isSampledIn)
                ddLogInfo("Request trace is sampled in")
                m._addSampledInHeaders(headerType)
            else
                ddLogInfo("Request trace is sampled out")
                m._addSampledOutHeaders(headerType)
            end if
        else
            ddLogInfo("Not tracing request to " + m.roUrlTransfer.GetUrl() + ", no tracing header for that host")
            m.traceId = invalid
            m.spanId = invalid
            m._deleteTracingHeaders()
        end if
        m._applyHeaders()
    end sub
    ' ----------------------------------------------------------------
    ' (Internal) adds the relevant headers for distributed tracing,
    ' matching the given type
    ' @param cookies (TracingHeaderType) the header type to use
    ' ----------------------------------------------------------------
    instance._addSampledInHeaders = sub(headerType as object)
        m._deleteTracingHeaders()
        if (headerType = "datadog")
            ' Datadog uses traces in base 10 and not hex
            m.traceId = generateUniqueId(10)
            m.spanId = generateUniqueId(10)
            m.AddHeader("x-datadog-trace-id", m.traceId)
            m.AddHeader("x-datadog-parent-id", m.spanId)
            m.AddHeader("x-datadog-sampling-priority", "1")
            m.AddHeader("x-datadog-origin", "rum")
        else if (headerType = "b3")
            m.traceId = generateUniqueId(16)
            m.spanId = generateUniqueId(16)
            b3 = padLeft(m.traceId, 32, "0") + "-" + padLeft(m.spanId, 16, "0") + "-1"
            m.AddHeader("b3", b3)
        else if (headerType = "b3multi")
            m.traceId = generateUniqueId(16)
            m.spanId = generateUniqueId(16)
            m.AddHeader("X-B3-TraceId", m.traceId)
            m.AddHeader("X-B3-SpanId", m.spanId)
            m.AddHeader("X-B3-Sampled", "1")
        else if (headerType = "tracecontext")
            m.traceId = generateUniqueId(16)
            m.spanId = generateUniqueId(16)
            hexSpanId = padLeft(m.spanId, 16, "0")
            traceparent = "00-" + padLeft(m.traceId, 32, "0") + "-" + hexSpanId + "-01"
            m.AddHeader("traceparent", traceparent)
            usrId = m.global.datadogUserInfo.id
            if (usrId <> invalid)
                usrIdByteArray = CreateObject("roByteArray")
                usrIdByteArray.FromAsciiString(usrId)
                usrIdBase64 = usrIdByteArray.ToBase64String().Replace("=", "~")
                tracestate = "dd=s:1;o:rum;p:" + hexSpanId + ";t.usr.id:" + usrIdBase64
            else
                tracestate = "dd=s:1;o:rum;p:" + hexSpanId
            end if
            m.AddHeader("tracestate", tracestate)
        else
            m.traceId = invalid
            m.spanId = invalid
            ddLogWarning("Cannot trace request, header type is unknown: " + headerType)
        end if
    end sub
    ' ----------------------------------------------------------------
    ' (Internal) adds the relevant headers for distributed tracing,
    ' matching the given type, to sample this request out
    ' @param cookies (TracingHeaderType) the header type to use
    ' ----------------------------------------------------------------
    instance._addSampledOutHeaders = sub(headerType as object)
        m._deleteTracingHeaders()
        m.traceId = invalid
        m.spanId = invalid
        if (headerType = "datadog")
            m.AddHeader("x-datadog-sampling-priority", "0")
        else if (headerType = "b3")
            m.AddHeader("b3", "0")
        else
            ddLogWarning("Cannot trace request, header type is unknown: " + headerType)
        end if
    end sub
    instance._deleteTracingHeaders = sub()
        m.headers.Delete("x-datadog-trace-id")
        m.headers.Delete("x-datadog-parent-id")
        m.headers.Delete("x-datadog-sampling-priority")
        m.headers.Delete("x-datadog-origin")
        m.headers.Delete("b3")
        m.headers.Delete("X-B3-TraceId")
        m.headers.Delete("X-B3-SpanId")
        m.headers.Delete("X-B3-Sampled")
        m.headers.Delete("traceparent")
        m.headers.Delete("tracestate")
    end sub
    instance._applyHeaders = sub()
        currentHeaders = m.headers
        headerMap = {}
        for each key in currentHeaders
            value = ""
            for each headerValue in currentHeaders[key]
                if (value.Len() > 0)
                    value = value + "," + headerValue
                else
                    value = headerValue
                end if
            end for
            headerMap[key] = value
        end for
        m.roUrlTransfer.SetHeaders(headerMap)
    end sub
    return instance
end function
function DdUrlTransfer(global as object)
    instance = __DdUrlTransfer_builder()
    instance.new(global)
    return instance
end function
'*****************************************************************
'* Utility functions to manipulate requests
'*****************************************************************

' ----------------------------------------------------------------
' Verifies whether the given url uses one of the provided hosts
' @param url (string) a url
' @param tracingHeaderTypes (array) a array of associative arrays. Each array item must have a the following entries:
'   - 'host': the host name  for which requests will have a trace generated (e.g.: example.com)
'   - 'header': one of the supported tracing header types :
'       - "b3": Open Telemetry B3 Single header (cf: https://github.com/openzipkin/b3-propagation#single-header)
'       - "b3multi": Open Telemetry B3 Multiple header (cf: https://github.com/openzipkin/b3-propagation#multiple-headers)
'       - "tracecontext": W3C Trace Context header (cf: https://www.w3.org/TR/trace-context/#tracestate-header)
'       - "datadog": Datadog's `x-datadog-*` header (cf: https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces)
' @return (dynamic) the tracing header to use or invalid
' ----------------------------------------------------------------
function getTracedHeaderType(url as string, tracingHeaderTypes as object) as dynamic
    tokens = url.split("/")
    ' assuming we have "scheme://host[/…]",
    ' tokens[0] = 'scheme:'
    ' tokens[1] = '' (empty string between the two //)
    ' tokens[2] = 'host'
    ' tokens[3+] = params
    urlHost = tokens[2]
    for each item in tracingHeaderTypes
        if (item.host = urlHost)
            return item.header
        end if
    end for
    return invalid
end function

' ----------------------------------------------------------------
' Generates a unique identifier compatible with Datadog's APM trace and span IDs
' @return (string) the generated Unique id
' ----------------------------------------------------------------
function generateUniqueId(radix = 10 as integer) as string
    maxInt = 4294967295
    low& = Rnd(maxInt) - 1
    high& = Rnd(maxInt) - 1
    id = ""
    while (high& > 0 or low& > 0)
        ' Create an intermediate value with the same modulo as the combined high and low value
        ' but requiring 36 bits max (32 for the low value + 4 for the high part)
        modH = high& mod radix
        temp& = (modH << 32) + low&
        digit = temp& mod radix
        ' update the high value
        high& = (high& - modH) / radix ' we reuse the modH to avoid the need of a floor op
        ' the low value reuses the previous temp value to account for the "missing mod" in the high update
        low& = (temp& - digit) / radix ' we reuse the digit to avoid the need of a floor op
        ' update the string from right to left
        if (digit < 10)
            id = digit.toStr() + id
        else
            id = chr(digit + 87) + id ' char 'a' is 97 = 10 + 87
        end if
    end while
    return id
end function

' ----------------------------------------------------------------
' Pads a string if it is shorter than the expected size
' @param input (string) the string to pad
' @param length (integer) the expected string length
' @param pad (string) the string to use to pad (whitespace by default)
' ----------------------------------------------------------------
function padLeft(input as string, length as integer, pad = " " as string) as string
    ddLogVerbose("Padding string '" + input + "' to length " + length.toStr() + " with pad:'" + pad + "'")
    inputLength = input.Len()
    if (inputLength >= length)
        return input
    end if
    if (pad.Len() = 0)
        ddLogWarning("Unable to pad string <" + input + "> because padding is empty")
        return input
    end if
    paddingLength = length - inputLength
    output = ""
    while (output.Len() < paddingLength)
        output = output + pad
    end while
    output = output + input
    return output
end function