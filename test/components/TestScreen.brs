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

    m.top.observeField("testResults", "onTestResults")
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

end sub
