' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.

'*****************************************************************
'* Utilities to inspect RUM events
'*****************************************************************
function isValidResource(resource as object) as boolean
    status = resource.status
    if (status = "ok" or status = "" or status = invalid)
        return (resource.url <> invalid and resource.transferTime <> invalid)
    end if
    return false
end function