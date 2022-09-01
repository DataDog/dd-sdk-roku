
' Main entry point for the sample app
sub RunUserInterface()

    screen = CreateObject("roSGScreen")

    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    screen.CreateScene("MainScreen")
    screen.show()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if (msgType = "roSGScreenEvent")
            if (msg.isScreenClosed())
                return
            end if
        end if
    end while

end sub
