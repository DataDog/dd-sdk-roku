'*****************************************************************
'* Roku Unit Testing Framework
'* Automating test suites for Roku channels.
'*
'* Build Version: 2.1.1
'* Build Date: 05/06/2019
'*
'* Public Documentation is avaliable on GitHub:
'* 		https://github.com/rokudev/unit-testing-framework
'*
'*****************************************************************
'*****************************************************************
'* Licensed under the Apache License Version 2.0
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************

' Functions in this file:

'     BaseTestSuite
'     BTS__AddTest
'     BTS__CreateTest
'     BTS__Fail
'     BTS__AssertFalse
'     BTS__AssertTrue
'     BTS__AssertEqual
'     BTS__AssertNotEqual
'     BTS__AssertInvalid
'     BTS__AssertNotInvalid
'     BTS__AssertAAHasKey
'     BTS__AssertAANotHasKey
'     BTS__AssertAAHasKeys
'     BTS__AssertAANotHasKeys
'     BTS__AssertArrayContains
'     BTS__AssertArrayNotContains
'     BTS__AssertArrayContainsSubset
'     BTS__AssertArrayNotContainsSubset
'     BTS__AssertArrayCount
'     BTS__AssertArrayNotCount
'     BTS__AssertEmpty
'     BTS__AssertNotEmpty
'     BTS__MultipleAssertions
'     BTS__AssertBetween
'     BTS__AssertGreaterThan

' ----------------------------------------------------------------
' Main function. Create BaseTestSuite object.

' @return A BaseTestSuite object.
' ----------------------------------------------------------------
function BaseTestSuite()
    this = {}
    this.Name = "BaseTestSuite"
    this.SKIP_TEST_MESSAGE_PREFIX = "SKIP_TEST_MESSAGE_PREFIX__"
    ' Test Cases methods
    this.testCases = []
    this.IS_NEW_APPROACH = false
    this.addTest = BTS__AddTest
    this.createTest = BTS__CreateTest
    this.StorePerformanceData = BTS__StorePerformanceData

    ' Assertion methods which determine test failure or skipping
    this.skip = BTS__Skip
    this.fail = BTS__Fail
    this.assertFalse = BTS__AssertFalse
    this.assertTrue = BTS__AssertTrue
    this.assertEqual = BTS__AssertEqual
    this.assertNotEqual = BTS__AssertNotEqual
    this.assertInvalid = BTS__AssertInvalid
    this.assertNotInvalid = BTS__AssertNotInvalid
    this.assertAAHasKey = BTS__AssertAAHasKey
    this.assertAANotHasKey = BTS__AssertAANotHasKey
    this.assertAAHasKeys = BTS__AssertAAHasKeys
    this.assertAANotHasKeys = BTS__AssertAANotHasKeys
    this.assertArrayContains = BTS__AssertArrayContains
    this.assertArrayNotContains = BTS__AssertArrayNotContains
    this.assertArrayContainsSubset = BTS__AssertArrayContainsSubset
    this.assertArrayNotContainsSubset = BTS__AssertArrayNotContainsSubset
    this.assertArrayCount = BTS__AssertArrayCount
    this.assertArrayNotCount = BTS__AssertArrayNotCount
    this.assertEmpty = BTS__AssertEmpty
    this.assertNotEmpty = BTS__AssertNotEmpty
    this.multipleAssertions = BTS__MultipleAssertions
    this.assertBetween = BTS__AssertBetween
    this.assertGreater = BTS__AssertGreaterThan

    ' Type Comparison Functionality
    this.eqValues = TF_Utils__EqValues
    this.eqAssocArrays = TF_Utils__EqAssocArray
    this.eqArrays = TF_Utils__EqArray
    this.baseComparator = TF_Utils__BaseComparator

    return this
end function

' ----------------------------------------------------------------
' Add a test to a suite's test cases array.

' @param name (string) A test name.
' @param func (object) A pointer to test function.
' @param setup (object) A pointer to setup function.
' @param teardown (object) A pointer to teardown function.
' @param arg (dynamic) A test function arguments.
' @param hasArgs (boolean) True if test function has parameters.
' @param skip (boolean) Skip test run.
' ----------------------------------------------------------------
sub BTS__AddTest(name as string, func as object, setup = invalid as object, teardown = invalid as object, arg = invalid as dynamic, hasArgs = false as boolean, skip = false as boolean)
    m.testCases.Push(m.createTest(name, func, setup, teardown, arg, hasArgs, skip))
end sub

' ----------------------------------------------------------------
' Create a test object.

