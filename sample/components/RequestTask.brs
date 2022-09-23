
sub init()
    m.top.functionName = "performRequest"

end sub

sub performRequest()
    datadogroku_logInfo("performing request")

    m.port = CreateObject("roMessagePort")

    if (Rnd(2) = 1)
        requestUrl = "https://www.google.com/search?q=" + m.top.query
    else
        requestUrl = "https://www.google.com/notasearch?q=" + m.top.query
    end if
    
    request = CreateObject("roUrlTransfer")
    request.SetUrl(requestUrl)
    request.RetainBodyOnError(true)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    request.SetMessagePort(m.port)

    timer = CreateObject("roTimespan")
    timer.Mark()
    request.AsyncGetToString()

    while (true)
        msg = wait(5000, m.port)
        if (msg <> invalid)
            msgType = type(msg)
            if (msgType = "roUrlEvent")
                if (msg.GetInt() = 1) ' transfer complete
                    durationMs& = timer.TotalMilliseconds()
                    transferTime# = datadogroku_millisToSec(durationMs&)

                    httpCode = msg.GetResponseCode()
                    if (httpCode < 0)
                        status = msg.GetFailureReason()
                    else
                        status = "ok"
                    end if
                    resource = {
                        url: requestUrl,
                        method: "GET",
                        transferTime: transferTime#,
                        httpCode: httpCode,
                        status: status
                    }
                    m.top.rumAgent.callFunc("addResource", resource)
                end if
            end if
        end if
    end while
end sub
