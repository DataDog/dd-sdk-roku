' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' ----------------------------------------------------------------
' Smoke test: verifies the roca setup is working correctly.
' Tests basic itemGenerator helpers and a trivial SDK function.
' ----------------------------------------------------------------
function main(args as object) as object
    return roca(args).describe("Roca setup smoke test", sub()

        m.describe("itemGenerator helpers", sub()
            m.it("IG_GetString returns a non-empty string", sub()
                result = IG_GetString(16)
                m.assert.isValid(result, "expected valid string")
                m.assert.isTrue(Len(result) > 0, "expected non-empty string")
                m.assert.isTrue(Len(result) <= 16, "expected string length <= 16")
            end sub)

            m.it("IG_GetInteger returns a positive integer", sub()
                result = IG_GetInteger(100)
                m.assert.isValid(result, "expected valid integer")
                m.assert.isTrue(result >= 1, "expected result >= 1")
                m.assert.isTrue(result <= 100, "expected result <= 100")
            end sub)

            m.it("IG_GetBoolean returns a boolean", sub()
                result = IG_GetBoolean()
                m.assert.isValid(result, "expected valid boolean")
                m.assert.isTrue(type(result) = "Boolean", "expected Boolean type")
            end sub)

            m.it("IG_GetOneOf returns an element from the array", sub()
                data = ["a", "b", "c"]
                result = IG_GetOneOf(data)
                m.assert.isValid(result, "expected valid element")
                found = false
                for each item in data
                    if item = result
                        found = true
                    end if
                end for
                m.assert.isTrue(found, "result was not in the original array")
            end sub)
        end sub)

        m.describe("SDK library availability", sub()
            ' Note: functions with enum parameters (compiled to 'as object') require
            ' a string-to-string cast workaround due to brs interpreter boxing behaviour.
            ' Those are tested in the individual migrated test files.

            m.it("nanosToMillis converts 1000000 ns to 1 ms", sub()
                result = nanosToMillis(1000000&)
                m.assert.equal(result, 1, "1000000 ns should equal 1 ms")
            end sub)

            m.it("millisToNanos converts 1 ms to 1000000 ns", sub()
                result = millisToNanos(1&)
                m.assert.equal(result, 1000000, "1 ms should equal 1000000 ns")
            end sub)

            m.it("millisToSec converts 1000 ms to 1 second", sub()
                result = millisToSec(1000&)
                m.assert.isTrue(Abs(result - 1.0) < 0.001, "1000 ms should equal 1.0 s")
            end sub)
        end sub)

    end sub)
end function
