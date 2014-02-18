/*
 * Test method for class LunarToSolarConversion.
 */
@isTest
private class LunarToSolarConversionTest
{
    @isTest
    static void testGetSolarDate()
    {
        System.assertEquals(Date.valueOf('2029-1-14'), LunarToSolarConversion.getSolarDate(2028, 11, 30));
        System.assertEquals(Date.valueOf('1992-9-25'), LunarToSolarConversion.getSolarDate(1992, 8, 29));
        System.assertEquals(Date.valueOf('1991-4-14'), LunarToSolarConversion.getSolarDate(1991, 2, 30));
        System.assertEquals(Date.valueOf('2003-5-30'), LunarToSolarConversion.getSolarDate(2003, 4, 30));

        Date testDate1 = LunarToSolarConversion.getBirthdayThisYear(11, 30, 'Lunar');
        Date testDate2 = LunarToSolarConversion.getBirthdayThisYear(3, 30, 'Solar');
        Date testDate3 = LunarToSolarConversion.getBirthdayThisYear(2, 18, 'Lunar');
        Date testDate4 = LunarToSolarConversion.getBirthdayNextYear(8, 29, 'Lunar');
        Date testDate5 = LunarToSolarConversion.getBirthdayNextYear(2, 28, 'Solar');
        Date testDate6 = LunarToSolarConversion.getBirthdayNextYear(5, 25, 'Lunar');
    }
}