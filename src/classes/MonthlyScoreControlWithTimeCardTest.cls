/*
 * Test method for class ScoreControlWithTimeCard.
 */
@isTest
private class MonthlyScoreControlWithTimeCardTest
{
    @isTest
    static void testSchedule()
    {
        Test.startTest();
        MonthlyScoreControlWithTimeCard schedule = new MonthlyScoreControlWithTimeCard();
        Test.stopTest();

    }
    @isTest
    static void testBatch()
    {
        Test.startTest();
        User user = TestDataFactory.newUser('00e8000000183bS', '00E800000013v1n');
        insert user;
        MProject__c project = TestDataFactory.generateSampleActiveProject('TestProject');
        insert project;
        TeamMember__c teamMember = new TeamMember__c(User__c=user.Id, Project__c=project.Id);
        teamMember.Name = 'acme' + Datetime.now().getTime();
       // TeamMember__c teamMember = TestDataFactory.generateSampleTeamMember(project);
        insert teamMember;
        Score__c score = new Score__c();
        score.User__c = user.Id;
        insert score;
        Date firstDay = Date.newInstance(2014, 6, 1);
        List<TimeCard__c> timecards = new List<TimeCard__c>();
        for(Integer i = 0; i <= 23; i++)
        {
            timecards.add(new TimeCard__c(Project__c = project.Id, TeamMember__c = teamMember.Id, Hours__c = 8, Description__c = 'description' + i, Date__c = firstDay.addDays(i)));
        }
        insert timecards;
        //MonthlyScoreControlWithTimeCard ms = new MonthlyScoreControlWithTimeCard();
        //String jobId = System.schedule('testMonthlyScoreControlWithTimeCard', '0 0 0 1 7 ? 2014', ms);
        MonthlyScoreControlWithTimeCard batch = new MonthlyScoreControlWithTimeCard();
        Database.executeBatch(batch);

        System.assertNotEquals(0.3, [select Worth__c from  Score__c where User__c = :user.Id limit 1].Worth__c);
        Test.stopTest();
        System.assertEquals(0.3, [select Worth__c from  Score__c where User__c = :user.Id limit 1].Worth__c);


    }

}