' @param name (string) A test name.
' @param func (object) A pointer to test function.
' @param setup (object) A pointer to setup function.
' @param teardown (object) A pointer to teardown function.
' @param arg (dynamic) A test function arguments.
' @param hasArgs (boolean) True if test function has parameters.
' @param skip (boolean) Skip test run.
'
' @return TestCase object.
' ----------------------------------------------------------------
function BTS__CreateTest(name as string, func as object, setup = invalid as object, teardown = invalid as object, arg = invalid as dynamic, hasArgs = false as boolean, skip = false as boolean) as object
    return {
        Name: name
        Func: func
        SetUp: setup
        TearDown: teardown
        TestSuite: m

        perfData: {}

        hasArguments: hasArgs
        arg: arg

        skip: skip
    }
end function

'----------------------------------------------------------------
' Store performance data to current test instance.
'
' @param name (string) A property name.
' @param value (Object) A value of data.
'----------------------------------------------------------------
sub BTS__StorePerformanceData(name as string, value as object)
    timestamp = StrI(CreateObject("roDateTime").AsSeconds())
    m.testInstance.perfData.Append({
        name: {
            "value": value
            "timestamp": timestamp
        }
    })
    ' print performance data to console
    ? "PERF_DATA: " + m.testInstance.Name + ": " + timestamp + ": " + name + "|" + TF_Utils__AsString(value)
end sub

' ----------------------------------------------------------------
' Assertion methods which determine test failure or skipping
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' Should be used to skip test cases. To skip test you must return the result of this method invocation.

' @param message (string) Optional skip message.
' Default value: "".

' @return A skip message, with a specific prefix added, in order to runner know that this test should be skipped.
' ----------------------------------------------------------------
function BTS__Skip(message = "" as string) as string
    ' add prefix so we know that this test is skipped, but not failed
    return m.SKIP_TEST_MESSAGE_PREFIX + message
end function

' ----------------------------------------------------------------
' Fail immediately, with the given message

' @param msg (string) An error message.
' Default value: "Error".

' @return An error message.
' ----------------------------------------------------------------
function BTS__Fail(msg = "Error" as string) as string
    return msg
end function

' ----------------------------------------------------------------
' Fail the test if the expression is true.

' @param expr (dynamic) An expression to evaluate.
' @param msg (string) An error message.
' Default value: "Expression evaluates to true"

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertFalse(expr as dynamic, msg = "Expression evaluates to true" as string) as string
    if not TF_Utils__IsBoolean(expr) or expr
        return BTS__Fail(msg)
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail the test unless the expression is true.

' @param expr (dynamic) An expression to evaluate.
' @param msg (string) An error message.
' Default value: "Expression evaluates to false"

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertTrue(expr as dynamic, msg = "Expression evaluates to false" as string) as string
    if not TF_Utils__IsBoolean(expr) or not expr then
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the two objects are unequal as determined by the '<>' operator.

' @param first (dynamic) A first object to compare.
' @param second (dynamic) A second object to compare.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertEqual(first as dynamic, second as dynamic, msg = "" as string) as string
    if not TF_Utils__EqValues(first, second)
        if msg = ""
            first_as_string = TF_Utils__AsString(first)
            second_as_string = TF_Utils__AsString(second)
            msg = first_as_string + " != " + second_as_string
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the two objects are equal as determined by the '=' operator.

' @param first (dynamic) A first object to compare.
' @param second (dynamic) A second object to compare.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertNotEqual(first as dynamic, second as dynamic, msg = "" as string) as string
    if TF_Utils__EqValues(first, second)
        if msg = ""
            first_as_string = TF_Utils__AsString(first)
            second_as_string = TF_Utils__AsString(second)
            msg = first_as_string + " == " + second_as_string
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the value is not invalid.

' @param value (dynamic) A value to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertInvalid(value as dynamic, msg = "" as string) as string
    if TF_Utils__IsValid(value)
        if msg = ""
            expr_as_string = TF_Utils__AsString(value)
            msg = expr_as_string + " <> Invalid"
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the value is invalid.

' @param value (dynamic) A value to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertNotInvalid(value as dynamic, msg = "" as string) as string
    if not TF_Utils__IsValid(value)
        if msg = ""
            if LCase(Type(value)) = "<uninitialized>" then value = invalid
            expr_as_string = TF_Utils__AsString(value)
            msg = expr_as_string + " = Invalid"
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the key.

