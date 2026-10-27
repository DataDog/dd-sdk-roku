' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
' cspell:ignore ddsv
'import "pkg:/source/immutableRecords.bs"
'import "pkg:/source/fileUtils.bs"
'import "pkg:/source/rum/crashStorage.bs"

function viewSnapshotOwner(instanceId as string) as string
    if (instanceId = "")
        return ""
    end if
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(instanceId)
    return immutableRecordDigest(bytes).Left(32)
end function

function parseViewSnapshotName(filename as string) as dynamic
    parts = filename.Split("_")
    if (parts.Count() <> 8)
        return invalid
    end if
    if (parts[0] <> "" or parts[1] <> "ddsv2" or not isRecordHex(parts[2], 32))
        return invalid
    end if
    generation = parseLegacyBatchTimestamp(parts[3])
    if (generation = invalid)
        return invalid
    end if
    if (generation < 1 or generation > 2147483646 or generation.ToStr() <> parts[3])
        return invalid
    end if
    recordName = "_dd2_" + parts[4] + "_" + parts[5] + "_" + parts[6] + "_" + parts[7]
    record = parseImmutableRecordName(recordName)
    if (record = invalid)
        return invalid
    end if
    return {
        filename: filename
        owner: parts[2]
        generation: generation
        scope: record.scope
        recordName: recordName
    }
end function

function newViewSnapshotIO() as object
    io = newImmutableRecordIO()
    io.list = function(folder as string) as object
        return ListDir(folder)
    end function
    io.remove = function(path as string) as boolean
        return deleteFileIfPresent(path)
    end function
    return io
end function

' Reuse the checked single-write protocol under a prefix ignored by old readers.
function viewSnapshotRecordIO(io as object, owner as string, generation as longinteger) as object
    return {
        delegate: io
        prefix: "/_ddsv2_" + owner + "_" + generation.ToStr() + "_"
        exists: function(path as string) as boolean
            return m.delegate.exists(path.Replace("/_dd2_", m.prefix))
        end function
        write: function(path as string, bytes as object) as boolean
            return m.delegate.write(path.Replace("/_dd2_", m.prefix), bytes)
        end function
        read: function(path as string, byteCount as integer) as dynamic
            return m.delegate.read(path.Replace("/_dd2_", m.prefix), byteCount)
        end function
    }
end function

function isViewSnapshotClear(event as dynamic) as boolean
    if (GetInterface(event, "ifAssociativeArray") = invalid)
        return false
    end if
    if (GetInterface(event.cleared, "ifBoolean") = invalid)
        return false
    end if
    return event.cleared
end function

' Includes partial records in count/generation, but only verified valid JSON in value.
function listViewSnapshots(folder as string, scope as string, owner as string, io as object) as object
    entries = []
    for each filename in io.list(folder)
        info = parseViewSnapshotName(filename)
        if (info <> invalid)
            if (info.scope = scope and (owner = "" or info.owner = owner))
                info.value = invalid
                recordIO = viewSnapshotRecordIO(io, info.owner, info.generation)
                record = readImmutableRecord(folder, info.recordName, scope, recordIO)
                if (record <> invalid)
                    event = ParseJson(record.payload)
                    if (isViewSnapshotClear(event) or isRecoverableCrashView(event))
                        info.value = event
                    end if
                end if
                entries.Push(info)
            end if
        end if
    end for
    return entries
end function

function latestViewSnapshot(entries as object) as dynamic
    latest = invalid
    ambiguous = false
    for each entry in entries
        if (entry.value <> invalid)
            if (latest = invalid)
                latest = entry
            else if (entry.generation > latest.generation)
                latest = entry
                ambiguous = false
            else if (entry.generation = latest.generation and entry.filename <> latest.filename)
                ' Two writers claimed the same generation: do not choose arbitrarily.
                ambiguous = true
            end if
        end if
    end for
    if (ambiguous)
        return invalid
    end if
    return latest
end function

' Delete only generations superseded by this verified snapshot. Keep the latest
' until every older generation is gone; a clear marker must not resurrect a view.
function pruneViewSnapshots(folder as string, entries as object, latest as object, removeLatest as boolean, io as object) as integer
    remaining = entries.Count()
    olderRemoved = true
    for each entry in entries
        if (entry.owner = latest.owner and entry.scope = latest.scope)
            if (entry.generation < latest.generation)
                if (io.remove(folder + "/" + entry.filename))
                    remaining--
                else
                    olderRemoved = false
                end if
            else if (entry.generation = latest.generation and entry.filename <> latest.filename)
                olderRemoved = false
            end if
        end if
    end for
    if (removeLatest and olderRemoved)
        if (io.remove(folder + "/" + latest.filename))
            remaining--
        end if
    end if
    return remaining
end function

' One WriterTask serializes all requests for an instance. Four generations bound
' buildup under failed cleanup/partial writes; a full store preserves prior bytes.
function writeViewSnapshot(folder as string, scope as string, instanceId as string, event as object, io = invalid as object) as object
    owner = viewSnapshotOwner(instanceId)
    if (not isRecordHex(owner, 32) or not isRecordHex(scope, 64))
        return {
            status: "invalid_input"
        }
    end if
    if (not isViewSnapshotClear(event) and not isRecoverableCrashView(event))
        return {
            status: "invalid_input"
        }
    end if
    if (io = invalid)
        io = newViewSnapshotIO()
    end if
    entries = listViewSnapshots(folder, scope, owner, io)
    generation& = 0
    for each entry in entries
        if (entry.generation > generation&)
            generation& = entry.generation
        end if
    end for
    latest = latestViewSnapshot(entries)
    remaining = entries.Count()
    if (latest <> invalid)
        remaining = pruneViewSnapshots(folder, entries, latest, false, io)
    end if
    if (remaining >= 4 or generation& >= 2147483646)
        return {
            status: "capacity"
        }
    end if
    generation&++
    recordIO = viewSnapshotRecordIO(io, owner, generation&)
    result = writeImmutableRecord(folder, scope, FormatJson(event), recordIO)
    if (result.filename <> "")
        result.filename = "_ddsv2_" + owner + "_" + generation&.ToStr() + "_" + result.filename.Mid(5)
    end if
    if (result.status = "verified")
        ' Publication succeeded; now it is safe to remove older copies.
        entries = listViewSnapshots(folder, scope, owner, io)
        latest = latestViewSnapshot(entries)
        if (latest <> invalid)
            pruneViewSnapshots(folder, entries, latest, false, io)
        end if
    end if
    return result
end function