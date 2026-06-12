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
        m.traceContextInjection = global.datadogTraceAgent.traceContextInjection
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
    '       - "tracecontext": W3C Trace Context header (cf: https://www.w3.org/TR/trace-context/)
    '       - "datadog": Datadog's `x-datadog-*` headers (cf: https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces)
    ' ----------------------------------------------------------------
    instance.SetTracingHeaderTypes = sub(tracingHeaderTypes = [] as object)
        m.tracingHeaderTypes = tracingHeaderTypes
    end sub
    ' ----------------------------------------------------------------
    ' Sets the trace sample rate.
    '
    ' @param traceSampleRate (double) The sample rate to create a trace
    ' for the requests (and add trace headers if the host is configured),
    ' between 0 and 100
    ' ----------------------------------------------------------------
    instance.SetTraceSampleRate = sub(traceSampleRate as double)
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
        startTime& = getTimestamp()
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
                            startTime: startTime&
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
        startTime& = getTimestamp()
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
                            startTime: startTime&
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
        startTime& = getTimestamp()
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
                            startTime: startTime&
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
        startTime& = getTimestamp()
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
                            startTime: startTime&
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
    instance.GetHeader = function(name as string) as dynamic
        return (function(m, name)
                __bsConsequent = m.headers[name]
                if __bsConsequent <> invalid then
                    return __bsConsequent
                else
                    return []
                end if
            end function)(m, name)
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
        sessionId = m.global.datadogRumContext?.sessionId
        isSampledIn = m._isSampledIn(sessionId)
        headerType = getTracedHeaderType(m.roUrlTransfer.GetUrl(), m.tracingHeaderTypes)
        if (headerType <> invalid)
            ddLogInfo("Tracing request to " + m.roUrlTransfer.GetUrl() + " with headers " + headerType)
            if (isSampledIn)
                ddLogInfo("Request trace is sampled in")
                m._addSampledInHeaders(headerType, sessionId)
            else if (m.traceContextInjection = "all")
                ddLogInfo("Request trace is sampled out")
                m._addSampledOutHeaders(headerType)
            else
                ddLogInfo("Request trace is sampled out, but no header is added.")
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
    ' (Internal) decides if the current trace is sampled in.
    ' Uses session ID (deterministic) when available, random fallback otherwise.
    ' ----------------------------------------------------------------
    instance._isSampledIn = function(sessionId as dynamic) as boolean
        if (m.traceSampleRate >= 100)
            return true
        end if
        if (m.traceSampleRate <= 0)
            return false
        end if
        if (sessionId <> invalid and sessionId.len() > 0)
            seed& = m._parseUuidLastSegment(sessionId)
            return m._isDeterministicSampledIn(seed&, m.traceSampleRate)
        end if
        ' Fallback: no session — use random (same as legacy behavior)
        return Rnd(100) <= m.traceSampleRate
    end function
    ' ----------------------------------------------------------------
    ' (Internal) extracts the last segment of a UUID as a LongInteger seed.
    ' UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (last segment = 12 hex chars = 48 bits)
    ' Assumes last segment is exactly 12 hex chars (standard UUID v4 format).
    ' ----------------------------------------------------------------
    instance._parseUuidLastSegment = function(uuid as string) as longinteger
        parts = uuid.split("-")
        if (parts.count() < 5)
            return 0&
        end if
        seg = parts[4] ' 12 hex chars
        highBits& = val(Left(seg, 6), 16) ' upper 24 bits
        lowBits& = val(Right(seg, 6), 16) ' lower 24 bits
        return highBits& * 16777216& + lowBits& ' 16^6 = 0x1000000
    end function
    ' ----------------------------------------------------------------
    ' (Internal) Knuth multiplicative hash — matches Android DeterministicSampler
    ' / iOS DeterministicSampler.
    ' Returns true if seed hashes into the sampled bucket for the given sampleRate (0-100).
    ' ----------------------------------------------------------------
    instance._isDeterministicSampledIn = function(seed& as longinteger, sampleRate as double) as boolean
        ' Knuth multiplicative hash — matches Android DeterministicSampler / iOS DeterministicSampler.
        ' KNUTH = 1111111111111111111 split into 16-bit chunks to avoid BrightScript's
        ' LongInteger * LongInteger overflow: large products use double arithmetic
        ' instead of wrapping at 64 bits, producing wrong results.
        ' Each partial product s_i * k_j <= 65535^2 < 2^32 — no overflow.
        k0& = 29127& ' bits  0-15 of 1111111111111111111
        k1& = 11204& ' bits 16-31
        k2& = 30123& ' bits 32-47
        k3& = 3947& ' bits 48-63
        s0& = seed& AND 65535&
        s1& = (seed& >> 16&) AND 65535&
        s2& = (seed& >> 32&) AND 65535&
        s3& = (seed& >> 48&) AND 65535&
        c0& = s0& * k0&
        c1& = s0& * k1& + s1& * k0&
        c2& = s0& * k2& + s1& * k1& + s2& * k0&
        c3& = s0& * k3& + s1& * k2& + s2& * k1& + s3& * k0&
        carry& = c0& >> 16&
        r0& = c0& AND 65535&
        sum1& = c1& + carry&
        r1& = sum1& AND 65535&
        carry& = sum1& >> 16&
        sum2& = c2& + carry&
        r2& = sum2& AND 65535&
        carry& = sum2& >> 16&
        r3& = (c3& + carry&) AND 65535&
        ' Build the unsigned 64-bit hash as a double directly from the 16-bit digits.
        ' All inputs are non-negative, so no sign correction is needed.
        hashDouble# = CDbl(r3&) * 281474976710656.0 + CDbl(r2&) * 4294967296.0 + CDbl(r1&) * 65536.0 + CDbl(r0&)
        MAX_UINT64# = 1.8446744073709552e+19 ' 2^64
        threshold# = MAX_UINT64# * sampleRate / 100.0#
        return hashDouble# < threshold#
    end function
    ' ----------------------------------------------------------------
    ' (Internal) adds the relevant headers for distributed tracing,
    ' matching the given type
    ' @param headerType (string) the header type to use
    ' ----------------------------------------------------------------
    instance._addSampledInHeaders = sub(headerType as object, sessionId as dynamic)
        m._deleteTracingHeaders()
        if (sessionId <> invalid and sessionId.len() > 0)
            m.AddHeader("baggage", "session.id=" + sessionId)
        end if
        traceId = generateTraceId()
        spanId = generateSpanId()
        m.traceId = traceId.hex
        m.spanId = spanId.decimal
        if (headerType = "datadog")
            ' Datadog uses a complex system for compatibility purposes
            m.AddHeader("x-datadog-trace-id", traceId.lowDecimal)
            ' Only forward the high-order bits when they carry information: a
            ' zero high part means a 64 bit trace id, for which the _dd.p.tid
            ' tag must be omitted (matching the other Datadog SDKs).
            if (traceId.highHex <> "0000000000000000")
                m.AddHeader("x-datadog-tags", "_dd.p.tid=" + traceId.highHex)
            end if
            m.AddHeader("x-datadog-parent-id", spanId.decimal)
            m.AddHeader("x-datadog-sampling-priority", "1")
            m.AddHeader("x-datadog-origin", "rum")
        else if (headerType = "b3")
            b3 = traceId.hex + "-" + spanId.hex + "-1"
            m.AddHeader("b3", b3)
        else if (headerType = "b3multi")
            m.AddHeader("X-B3-TraceId", traceId.hex)
            m.AddHeader("X-B3-SpanId", spanId.hex)
            m.AddHeader("X-B3-Sampled", "1")
        else if (headerType = "tracecontext")
            traceparent = "00-" + traceId.hex + "-" + spanId.hex + "-01"
            m.AddHeader("traceparent", traceparent)
            usrId = m.global.datadogUserInfo.id
            if (usrId <> invalid)
                usrIdByteArray = CreateObject("roByteArray")
                usrIdByteArray.FromAsciiString(usrId)
                usrIdBase64 = usrIdByteArray.ToBase64String().Replace("=", "~")
                tracestate = "dd=s:1;o:rum;p:" + spanId.hex + ";t.usr.id:" + usrIdBase64
            else
                tracestate = "dd=s:1;o:rum;p:" + spanId.hex
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
    ' @param headerType (TracingHeaderType) the header type to use
    ' ----------------------------------------------------------------
    instance._addSampledOutHeaders = sub(headerType as object)
        m._deleteTracingHeaders()
        m.traceId = invalid
        m.spanId = invalid
        if (headerType = "datadog")
            m.AddHeader("x-datadog-sampling-priority", "0")
        else if (headerType = "b3")
            m.AddHeader("b3", "0")
        else if (headerType = "b3multi")
            m.AddHeader("X-B3-Sampled", "0")
        else if (headerType = "tracecontext")
            m.AddHeader("traceparent", "00-" + padLeft("", 32, "0") + "-" + padLeft("", 16, "0") + "-00")
        else
            ddLogWarning("Cannot trace request, header type is unknown: " + headerType)
        end if
    end sub
    ' ----------------------------------------------------------------
    ' (Internal) delete the tracing headers to avoid duplicated value
    ' when the ddUrlTransfer is used for more than one request.
    ' ----------------------------------------------------------------
    instance._deleteTracingHeaders = sub()
        baggageHeader = m.GetHeader("baggage")
        m.headers.Delete("baggage")
        for each item in baggageHeader
            if (Left(item, 11) <> "session.id=")
                m.AddHeader("baggage", item)
            end if
        end for
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
    ' ----------------------------------------------------------------
    ' (Internal) applies the headers recorded in the ddUrlTransfer
    ' to the underlying roUrlTransfer component.
    ' ----------------------------------------------------------------
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
'       - "tracecontext": W3C Trace Context header (cf: https://www.w3.org/TR/trace-context/)
'       - "datadog": Datadog's `x-datadog-*` headers (cf: https://docs.datadoghq.com/real_user_monitoring/connect_rum_and_traces)
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
' Generates a 128 bit trace id with all the representations required
' by the supported tracing headers and the RUM resource event.
'
' The backend (rum-span-mapper) only correlates a RUM resource to an APM
' span when `_dd.trace_id` is either a 64 bit decimal number or a 128 bit
' hexadecimal number padded to exactly 32 chars; an unpadded hexadecimal
' id (shorter than 32 chars) is rejected. We therefore zero-pad the id.
'
' @return (object) an associative array with the following entries:
'   - hex (string) the full 128 bit id as a 32 char zero-padded hexadecimal
'       string (used by the RUM event, the W3C and the B3 headers)
'   - lowDecimal (string) the low 64 bit part in decimal (used by the legacy
'       x-datadog-trace-id header)
'   - highHex (string) the high 64 bit part as a 16 char zero-padded
'       hexadecimal string (used by the _dd.p.tid Datadog tag)
' ----------------------------------------------------------------
function generateTraceId() as object
    high0& = random32()
    high1& = random32()
    low0& = random32()
    low1& = random32()
    return {
        hex: padLeft(printIdToString(high0&, high1&, low0&, low1&, 16), 32, "0")
        lowDecimal: renderId64(low0&, low1&).decimal
        highHex: renderId64(high0&, high1&).hex
    }
end function

' ----------------------------------------------------------------
' Generates a 64 bit span id with all the representations required
' by the supported tracing headers and the RUM resource event.
'
' The backend (rum-span-mapper) only correlates a RUM resource to an APM
' span when `_dd.span_id` is a strictly positive decimal number; a
' hexadecimal span id is rejected. We therefore expose a decimal form for
' the RUM event and the Datadog header, and a hexadecimal form for the
' W3C and B3 headers.
'
' @return (object) an associative array with the following entries:
'   - decimal (string) the id in decimal (used by the RUM event and the
'       x-datadog-parent-id header)
'   - hex (string) the id as a 16 char zero-padded hexadecimal string
'       (used by the W3C and B3 headers)
' ----------------------------------------------------------------
function generateSpanId() as object
    return renderId64(random32(), random32())
end function

' ----------------------------------------------------------------
' Renders a 64 bit id (given as two 32 bit halves) in the representations
' shared by the trace and span id generators.
' @param hi& (longinteger) the high 32 bits
' @param lo& (longinteger) the low 32 bits
' @return (object) an associative array with the following entries:
'   - decimal (string) the id in decimal (used by the RUM event and the
'       Datadog headers)
'   - hex (string) the id as a 16 char zero-padded hexadecimal string
'       (used by the W3C and B3 headers)
' ----------------------------------------------------------------
function renderId64(hi& as longinteger, lo& as longinteger) as object
    return {
        decimal: printIdToString(0, 0, hi&, lo&, 10)
        hex: padLeft(printIdToString(0, 0, hi&, lo&, 16), 16, "0")
    }
end function

' ----------------------------------------------------------------
' Generates a uniformly distributed unsigned 32 bit value.
'
' BrightScript's `Rnd(n)` takes a signed 32 bit Integer, so it cannot be
' asked directly for the full unsigned 32 bit range; we assemble the value
' from two independent 16 bit draws instead.
' @return (longinteger) a value in [0, 4294967295]
' ----------------------------------------------------------------
function random32() as longinteger
    high& = Rnd(65536) - 1 ' 0..65535
    low& = Rnd(65536) - 1 ' 0..65535
    return (high& << 16) + low&
end function

function printIdToString(li0& as longinteger, li1& as longinteger, li2& as longinteger, li3& as longinteger, radix = 10 as integer) as string
    a& = li0&
    b& = li1&
    c& = li2&
    d& = li3&
    id = ""
    while (a& > 0 or b& > 0 or c& > 0 or d& > 0)
        ' Create intermediate values with the same modulo as the combined high and low value
        ' but requiring 36 bits max (32 for the low value + 4 for the high part)
        ' transitively for each bucket
        modA& = a& mod radix
        tempB& = (modA& << 32) + b&
        modTempB& = tempB& mod radix
        tempC& = (modTempB& << 32) + c&
        modTempC& = tempC& mod radix
        tempD& = (modTempC& << 32) + d&
        digit = tempD& mod radix
        a& = (a& - modA&) / radix
        b& = (tempB& - modTempB&) / radix
        c& = (tempC& - modTempC&) / radix
        d& = (tempD& - digit) / radix
        ' update the string from right to left
        if (digit < 10)
            id = digit.toStr() + id
        else
            id = chr(digit + 87) + id ' char 'a' is 97 = 10 + 87
        end if
    end while
    ' A zero value produces no digits in the loop above; return "0" rather than
    ' an empty string so decimal ids stay valid (e.g. the backend requires
    ' `_dd.span_id` to be a strictly positive decimal, and "" / missing is rejected).
    if (id = "")
        return "0"
    end if
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