' @param array (dynamic) A target array.
' @param key (string) A key name.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAAHasKey(array as dynamic, key as dynamic, msg = "" as string) as string
    if not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array)
        if not array.DoesExist(key)
            if msg = ""
                msg = "Array doesn't have the '" + key + "' key."
            end if
            return msg
        end if
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array has the key.

' @param array (dynamic) A target array.
' @param key (string) A key name.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAANotHasKey(array as dynamic, key as dynamic, msg = "" as string) as string
    if not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array)
        if array.DoesExist(key)
            if msg = ""
                msg = "Array has the '" + key + "' key."
            end if
            return msg
        end if
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the keys list.

' @param array (dynamic) A target associative array.
' @param keys (object) A key names array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAAHasKeys(array as dynamic, keys as object, msg = "" as string) as string
    if not TF_Utils__IsAssociativeArray(array)
        return "Input value is not an Associative Array."
    end if

    if not TF_Utils__IsArray(keys) or keys.Count() = 0
        return "Keys value is not an Array or is empty."
    end if

    if TF_Utils__IsAssociativeArray(array) and TF_Utils__IsArray(keys)
        for each key in keys
            if not TF_Utils__IsString(key)
                return "Key value has invalid type."
            end if

            if not array.DoesExist(key)
                if msg = ""
                    msg = "Array doesn't have the '" + key + "' key."
                end if

                return msg
            end if
        end for
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array has the keys list.

' @param array (dynamic) A target associative array.
' @param keys (object) A key names array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertAANotHasKeys(array as dynamic, keys as object, msg = "" as string) as string
    if not TF_Utils__IsAssociativeArray(array)
        return "Input value is not an Associative Array."
    end if

    if not TF_Utils__IsArray(keys) or keys.Count() = 0
        return "Keys value is not an Array or is empty."
    end if

    if TF_Utils__IsAssociativeArray(array) and TF_Utils__IsArray(keys)
        for each key in keys
            if not TF_Utils__IsString(key)
                return "Key value has invalid type."
            end if

            if array.DoesExist(key)
                if msg = ""
                    msg = "Array has the '" + key + "' key."
                end if
                return msg
            end if
        end for
    else
        msg = "Input value is not an Associative Array."
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the item.

' @param array (dynamic) A target array.
' @param value (dynamic) A value to check.
' @param key (object) A key name for associative array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayContains(array as dynamic, value as dynamic, key = invalid as dynamic, msg = "" as string) as string
    if key <> invalid and not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if not TF_Utils__ArrayContains(array, value, key)
            msg = "Array doesn't have the '" + TF_Utils__AsString(value) + "' value."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array has the item.

' @param array (dynamic) A target array.
' @param value (dynamic) A value to check.
' @param key (object) A key name for associative array.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayNotContains(array as dynamic, value as dynamic, key = invalid as dynamic, msg = "" as string) as string
    if key <> invalid and not TF_Utils__IsString(key)
        return "Key value has invalid type."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if TF_Utils__ArrayContains(array, value, key)
            msg = "Array has the '" + TF_Utils__AsString(value) + "' value."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array doesn't have the item subset.

' @param array (dynamic) A target array.
' @param subset (dynamic) An items array to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayContainsSubset(array as dynamic, subset as dynamic, msg = "" as string) as string
    if (TF_Utils__IsAssociativeArray(array) and TF_Utils__IsAssociativeArray(subset)) or (TF_Utils__IsArray(array) and TF_Utils__IsArray(subset))
        isAA = TF_Utils__IsAssociativeArray(subset)
        for each item in subset
            key = invalid
            value = item
            if isAA
                key = item
                value = subset[key]
            end if

            if not TF_Utils__ArrayContains(array, value, key)
                msg = "Array doesn't have the '" + TF_Utils__AsString(value) + "' value."

                return msg
            end if
        end for
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array have the item from subset.

' @param array (dynamic) A target array.
' @param subset (dynamic) A items array to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayNotContainsSubset(array as dynamic, subset as dynamic, msg = "" as string) as string
    if (TF_Utils__IsAssociativeArray(array) and TF_Utils__IsAssociativeArray(subset)) or (TF_Utils__IsArray(array) and TF_Utils__IsArray(subset))
        isAA = TF_Utils__IsAssociativeArray(subset)
        for each item in subset
            key = invalid
            value = item
            if isAA
                key = item
                value = subset[key]
            end if

            if TF_Utils__ArrayContains(array, value, key)
                msg = "Array has the '" + TF_Utils__AsString(value) + "' value."

                return msg
            end if
        end for
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array items count <> expected count

