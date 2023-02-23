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

' *************************************************
' TF_Utils__IsXmlElement - check if value contains XMLElement interface
' @param value As Dynamic
' @return As Boolean - true if value contains XMLElement interface, else return false
' *************************************************
function TF_Utils__IsXmlElement(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifXMLElement") <> invalid
end function

' *************************************************
' TF_Utils__IsFunction - check if value contains Function interface
' @param value As Dynamic
' @return As Boolean - true if value contains Function interface, else return false
' *************************************************
function TF_Utils__IsFunction(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifFunction") <> invalid
end function

' *************************************************
' TF_Utils__IsBoolean - check if value contains Boolean interface
' @param value As Dynamic
' @return As Boolean - true if value contains Boolean interface, else return false
' *************************************************
function TF_Utils__IsBoolean(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifBoolean") <> invalid
end function

' *************************************************
' TF_Utils__IsInteger - check if value type equals Integer
' @param value As Dynamic
' @return As Boolean - true if value type equals Integer, else return false
' *************************************************
function TF_Utils__IsInteger(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifInt") <> invalid and (Type(value) = "roInt" or Type(value) = "roInteger" or Type(value) = "Integer")
end function

' *************************************************
' TF_Utils__IsFloat - check if value contains Float interface
' @param value As Dynamic
' @return As Boolean - true if value contains Float interface, else return false
' *************************************************
function TF_Utils__IsFloat(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifFloat") <> invalid
end function

' *************************************************
' TF_Utils__IsDouble - check if value contains Double interface
' @param value As Dynamic
' @return As Boolean - true if value contains Double interface, else return false
' *************************************************
function TF_Utils__IsDouble(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifDouble") <> invalid
end function

' *************************************************
' TF_Utils__IsLongInteger - check if value contains LongInteger interface
' @param value As Dynamic
' @return As Boolean - true if value contains LongInteger interface, else return false
' *************************************************
function TF_Utils__IsLongInteger(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifLongInt") <> invalid
end function

' *************************************************
' TF_Utils__IsNumber - check if value contains LongInteger or Integer or Double or Float interface
' @param value As Dynamic
' @return As Boolean - true if value is number, else return false
' *************************************************
function TF_Utils__IsNumber(value as dynamic) as boolean
    return TF_Utils__IsLongInteger(value) or TF_Utils__IsDouble(value) or TF_Utils__IsInteger(value) or TF_Utils__IsFloat(value)
end function

' *************************************************
' TF_Utils__IsList - check if value contains List interface
' @param value As Dynamic
' @return As Boolean - true if value contains List interface, else return false
' *************************************************
function TF_Utils__IsList(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifList") <> invalid
end function

' *************************************************
' TF_Utils__IsArray - check if value contains Array interface
' @param value As Dynamic
' @return As Boolean - true if value contains Array interface, else return false
' *************************************************
function TF_Utils__IsArray(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifArray") <> invalid
end function

' *************************************************
' TF_Utils__IsAssociativeArray - check if value contains AssociativeArray interface
' @param value As Dynamic
' @return As Boolean - true if value contains AssociativeArray interface, else return false
' *************************************************
function TF_Utils__IsAssociativeArray(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifAssociativeArray") <> invalid
end function

' *************************************************
' TF_Utils__IsSGNode - check if value contains SGNodeChildren interface
' @param value As Dynamic
' @return As Boolean - true if value contains SGNodeChildren interface, else return false
' *************************************************
function TF_Utils__IsSGNode(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifSGNodeChildren") <> invalid
end function

' *************************************************
' TF_Utils__IsString - check if value contains String interface
' @param value As Dynamic
' @return As Boolean - true if value contains String interface, else return false
' *************************************************
function TF_Utils__IsString(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and GetInterface(value, "ifString") <> invalid
end function

' *************************************************
' TF_Utils__IsNotEmptyString - check if value contains String interface and length more 0
' @param value As Dynamic
' @return As Boolean - true if value contains String interface and length more 0, else return false
' *************************************************
function TF_Utils__IsNotEmptyString(value as dynamic) as boolean
    return TF_Utils__IsString(value) and Len(value) > 0
end function

' *************************************************
' TF_Utils__IsDateTime - check if value contains DateTime interface
' @param value As Dynamic
' @return As Boolean - true if value contains DateTime interface, else return false
' *************************************************
function TF_Utils__IsDateTime(value as dynamic) as boolean
    return TF_Utils__IsValid(value) and (GetInterface(value, "ifDateTime") <> invalid or Type(value) = "roDateTime")
end function

' *************************************************
' TF_Utils__IsValid - check if value initialized and not equal invalid
' @param value As Dynamic
' @return As Boolean - true if value initialized and not equal invalid, else return false
' *************************************************
function TF_Utils__IsValid(value as dynamic) as boolean
    return Type(value) <> "<uninitialized>" and value <> invalid
end function

' *************************************************
' TF_Utils__ValidStr - return value if his contains String interface else return empty string
' @param value As Object
' @return As String - value if his contains String interface else return empty string
' *************************************************
function TF_Utils__ValidStr(obj as object) as string
    if obj <> invalid and GetInterface(obj, "ifString") <> invalid
        return obj
    else
        return ""
    end if
end function

' *************************************************
' TF_Utils__AsString - convert input to String if this possible, else return empty string
' @param input As Dynamic
' @return As String - return converted string
' *************************************************
function TF_Utils__AsString(input as dynamic) as string
    if TF_Utils__IsValid(input) = false
        return "<invalid>"
    else if TF_Utils__IsString(input)
        return """" + input + """"
    else if TF_Utils__IsInteger(input) or TF_Utils__IsLongInteger(input) or TF_Utils__IsBoolean(input)
        return input.ToStr()
    else if TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input)
        return Str(input).Trim()
    else if TF_Utils__IsSGNode(input)
        return "roSGNode/" + input.subtype()
    else if Type(input) = "roList"
        return "roList/" + FormatJson(input.ToArray())
    else if TF_Utils__IsArray(input)
        return FormatJson(input)
    else if TF_Utils__IsAssociativeArray(input)
        first = true
        asString = "{ "
        for each key in input
            if (not first)
                asString += ", "
            endif
            asString += key + ": " + TF_Utils__AsString(input[key]) 
            first = false
        end for
        asString += " }"
        return asString
    else
        throw "Can't convert type " + type(input) + " to string"
    end if
end function

' *************************************************
' TF_Utils__AsInteger - convert input to Integer if this possible, else return 0
' @param input As Dynamic
' @return As Integer - return converted Integer
' *************************************************
function TF_Utils__AsInteger(input as dynamic) as integer
    if TF_Utils__IsValid(input) = false
        return 0
    else if TF_Utils__IsString(input)
        return input.ToInt()
    else if TF_Utils__IsInteger(input)
        return input
    else if TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input) or TF_Utils__IsLongInteger(input)
        return Int(input)
    else
        return 0
    end if
end function

' *************************************************
' TF_Utils__AsLongInteger - convert input to LongInteger if this possible, else return 0
' @param input As Dynamic
' @return As Integer - return converted LongInteger
' *************************************************
function TF_Utils__AsLongInteger(input as dynamic) as longinteger
    if TF_Utils__IsValid(input) = false
        return 0
    else if TF_Utils__IsString(input)
        return TF_Utils__AsInteger(input)
    else if TF_Utils__IsLongInteger(input) or TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input) or TF_Utils__IsInteger(input)
        return input
    else
        return 0
    end if
end function

' *************************************************
' TF_Utils__AsFloat - convert input to Float if this possible, else return 0.0
' @param input As Dynamic
' @return As Float - return converted Float
' *************************************************
function TF_Utils__AsFloat(input as dynamic) as float
    if TF_Utils__IsValid(input) = false
        return 0.0
    else if TF_Utils__IsString(input)
        return input.ToFloat()
    else if TF_Utils__IsInteger(input)
        return (input / 1)
    else if TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input) or TF_Utils__IsLongInteger(input)
        return input
    else
        return 0.0
    end if
end function

' *************************************************
' TF_Utils__AsDouble - convert input to Double if this possible, else return 0.0
' @param input As Dynamic
' @return As Float - return converted Double
' *************************************************
function TF_Utils__AsDouble(input as dynamic) as double
    if TF_Utils__IsValid(input) = false
        return 0.0
    else if TF_Utils__IsString(input)
        return TF_Utils__AsFloat(input)
    else if TF_Utils__IsInteger(input) or TF_Utils__IsLongInteger(input) or TF_Utils__IsFloat(input) or TF_Utils__IsDouble(input)
        return input
    else
        return 0.0
    end if
end function

' *************************************************
' TF_Utils__AsBoolean - convert input to Boolean if this possible, else return False
' @param input As Dynamic
' @return As Boolean
' *************************************************
function TF_Utils__AsBoolean(input as dynamic) as boolean
    if TF_Utils__IsValid(input) = false
        return false
    else if TF_Utils__IsString(input)
        return LCase(input) = "true"
    else if TF_Utils__IsInteger(input) or TF_Utils__IsFloat(input)
        return input <> 0
    else if TF_Utils__IsBoolean(input)
        return input
    else
        return false
    end if
end function

' *************************************************
' TF_Utils__AsArray - if type of value equals array return value, else return array with one element [value]
' @param value As Object
' @return As Object - roArray
' *************************************************
function TF_Utils__AsArray(value as object) as object
    if TF_Utils__IsValid(value)
        if not TF_Utils__IsArray(value)
            return [value]
        else
            return value
        end if
    end if
    return []
end function

' =====================
' Strings
' =====================

' *************************************************
' TF_Utils__IsNullOrEmpty - check if value is invalid or empty
' @param value As Dynamic
' @return As Boolean - true if value is null or empty string, else return false
' *************************************************
function TF_Utils__IsNullOrEmpty(value as dynamic) as boolean
    if TF_Utils__IsString(value)
        return Len(value) = 0
    else
        return not TF_Utils__IsValid(value)
    end if
end function

' =====================
' Arrays
' =====================

' *************************************************
' TF_Utils__FindElementIndexInArray - find an element index in array
' @param array As Object
' @param value As Object
' @param compareAttribute As Dynamic
' @param caseSensitive As Boolean
' @return As Integer - element index if array contains a value, else return -1
' *************************************************
function TF_Utils__FindElementIndexInArray(array as object, value as object, compareAttribute = invalid as dynamic, caseSensitive = false as boolean) as integer
    if TF_Utils__IsArray(array)
        for i = 0 to TF_Utils__AsArray(array).Count() - 1
            compareValue = array[i]

            if compareAttribute <> invalid and TF_Utils__IsAssociativeArray(compareValue) and compareValue.DoesExist(compareAttribute)
                compareValue = compareValue.LookupCI(compareAttribute)
            end if

            if TF_Utils__IsString(compareValue) and TF_Utils__IsString(value) and not caseSensitive
                if LCase(compareValue) = LCase(value)
                    return i
                end if
            else if TF_Utils__BaseComparator(compareValue, value)
                return i
            end if

            item = array[i]
        next
    end if

    return -1
end function

' *************************************************
' TF_Utils__ArrayContains - check if array contains specified value
' @param array As Object
' @param value As Object
' @param compareAttribute As Dynamic
' @return As Boolean - true if array contains a value, else return false
' *************************************************
function TF_Utils__ArrayContains(array as object, value as object, compareAttribute = invalid as dynamic) as boolean
    return (TF_Utils__FindElementIndexInArray(array, value, compareAttribute) > -1)
end function

' ----------------------------------------------------------------
' Type Comparison Functionality
' ----------------------------------------------------------------

' ----------------------------------------------------------------
' Compare two arbitrary values to each other.

' @param Value1 (dynamic) A first item to compare.
' @param Value2 (dynamic) A second item to compare.
' @param comparator (Function, optional) Function, to compare 2 values. Should take in 2 parameters and return either true or false.

' @return True if values are equal or False in other case.
' ----------------------------------------------------------------
function TF_Utils__EqValues(Value1 as dynamic, Value2 as dynamic, comparator = invalid as object) as boolean
    if comparator = invalid
        return TF_Utils__BaseComparator(value1, value2)
    else
        return comparator(value1, value2)
    end if
end function

' ----------------------------------------------------------------
' Base comparator for comparing two values.

' @param Value1 (dynamic) A first item to compare.
' @param Value2 (dynamic) A second item to compare.

' @return True if values are equal or False in other case.
function TF_Utils__BaseComparator(value1 as dynamic, value2 as dynamic) as boolean
    value1Type = Type(value1)
    value2Type = Type(value2)

    if (value1Type = "roList" or value1Type = "roArray") and (value2Type = "roList" or value2Type = "roArray")
        return TF_Utils__EqArray(value1, value2)
    else if value1Type = "roAssociativeArray" and value2Type = "roAssociativeArray"
        return TF_Utils__EqAssocArray(value1, value2)
    else if value1Type = "roDeviceInfo" and value2Type = "roDeviceInfo"
        return true
    else if value1Type = "roAppInfo" and value2Type = "roAppInfo"
        return true
    else if TF_Utils__IsNumber(value1) and TF_Utils__IsNumber(value2)
        return Abs(value1 - value2) < 0.0001
    else if Type(box(value1), 3) = Type(box(value2), 3)
        return value1 = value2
    else
        return false
    end if
end function

' ----------------------------------------------------------------
' Compare two roAssociativeArray objects for equality.

' @param Value1 (object) A first associative array.
' @param Value2 (object) A second associative array.

' @return True if arrays are equal or False in other case.
' ----------------------------------------------------------------
function TF_Utils__EqAssocArray(Value1 as object, Value2 as object) as boolean
    l1 = Value1.Count()
    l2 = Value2.Count()

    if not l1 = l2
        return false
    else
        for each k in Value1
            if not Value2.DoesExist(k)
                return false
            else
                v1 = Value1[k]
                v2 = Value2[k]
                if not TF_Utils__EqValues(v1, v2)
                    return false
                end if
            end if
        end for
        return true
    end if
end function

' ----------------------------------------------------------------
' Compare two roArray objects for equality.

' @param Value1 (object) A first array.
' @param Value2 (object) A second array.

' @return True if arrays are equal or False in other case.
' ----------------------------------------------------------------
function TF_Utils__EqArray(Value1 as object, Value2 as object) as boolean
    l1 = Value1.Count()
    l2 = Value2.Count()

    if not l1 = l2
        return false
    else
        for i = 0 to l1 - 1
            v1 = Value1[i]
            v2 = Value2[i]
            if not TF_Utils__EqValues(v1, v2) then
                return false
            end if
        end for
        return true
    end if
end function