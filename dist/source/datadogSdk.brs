' Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
' This product includes software developed at Datadog (https://www.datadoghq.com/).
' Copyright 2022-Today Datadog, Inc.
'*****************************************************************
'* "Constants" for the SDK
'*****************************************************************
' ----------------------------------------------------------------
' The available track types for the uploader/writer
' ----------------------------------------------------------------


' ----------------------------------------------------------------
' @return (string) the version of the library
' TODO generate this from the package.json
' ----------------------------------------------------------------
function sdkVersion() as string
    return "1.0.0-dev"
end function

' ----------------------------------------------------------------
' @return (string) the source to report in events
' ----------------------------------------------------------------
function agentSource() as string
    return "roku"
end function