' @param array (dynamic) A target array.
' @param count (integer) An expected array items count.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayCount(array as dynamic, count as dynamic, msg = "" as string) as string
    if not TF_Utils__IsInteger(count)
        return "Count value should be an integer."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if array.Count() <> count
            msg = "Array items count <> " + TF_Utils__AsString(count) + "."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array items count = expected count.

' @param array (dynamic) A target array.
' @param count (integer) An expected array items count.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertArrayNotCount(array as dynamic, count as dynamic, msg = "" as string) as string
    if not TF_Utils__IsInteger(count)
        return "Count value should be an integer."
    end if

    if TF_Utils__IsAssociativeArray(array) or TF_Utils__IsArray(array)
        if array.Count() = count
            msg = "Array items count = " + TF_Utils__AsString(count) + "."

            return msg
        end if
    else
        msg = "Input value is not an Array."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the item is not empty array or string.

' @param item (dynamic) An array or string to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertEmpty(item as dynamic, msg = "" as string) as string
    if TF_Utils__IsAssociativeArray(item) or TF_Utils__IsArray(item)
        if item.Count() > 0
            msg = "Array is not empty."

            return msg
        end if
    else if TF_Utils__IsString(item)
        if Len(item) <> 0
            msg = "Input value is not empty."

            return msg
        end if
    else
        msg = "Input value is not an Array, AssociativeArray or String."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the item is empty array or string.

' @param item (dynamic) An array or string to check.
' @param msg (string) An error message.
' Default value: ""

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertNotEmpty(item as dynamic, msg = "" as string) as string
    if TF_Utils__IsAssociativeArray(item) or TF_Utils__IsArray(item)
        if item.Count() = 0
            msg = "Array is empty."

            return msg
        end if
    else if TF_Utils__IsString(item)
        if Len(item) = 0
            msg = "Input value is empty."

            return msg
        end if
    else
        msg = "Input value is not an Array, AssociativeArray or String."

        return msg
    end if

    return ""
end function

' ----------------------------------------------------------------
' Fail if the array contains at least one non empty string.

' @param item (objec) An array of strings to check.

' @return An error message.
' ----------------------------------------------------------------
function BTS__MultipleAssertions(assertions as object) as string
    failedAssertions = 0
    combinedMsg = ""
    for each assertion in assertions
        if (not TF_Utils__IsString(assertion))
            return "Expected assertions to be strings but found type " + type(assertion) + chr(10) + FormatJson(assertions)
        end if

        if (assertion <> "")
            failedAssertions++
            if (failedAssertions > 1)
                combinedMsg = combinedMsg + ";" + chr(10) + assertion
            else
                combinedMsg = assertion
            end if
        end if
    end for

    if (failedAssertions = 0)
        return ""
    else if (failedAssertions = 1)
        return combinedMsg
    else
        return failedAssertions.toStr() + " failed assertions: " + chr(10) + combinedMsg
    end if
end function

' ----------------------------------------------------------------
' Fail if the number is not between the given bounderaies

' @param item (objec) An array of strings to check.

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertBetween(number as dynamic, min as dynamic, max as dynamic, msg = "" as string) as string

    if (not TF_Utils__IsNumber(number))
        return "Expected number to be a number (integer, longinteger, float or double) but was " + type(number)
    else if (not TF_Utils__IsNumber(min))
        return "Expected min to be a number (integer, longinteger, float or double) but was " + type(min)
    else if (not TF_Utils__IsNumber(max))
        return "Expected max to be a number (integer, longinteger, float or double) but was " + type(max)
    end if

    if ((number < min) or (number > max))
        if (msg = "")
            msg = "Expected " + number.toStr() + " to be between " + min.toStr() + " and " + max.toStr()
        end if
        return msg
    end if
    return ""
end function

' ----------------------------------------------------------------
' Fail if the number is not between the given bounderaies

' @param item (objec) An array of strings to check.

' @return An error message.
' ----------------------------------------------------------------
function BTS__AssertGreaterThan(number as dynamic, boundary as dynamic, msg = "" as string) as string

    if (not TF_Utils__IsNumber(number))
        return "Expected number to be a number (integer, longinteger, float or double) but was " + type(number)
    else if (not TF_Utils__IsNumber(boundary))
        return "Expected boundary to be a number (integer, longinteger, float or double) but was " + type(boundary)
    end if

    if (number <= boundary)
        if (msg = "")
            msg = "Expected " + number.toStr() + " to be greater than " + boundary.toStr()
        end if
        return msg
    end if
    return ""
end function
