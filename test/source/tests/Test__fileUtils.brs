
'----------------------------------------------------------------
' Main setup function.
' @return A configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__FileUtils() as object
    this = BaseTestSuite()
    this.Name = "FileUtils"

    this.addTest("WhenMkDirs_ThenCreateDir", FileUtilsTest__WhenMkDirs_ThenCreateDir)
    this.addTest("WhenMkDirsExisting_ThenDoNothing", FileUtilsTest__WhenMkDirsExisting_ThenDoNothing)
    this.addTest("WhenMkDirs_ThenCreateParentDirs", FileUtilsTest__WhenMkDirs_ThenCreateParentDirs)
    this.addTest("WhenMkDirsInvalidPath_ThenDoNothing", FileUtilsTest__WhenMkDirsInvalidPath_ThenDoNothing)
    this.addTest("WhenTrackFolderPath_ThenComputePath", FileUtilsTest__WhenTrackFolderPath_ThenComputePath)
    this.addTest("WhenAppendAsciiFile_ThenAppendsToExistingFile", FileUtilsTest__WhenAppendAsciiFile_ThenAppendsToExistingFile)
    this.addTest("WhenAppendAsciiFile_ThenAppendsToEmptyFile", FileUtilsTest__WhenAppendAsciiFile_ThenAppendsToEmptyFile)
    this.addTest("WhenStrToLong_ThenReturnsLong", FileUtilsTest__WhenStrToLong_ThenReturnsLong)
    this.addTest("WhenStrToLongOnString_ThenReturnsLong", FileUtilsTest__WhenStrToLongOnString_ThenReturnsLong)

    return this
end function

'----------------------------------------------------------------
' Checks that mkdirs creates the required directory
'----------------------------------------------------------------
function FileUtilsTest__WhenMkDirs_ThenCreateDir() as string
    ' Given
    fileSystem = CreateObject("roFileSystem")
    path = IG_GetOneOf(["cachefs", "tmp"]) + ":/" + IG_GetString(16)
    if (fileSystem.Exists(path))
        return "Random folder at " + path + " shouldn't exist"
    end if

    ' When
    result = datadogroku_mkdirs(path)

    ' Then
    return m.multipleAssertions([
        m.assertTrue(result, "Expected result to be true"),
        m.assertTrue(fileSystem.Exists(path), "Random folder at " + path + " should exist")
    ])
end function

'----------------------------------------------------------------
' Checks that mkdirs does nothing if folder already exists
'----------------------------------------------------------------
function FileUtilsTest__WhenMkDirsExisting_ThenDoNothing() as string
    ' Given
    fileSystem = CreateObject("roFileSystem")
    path = IG_GetOneOf(["cachefs", "tmp"]) + ":/" + IG_GetString(16)
    if (fileSystem.Exists(path))
        return "Random folder at " + path + " shouldn't exist"
    end if

    ' When
    result = datadogroku_mkdirs(path)
    result2 = datadogroku_mkdirs(path)

    ' Then
    return m.multipleAssertions([
        m.assertTrue(result, "Expected result to be true"),
        m.assertTrue(result2, "Expected result2 to be true"),
        m.assertTrue(fileSystem.Exists(path), "Random folder at " + path + " should exist")
    ])
end function

'----------------------------------------------------------------
' Checks that mkdirs creates all intermediate directories
'----------------------------------------------------------------
function FileUtilsTest__WhenMkDirs_ThenCreateParentDirs() as string
    ' Given
    fileSystem = CreateObject("roFileSystem")
    folderNames = IG_GetArray(["string", "string", "string", "string"])
    path = IG_GetOneOf(["cachefs", "tmp"]) + ":"
    for each folderName in folderNames
        path = path + "/" + folderName
    end for
    if (fileSystem.Exists(path))
        return "Random folder at " + path + " shouldn't exist"
    end if

    ' When
    result = datadogroku_mkdirs(path)

    ' Then
    return m.multipleAssertions([
        m.assertTrue(result, "Expected result to be true"),
        m.assertTrue(fileSystem.Exists(path), "Random folder at " + path + " should exist")
    ])
end function

