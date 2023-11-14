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
'     ItemGenerator
'     IG_GetItem
'     IG_GetAssocArray
'     IG_GetArray
'     IG_GetSimpleType
'     IG_GetBoolean
'     IG_GetInteger
'     IG_GetIntegerInRange
'     IG_GetFloat
'     IG_GetString

' ----------------------------------------------------------------
' Main function to generate object according to specified scheme.

' @param scheme (object) A scheme with desired object structure. Can be
' any simple type, array of types or associative array in form
'     { propertyName1 : "propertyType1"
'       propertyName2 : "propertyType2"
'       ...
'       propertyNameN : "propertyTypeN" }

' @return An object according to specified scheme or invalid,
' if scheme is not valid.
' ----------------------------------------------------------------
function ItemGenerator(scheme as object) as object
    this = {}

    this.getItem = IG_GetItem
    this.getAssocArray = IG_GetAssocArray
    this.getArray = IG_GetArray
    this.getSimpleType = IG_GetSimpleType
    this.getInteger = IG_GetInteger
    this.getIntegerInRange = IG_GetIntegerInRange
    this.getFloat = IG_GetFloat
    this.getString = IG_GetString
    this.getBoolean = IG_GetBoolean

    if not TF_Utils__IsValid(scheme)
        return invalid
    end if

    return this.getItem(scheme)
end function

' TODO: Create IG_GetInvalidItem function with random type fields

' ----------------------------------------------------------------
' Generate object according to specified scheme.

' @param scheme (object) A scheme with desired object structure.
' Can be any simple type, array of types or associative array.

' @return An object according to specified scheme or invalid,
' if scheme is not one of simple type, array or
' associative array.
' ----------------------------------------------------------------
function IG_GetItem(scheme as object) as object
    item = invalid

    if TF_Utils__IsAssociativeArray(scheme)
        item = IG_GetAssocArray(scheme)
    else if TF_Utils__IsArray(scheme)
        item = IG_GetArray(scheme)
    else if TF_Utils__IsString(scheme)
        item = IG_GetSimpleType(LCase(scheme))
    end if

    return item
end function

' ----------------------------------------------------------------
' Generates associative array according to specified scheme.

' @param scheme (object) An associative array with desired
'    object structure in form
'     { propertyName1 : "propertyType1"
'       propertyName2 : "propertyType2"
'       ...
'       propertyNameN : "propertyTypeN" }

' @return An associative array according to specified scheme.
' ----------------------------------------------------------------
function IG_GetAssocArray(scheme as object) as object
    item = {}

    for each key in scheme
        if not item.DoesExist(key)
            item[key] = IG_GetItem(scheme[key])
        end if
    end for

    return item
end function

' ----------------------------------------------------------------
' Generates array according to specified scheme.

' @param scheme (object) An array with desired object types.

' @return An array according to specified scheme.
' ----------------------------------------------------------------
function IG_GetArray(scheme as object) as object
    item = []

    for each key in scheme
        item.Push(IG_GetItem(key))
    end for

    return item
end function

' ----------------------------------------------------------------
' Generates random value of specified type.

' @param typeStr (string) A name of desired object type.

' @return A simple type object or invalid if type is not supported.
' ----------------------------------------------------------------
function IG_GetSimpleType(typeStr as string) as object
    item = invalid

    if typeStr = "integer" or typeStr = "int" or typeStr = "roint"
        item = IG_GetInteger()
    else if typeStr = "float" or typeStr = "rofloat"
        item = IG_GetFloat()
    else if typeStr = "string" or typeStr = "rostring"
        item = IG_GetString(10)
    else if typeStr = "boolean" or typeStr = "roboolean"
        item = IG_GetBoolean()
    end if

    return item
end function

' ----------------------------------------------------------------
' Generates random boolean value.

' @return A random boolean value.
' ----------------------------------------------------------------
function IG_GetBoolean() as boolean
    return TF_Utils__AsBoolean(Rnd(2) \ Rnd(2))
end function

' ----------------------------------------------------------------
' Generates random integer value from 1 to specified seed value.

' @param seed (integer) A seed value for Rnd function.
' Default value: 100.

' @return A random integer value.
' ----------------------------------------------------------------
function IG_GetInteger(seed = 100 as integer) as integer
    return Rnd(seed)
end function

' ----------------------------------------------------------------
' Generates random integer value from 1 to specified seed value.
' @return A random integer value.
' ----------------------------------------------------------------
function IG_GetLongInteger() as longinteger
    maxInt& = 2147483647
    result& = IG_GetInteger(maxInt&)
    result& *= maxInt&
    result& += IG_GetInteger(maxInt&)
    return result&
end function

' ----------------------------------------------------------------
' Generates random integer value in the given range.

' @param min (integer) the lower boundary (inclusive) of the range
' @param max (integer) the upper boundary (inclusive) of the range

' @return A random integer value.
' ----------------------------------------------------------------
function IG_GetIntegerInRange(min = 0 as integer, max = 100 as integer) as integer
    return Rnd(max - min + 1) + min - 1
end function

' ----------------------------------------------------------------
' Generates random float value.

' @return A random float value in the 0..1 range.
' ----------------------------------------------------------------
function IG_GetFloat() as float
    return Rnd(0)
end function

' ----------------------------------------------------------------
' Generates random double value.

' @return A random double value in the 0..1 range.
' ----------------------------------------------------------------
function IG_GetDouble() as double
    return Rnd(0)
end function

' ----------------------------------------------------------------
' Generates random string with specified length.

' @param seed (integer) A string length.

' @return A random string value or empty string if seed is 0.
' ----------------------------------------------------------------
function IG_GetString(seed as integer) as string
    item = ""
    if seed > 0
        stringLength = Rnd(seed)
        for i = 1 to stringLength ' final value is inclusive!
            chType = Rnd(3)

            if chType = 1 ' Chr(48-57) - numbers
                chNumber = 47 + Rnd(10)
            else if chType = 2 ' Chr(65-90) - Uppercase Letters
                chNumber = 64 + Rnd(26)
            else ' Chr(97-122) - Lowercase Letters
                chNumber = 96 + Rnd(26)
            end if

            item = item + Chr(chNumber)
        end for
    end if

    return item
end function

' ----------------------------------------------------------------
' Generates random element from array.

' @param data (array) An array of possible values.

' @return A random value from the array.
' ----------------------------------------------------------------
function IG_GetOneOf(data as object) as dynamic
    index = Rnd(data.count()) - 1
    return data[index]
end function

' ----------------------------------------------------------------
' Generates a random backtrace.
' @return the backtrace array.
' ----------------------------------------------------------------
function IG_GetBacktrace() as object
    size = IG_GetInteger(32)
    backtrace = []
    for i = 1 to size
        backtrace.Push(IG_GetBacktraceFrame())
    end for
    return backtrace
end function

' ----------------------------------------------------------------
' Generates a random backtrace frame.
' @return the backtrace frame object.
' ----------------------------------------------------------------
function IG_GetBacktraceFrame() as object
    return {
        function: IG_GetString(32),
        filename: IG_GetString(32),
        line_number: IG_GetInteger(128)
    }
end function

