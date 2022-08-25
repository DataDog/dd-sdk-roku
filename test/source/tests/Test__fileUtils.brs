
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
    print "Result is "; result

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
    print "Result is "; result

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
