/*
 * Test method for class PerfectAttendanceCreditJob.
 */
@isTest
private class PerfectAttendanceCreditJobTest
{
    //Create user
    private static User user;
    static 
    {
        String ret = 'user' + Math.rint(Math.random() * 100000);
        user = new User();
        user.Email = 'test@test.com';
        user.Username = ret + '@testuser.com';
        user.LastName = 'test';
        user.Alias = 'test';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        user.TimeZoneSidKey = 'America/Chicago';
        user.EmailEncodingKey = 'UTF-8';

        user.UserRoleId = '00E800000013v1n';
        user.ProfileId = '00e8000000183bS';
        user.ManagerId = UserInfo.getUserId();
    }

    @isTest
    static void testSchedule()
    {
        Test.startTest();
        PerfectAttendanceCreditJob schedule = new PerfectAttendanceCreditJob();
        Test.stopTest();

    }
    @isTest
    static void testBatch()
    {
        System.runAs(user)
        {
            
            MProject__c project = TestDataFactory.generateSampleActiveProject('TestProject');
            insert project;
            TeamMember__c teamMember = new TeamMember__c(User__c=user.Id, Project__c=project.Id);
            teamMember.Name = 'acme' + Datetime.now().getTime();
            insert teamMember;

            Date firstDay = Date.newInstance(2014, 6, 1);
            List<TimeCard__c> timecards = new List<TimeCard__c>();
            for(Integer i = 0; i <= 23; i++)
            {
                timecards.add(new TimeCard__c(Project__c = project.Id, TeamMember__c = teamMember.Id, Hours__c = 8, Description__c = 'description' + i, Date__c = firstDay.addDays(i)));
            }
            insert timecards;
            
            Test.startTest();
            PerfectAttendanceCreditJob batch = new PerfectAttendanceCreditJob();
            Database.executeBatch(batch);
            Test.stopTest();

       } 
    }

}