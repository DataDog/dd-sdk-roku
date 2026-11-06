' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

' Completion for one uploader run is independent of file deletion. Never evict a
' remembered terminal outcome to admit another upload. Keys are complete paths.
function newRecordCompletionState(capacity = 256 as integer, clock = invalid as object) as object
    if (capacity < 0)
        capacity = 0
    else if (capacity > 256)
        capacity = 256
    end if
    if (clock = invalid)
        clock = CreateObject("roTimespan")
    end if
    return {
        capacity: capacity
        clock: clock
        entries: {}
        remaining: function() as integer
            return m.capacity - m.entries.Count()
        end function
        isKnown: function(path as string) as boolean
            return m.entries.DoesExist(path)
        end function
        reserve: function(paths as object) as boolean
            if (paths.Count() > m.remaining())
                return false
            end if
            seen = {}
            for each path in paths
                if (m.entries.DoesExist(path) or seen.DoesExist(path))
                    return false
                end if
                seen[path] = true
            end for
            for each path in paths
                m.entries[path] = {
                    state: "uploading"
                }
            end for
            return true
        end function
        release: sub(paths as object)
            for each path in paths
                entry = m.entries[path]
                if (entry <> invalid and entry.state = "uploading")
                    m.entries.Delete(path)
                end if
            end for
        end sub
        complete: sub(paths as object)
            now = m.clock.TotalMilliseconds()
            for each path in paths
                entry = m.entries[path]
                if (entry <> invalid and entry.state = "uploading")
                    m.entries[path] = {
                        state: "completed"
                        lastAttempt: now
                        delayMs: 0
                        nextDelayMs: 1000
                    }
                end if
            end for
        end sub
        cleanupDue: function() as object
            due = []
            now = m.clock.TotalMilliseconds()
            for each path in m.entries
                entry = m.entries[path]
                if (entry.state = "completed")
                    elapsed = now - entry.lastAttempt
                    if (elapsed < 0 or elapsed >= entry.delayMs)
                        due.Push(path)
                    end if
                end if
            end for
            return due
        end function
        cleanupResult: sub(path as string, removed as boolean)
            entry = m.entries[path]
            if (entry = invalid or entry.state <> "completed")
                return
            end if
            if (removed)
                m.entries.Delete(path)
            else
                entry.lastAttempt = m.clock.TotalMilliseconds()
                entry.delayMs = entry.nextDelayMs
                entry.nextDelayMs *= 2
                if (entry.nextDelayMs > 60000)
                    entry.nextDelayMs = 60000
                end if
            end if
        end sub
    }
end function