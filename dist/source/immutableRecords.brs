' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' New records are immutable by construction: a fresh ID receives exactly one write.
' Length and digest are known before writing; recovery needs no mutable owner lease.
' Old SDK versions ignore the reserved leading underscore.
function immutableRecordDigest(bytes as object) as string
    digest = CreateObject("roEVPDigest")
    if (digest.Setup("sha256") <> 0)
        return ""
    end if
    return LCase(digest.Process(bytes))
end function

' Stable routing metadata for new records only. Do not include SDK/app versions.
' Existing unscoped numeric files are neither migrated nor assigned a new scope.
function immutableRecordScope(channelId as string, destination as string, clientToken as string, applicationId as string) as string
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(FormatJson([
        channelId
        destination
        clientToken
        applicationId
    ]))
    return immutableRecordDigest(bytes)
end function

function isRecordHex(value as string, length as integer) as boolean
    if (value.Len() <> length)
        return false
    end if
    for i = 1 to value.Len()
        digit = Asc(Mid(value, i, 1))
        if (not ((digit >= 48 and digit <= 57) or (digit >= 97 and digit <= 102)))
            return false
        end if
    end for
    return true
end function

function parseImmutableRecordName(filename as string) as dynamic
    parts = filename.Split("_")
    if (parts.Count() <> 6)
        return invalid
    end if
    if (parts[0] <> "" or parts[1] <> "dd2")
        return invalid
    end if
    if (not isRecordHex(parts[2], 64) or not isRecordHex(parts[3], 32) or not isRecordHex(parts[5], 64))
        return invalid
    end if
    lengthText = parts[4]
    if (lengthText.Len() = 0 or lengthText.Len() > 10 or lengthText.Left(1) = "0")
        return invalid
    end if
    for i = 1 to lengthText.Len()
        digit = Asc(Mid(lengthText, i, 1))
        if (digit < 48 or digit > 57)
            return invalid
        end if
    end for
    if (lengthText.Len() = 10 and lengthText > "2147483646")
        return invalid
    end if
    return {
        scope: parts[2]
        id: parts[3]
        byteCount: lengthText.ToInt()
        digest: parts[5]
    }
end function

' Injectable filesystem boundary. Reads retain a byte array until validation has
' completed; callers must post this snapshot, never reread the filename afterward.
function newImmutableRecordIO() as object
    return {
        exists: function(path as string) as boolean
            return CreateObject("roFileSystem").Exists(path)
        end function
        write: function(path as string, bytes as object) as boolean
            return bytes.WriteFile(path)
        end function
        read: function(path as string, _byteCount as integer) as dynamic
            bytes = CreateObject("roByteArray")
            ' Validate the complete read, including any unexpected trailing bytes.
            if (not bytes.ReadFile(path))
                return invalid
            end if
            return bytes
        end function
    }
end function

function readImmutableRecord(folderPath as string, filename as string, scope as string, io = invalid as object) as dynamic
    info = parseImmutableRecordName(filename)
    if (info = invalid)
        return invalid
    end if
    if (info.scope <> scope)
        return invalid
    end if
    if (io = invalid)
        io = newImmutableRecordIO()
    end if
    bytes = io.read(folderPath + "/" + filename, info.byteCount)
    if (bytes = invalid)
        return invalid
    end if
    if (bytes.Count() <> info.byteCount)
        return invalid
    end if
    if (immutableRecordDigest(bytes) <> info.digest)
        return invalid
    end if
    return {
        filename: filename
        id: info.id
        byteCount: info.byteCount
        payload: bytes.ToAsciiString()
    }
end function

' A failed/uncertain write is never retried into the same path or deleted here.
' A complete matching record may be discovered later even if verification failed.
function writeImmutableRecord(folderPath as string, scope as string, event as string, io = invalid as object, recordId = "" as string) as object
    if (not isRecordHex(scope, 64) or event = "")
        return {
            status: "invalid_input"
            filename: ""
        }
    end if
    if (recordId = "")
        recordId = LCase(CreateObject("roDeviceInfo").GetRandomUUID().Replace("-", ""))
    end if
    if (not isRecordHex(recordId, 32))
        return {
            status: "invalid_input"
            filename: ""
        }
    end if
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(event)
    hash = immutableRecordDigest(bytes)
    if (not isRecordHex(hash, 64))
        return {
            status: "digest_failed"
            filename: ""
        }
    end if
    filename = "_dd2_" + scope + "_" + recordId + "_" + bytes.Count().toStr() + "_" + hash
    if (io = invalid)
        io = newImmutableRecordIO()
    end if
    path = folderPath + "/" + filename
    if (io.exists(path))
        return {
            status: "collision"
            filename: filename
        }
    end if
    if (not io.write(path, bytes))
        return {
            status: "write_failed"
            filename: filename
        }
    end if
    verified = readImmutableRecord(folderPath, filename, scope, io)
    if (verified = invalid)
        return {
            status: "verification_failed"
            filename: filename
        }
    end if
    return {
        status: "verified"
        filename: filename
    }
end function