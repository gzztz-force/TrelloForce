@isTest
private class TestTimeCardSyncAutomation
{
    @isTest
    static void testTimeCardSyncService()
    {
        TestDataFactory.createTimeCardSyncSettings();
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<TeamMember__c> teamMembers = TestDataFactory.createTeamMembers(projects);
        TestDataFactory.createTimecards(teamMembers);


        // Three TimeCard records are created.W
        // The first TimeCard is created with Change field populated, but the specified Change has no External ID.
        // The second TimeCard is also created with Change field populated, and the specified Change does have External ID.
        // The third TimeCard is created without specifying any Change.
        Test.startTest();
        TimeCardSyncService.invokeTimeCardSync();
        Test.stopTest();
    }

    @isTest
    static void testTimeCardSyncScheduler()
    {
        Test.startTest();

        Date tomorrow = Date.today().addDays(1);
        String scheduleRunTime = '0 0 0 ' + tomorrow.day() + ' ' + tomorrow.month() + ' ? ' + tomorrow.year();
        system.schedule('Test Card Sync Automation', scheduleRunTime, new TimeCardSyncScheduler());

        Test.stopTest();
    }
}