' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

function main(args as object) as object

    return roca(args).describe("test suite", sub()
        m.beforeEach(sub()
            'print "- Before test"
        end sub)

        m.afterEach(sub()
            'print "- After test"
        end sub)

        m.it("has a test case", sub()
            'print "  - test 1"
            m.pass() 'required otherwise the test is marked as "Pending"
        end sub)

        ' m.it("has a another test case", sub()
        '     'print "  - test 2"
        '     m.pass()
        '     m.fail()
        ' end sub)

        ' m.it("has a third test case", sub()
        '     'print "  - test 3"
        '     m.assert.equal("foo", "bar", "whoops, these should be equal")
        ' end sub)
    end sub)
end function
