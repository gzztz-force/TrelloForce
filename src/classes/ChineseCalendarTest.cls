/*
 * Test method for class ChineseCalendar.
 */
@isTest
private class ChineseCalendarTest
{
    @isTest
    static void testGetSolarDate()
    {
        System.assertEquals(Date.valueOf('2029-1-14'), ChineseCalendar.convertLunarToSolar('2028-11-30', false, false));
        System.assertEquals(Date.valueOf('1992-9-25'), ChineseCalendar.convertLunarToSolar('1992-8-29'));
        System.assertEquals(Date.valueOf('1991-4-14'), ChineseCalendar.convertLunarToSolar('1991-2-30'));
        System.assertEquals(Date.valueOf('2003-5-30'), ChineseCalendar.convertLunarToSolar('2003-4-30'));
        System.assertEquals(Date.valueOf('2029-2-12'), ChineseCalendar.convertLunarToSolar('2028-12-29'));

        // Test leap month
        System.assertEquals(Date.valueOf('2014-11-20'),
                ChineseCalendar.convertLunarToSolar('2014-9-28', true, false));

        // Test big month that will reduce 1 day
        System.assertEquals(Date.valueOf('2013-12-31'),
                ChineseCalendar.convertLunarToSolar('2013-11-30', false, true));

        // Test big month is invalid date
        try
        {
            ChineseCalendar.convertLunarToSolar('2013-11-30', false, false);
        }
        catch(Exception ex)
        {
            System.assert(ex.getMessage() != null);
        }

        // Test data is out of lunar date range
        try
        {
            ChineseCalendar.convertLunarToSolar('2222-11-30');
        }
        catch(Exception ex)
        {
            System.assert(ex.getMessage() != null);
        }

    }
}