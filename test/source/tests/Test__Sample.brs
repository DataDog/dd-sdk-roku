

'----------------------------------------------------------------
' Sample setup function.
'
' @return A configured TestSuite object.
'----------------------------------------------------------------
function TestSuite__Sample() as object

    ' Inherite your test suite from BaseTestSuite
    this = BaseTestSuite()

    ' Test suite name for log statistics
    this.Name = "Sample"

    this.SetUp = SampleTestSuite__SetUp
    this.TearDown = SampleTestSuite__TearDown

    ' Add tests to suite's tests collection
    this.addTest("CheckDataCount", TestCase__Sample_CheckDataCount)

    return this
end function



'----------------------------------------------------------------
' This function called immediately before running tests of current suite.
' This function called to prepare all data for testing.
'----------------------------------------------------------------
sub SampleTestSuite__SetUp()
    ' Target testing object. To avoid the object creation in each test
    ' we create instance of target object here and use it in tests as m.targetTestObject.
    m.mainData = []
end sub

'----------------------------------------------------------------
' This function called immediately after running tests of current suite.
' This function called to clean or remove all data for testing.
'----------------------------------------------------------------
sub SampleTestSuite__TearDown()
    ' Remove all the test data
    m.Delete("mainData")
end sub


'----------------------------------------------------------------
' Check if data has an expected amount of items
'
' @return An empty string if test is success or error message if not.
'----------------------------------------------------------------
function TestCase__Sample_CheckDataCount() as string
    return m.assertArrayCount(m.mainData, 15)
end function