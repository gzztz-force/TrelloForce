/*
 * Test method for class ScoreControlWithTimeCard.
 */
@isTest
private class MonthlyScoreControlWithTimeCardTest
{
    @isTest
    static void testTimeCardGreaterThan23()
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
        MonthlyScoreControlWithTimeCard ms = new MonthlyScoreControlWithTimeCard();
        String jobId = System.schedule('testMonthlyScoreControlWithTimeCard', '0 0 0 1 7 ? 2014', ms);
        CronTrigger ct = [select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
        ID batchId = Database.executeBatch(ms);
        //Double scores1 = [select Worth__c from  Score__c where User__c = :UserInfo.getUserId() limit 1].Worth__c;
        System.assertNotEquals(0.3, [select Worth__c from  Score__c where User__c = :user.Id limit 1].Worth__c);
        Test.stopTest();
        //Double scores2 = [select Worth__c from  Score__c where User__c = :UserInfo.getUserId() limit 1].Worth__c;
        System.assertEquals(0.3, [select Worth__c from  Score__c where User__c = :user.Id limit 1].Worth__c);
    }

}