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
'* Copyright Roku 2011-2019
'* All Rights Reserved
'*****************************************************************
' Common framework utility functions
' *****************************************************************

function UTF_skip(msg = "")
    return UTF_PushErrorMessage(BTS__Skip(msg))
end function

function UTF_fail(msg = "")
    return UTF_PushErrorMessage(BTS__Fail(msg))
end function

function UTF_assertFalse(expr, msg = "Expression evaluates to true")
    return UTF_PushErrorMessage(BTS__AssertFalse(expr, msg))
end function

function UTF_assertTrue(expr, msg = "Expression evaluates to false")
    return UTF_PushErrorMessage(BTS__AssertTrue(expr, msg))
end function

function UTF_assertEqual(first, second, msg = "")
    return UTF_PushErrorMessage(BTS__AssertEqual(first, second, msg))
end function

function UTF_assertNotEqual(first, second, msg = "")
    return UTF_PushErrorMessage(BTS__AssertNotEqual(first, second, msg))
end function

function UTF_assertInvalid(value, msg = "")
    return UTF_PushErrorMessage(BTS__AssertInvalid(value, msg))
end function

function UTF_assertNotInvalid(value, msg = "")
    return UTF_PushErrorMessage(BTS__AssertNotInvalid(value, msg))
end function

function UTF_assertAAHasKey(array, key, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAAHasKey(array, key, msg))
end function

function UTF_assertAANotHasKey(array, key, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAANotHasKey(array, key, msg))
end function

function UTF_assertAAHasKeys(array, keys, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAAHasKeys(array, keys, msg))
end function

function UTF_assertAANotHasKeys(array, keys, msg = "")
    return UTF_PushErrorMessage(BTS__AssertAANotHasKeys(array, keys, msg))
end function

function UTF_assertArrayContains(array, value, key = invalid, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayContains(array, value, key, msg))
end function

function UTF_assertArrayNotContains(array, value, key = invalid, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayNotContains(array, value, key, msg))
end function

function UTF_assertArrayContainsSubset(array, subset, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayContainsSubset(array, subset, msg))
end function

function UTF_assertArrayNotContainsSubset(array, subset, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayNotContainsSubset(array, subset, msg))
end function

function UTF_assertArrayCount(array, count, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayCount(array, count, msg))
end function

function UTF_assertArrayNotCount(array, count, msg = "")
    return UTF_PushErrorMessage(BTS__AssertArrayNotCount(array, count, msg))
end function

function UTF_assertEmpty(item, msg = "")
    return UTF_PushErrorMessage(BTS__AssertEmpty(item, msg))
end function

function UTF_assertNotEmpty(item, msg = "")
    return UTF_PushErrorMessage(BTS__AssertNotEmpty(item, msg))
end function

function UTF_PushErrorMessage(message as string) as boolean
    result = Len(message) <= 0
    if not result then
        m.globalErrorsList.push(message)
    end if

    return result
end function