'----------------------------------------------------------------
' Checks that mkdirs fails silently when an invalid path is provided
' cf: https://developer.roku.com/en-gb/docs/developer-program/getting-started/architecture/file-system.md
'----------------------------------------------------------------
function FileUtilsTest__WhenMkDirsInvalidPath_ThenDoNothing() as string
    ' Given
    fileSystem = CreateObject("roFileSystem")
    invalidChar = IG_GetOneOf(["<", ">", """", ":", "|", "?", "*"])
    path = IG_GetOneOf(["foo", "bar"]) + ":/" + IG_GetString(8) + invalidChar + IG_GetString(8)
    if (fileSystem.Exists(path))
        return "Random folder at " + path + " shouldn't exist"
    end if

    ' When
    result = datadogroku_mkdirs(path)

    ' Then
    return m.multipleAssertions([
        m.assertFalse(result, "Expected result to be false"),
        m.assertFalse(fileSystem.Exists(path), "Random folder at " + path + " shouldn't exist")
    ])
end function

'----------------------------------------------------------------
' Checks that trackFolderPath creates a relevant path
'----------------------------------------------------------------
function FileUtilsTest__WhenTrackFolderPath_ThenComputePath() as string
    ' Given
    trackType = IG_GetString(8)
    version = IG_GetInteger(64)

    ' When
    result = datadogroku_trackFolderPath(trackType, version)

    ' Then
    return m.multipleAssertions([
        m.assertEqual(result, "cachefs:/datadog/v" + version.toStr() + "/" + trackType)
    ])
end function

'----------------------------------------------------------------
' Checks that AppendAsciiFile appends data to an existing file
'----------------------------------------------------------------
function FileUtilsTest__WhenAppendAsciiFile_ThenAppendsToExistingFile() as string
    ' Given
    filepath = IG_GetOneOf(["cachefs", "tmp"]) + ":/" + IG_GetString(8)
    initialText = IG_GetString(8)
    appendedText = IG_GetString(8)
    WriteAsciiFile(filepath, initialText)

    ' When
    result = datadogroku_AppendAsciiFile(filepath, appendedText)

    ' Then
    return m.multipleAssertions([
        m.assertEqual(result, true)
        m.assertEqual(ReadAsciiFile(filepath), initialText + appendedText)
    ])
end function

'----------------------------------------------------------------
' Checks that AppendAsciiFile writes to an existing empty file
'----------------------------------------------------------------
function FileUtilsTest__WhenAppendAsciiFile_ThenAppendsToEmptyFile() as string
    ' Given
    filepath = IG_GetOneOf(["cachefs", "tmp"]) + ":/" + IG_GetString(8)
    appendedText = IG_GetString(8)
    WriteAsciiFile(filepath, "")

    ' When
    result = datadogroku_AppendAsciiFile(filepath, appendedText)

    ' Then
    return m.multipleAssertions([
        m.assertEqual(result, true)
        m.assertEqual(ReadAsciiFile(filepath), appendedText)
    ])
end function

'----------------------------------------------------------------
' Checks that AppendAsciiFile creates and writes to a non-existing file
'----------------------------------------------------------------
function FileUtilsTest__WhenAppendAsciiFile_ThenCreateNewFile() as string
    ' Given
    filepath = IG_GetOneOf(["cachefs", "tmp"]) + ":/" + IG_GetString(8)
    appendedText = IG_GetString(8)

    ' When
    result = datadogroku_AppendAsciiFile(filepath, appendedText)

    ' Then
    return m.multipleAssertions([
        m.assertEqual(result, true)
        m.assertEqual(ReadAsciiFile(filepath), appendedText)
    ])
end function

'----------------------------------------------------------------
' Checks that strToLong parses long properly
'----------------------------------------------------------------
function FileUtilsTest__WhenStrToLong_ThenReturnsLong() as string
    assertions = []

    for i = 0 to 100
        ' Given
        input& = IG_GetLongInteger()
        input$ = input&.toStr()

        ' When
        result& = datadogroku_strToLong(input$)

        ' Then
        assertions.Push(m.assertEqual(result&, input&))
    end for
    return m.multipleAssertions(assertions)
end function

'----------------------------------------------------------------
' Checks that strToLong parses not long safely
'----------------------------------------------------------------
function FileUtilsTest__WhenStrToLongOnString_ThenReturnsLong() as string
    assertions = []

    for i = 0 to 100
        ' Given
        input$ = IG_GetString(128)

        ' When
        crashed = false
        try
            datadogroku_strToLong(input$)
        catch e
            crashed = true
        end try

        ' Then
        assertions.Push(m.assertFalse(crashed))
    end for

    return m.multipleAssertions(assertions)
end function
