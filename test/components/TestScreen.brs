' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

sub init()
    m.top.backgroundURI = "pkg:/images/main_bg_hd.jpg"
    m.top.setFocus(true)

    m.outputAbstract = m.top.findNode("outputAbstract")
    m.outputCorrect = m.top.findNode("outputCorrect")
    m.outputSkipped = m.top.findNode("outputSkipped")
    m.outputFail = m.top.findNode("outputFail")
    m.outputCrash = m.top.findNode("outputCrash")
    m.outputMessage = m.top.findNode("outputMessage")

    m.top.observeField("testResults", "onTestResults")
    m.top.observeField("message", "onMessage")
    m.top.observeField("crash", "onCrash")
end sub


' ----------------------------------------------------------------
' Callback used to display the test results on screen
' ----------------------------------------------------------------
sub onTestResults()

    testResults = m.top.testResults

    m.outputAbstract.text = "Ran " + testResults.total.toStr() + " tests in " + testResults.time.toStr() + "ms"
    if (testResults.correct > 0)
        m.outputCorrect.text = testResults.correct.toStr() + " passed"
    end if
    if (testResults.skipped > 0)
        m.outputSkipped.text = testResults.skipped.toStr() + " skipped"
    end if
    if (testResults.fail > 0)
        m.outputFail.text = testResults.fail.toStr() + " failed"
    end if
    if (testResults.crash > 0)
        m.outputCrash.text = testResults.crash.toStr() + " crashed"
    end if

    if (testResults.crash > 0)
        m.outputMessage.color = "0xe3554c"
    else if (testResults.fail > 0)
        m.outputMessage.color = "0xedb359"
    else if (testResults.skipped > 0)
        m.outputMessage.color = "0x9aaaba"
    else
        m.outputMessage.color = "0x1c2b34fa"
    end if

    output = ""
    for each entry in testResults.outputLog
        output = output + entry + chr(10)
    end for
    m.outputMessage.text = output
    m.outputMessage.setFocus(true)

end sub

' ----------------------------------------------------------------
' Callback used to display a message on screen
' ----------------------------------------------------------------
sub onMessage()
    m.outputMessage.text = m.top.message
    m.outputMessage.setFocus(true)
end sub

' ----------------------------------------------------------------
' Callback used to display an error on screen
' ----------------------------------------------------------------
sub onCrash()
    crash = m.top.crash

    m.outputMessage.text = datadogroku_errorToString(crash)
    m.outputMessage.color = "0xe3554c"
    m.outputMessage.setFocus(true)
end sub

