/**
 * Test method for LogTimeCardController
 */
@isTest
private class LogTimeCardControllerTest
{
    @isTest static void testNewUserNoUsedProject()
    {
        createProjectAndTeamMember();

        Test.startTest();
        LogTimeCardController controller = new LogTimeCardController();
        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }

    @isTest static void testOldUserHasUsedProject()
    {

        List<TeamMember__c> tms = createProjectAndTeamMember();
        createChangeAndTimecard(tms);

        Test.startTest();
        LogTimeCardController controller = new LogTimeCardController();
        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }

    private static List<TeamMember__c> createProjectAndTeamMember()
    {
        // Create Test data
        List<MProject__c> projects = new List<MProject__c>();

        for(Integer i=0; i < 10; i++)
        {
            MProject__c p = new MProject__c();
            p.Name = 'ProjectA' + i;
            projects.add(p);
        }

        insert projects;

        List<TeamMember__c> teamMembers = new List<TeamMember__c>();

        for(MProject__c p : projects)
        {
            TeamMember__c t = new TeamMember__c(Name= 'jair', User__c = UserInfo.getUserId(), Project__c = p.Id);
            teamMembers.add(t);
        }

        insert teamMembers;

        return teamMembers;
    }

    private static void createChangeAndTimecard(List<TeamMember__c> teamMembers)
    {
        List<TimeCard__c> timecards = new List<TimeCard__c>();
        List<Change__c> changes = new List<Change__c>();

        Map<Id, Id> memberIdToProjectId = new Map<Id, Id>();

        for(TeamMember__c tm : [select Id, Project__c from TeamMember__c where Id in :teamMembers])
        {
            memberIdToProjectId.put(tm.Id, tm.Project__c);
        }

        for(TeamMember__c t : teamMembers)
        {
            for(Integer i=0; i < 20; i++)
            {
                Change__c c = new Change__c();
                c.Project__c = memberIdToProjectId.get(t.Id);
                c.Name = 'Change' + i;
                changes.add(c);
            }

            for(Integer i=0; i < 15; i++)
            {
                TimeCard__c tm = new TimeCard__c();
                tm.Project__c = memberIdToProjectId.get(t.Id);
                tm.TeamMember__c = t.Id;
                tm.Hours__c = 8;
                tm.Date__c = Date.today().addDays(-i);
                timecards.add(tm);
            }
        }

        insert changes;
        insert timecards;
    }
}