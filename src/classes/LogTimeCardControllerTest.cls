/**
 * Test method for LogTimeCardController
 */
@isTest
public class LogTimeCardControllerTest
{
    @isTest static void testNewUserNoUsedProject()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        TestDataFactory.createTeamMembers(projects);

        Test.startTest();
        LogTimeCardController controller = new LogTimeCardController();
        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }

    @isTest static void testOldUserHasUsedProject()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        List<TeamMember__c> members = TestDataFactory.createTeamMembers(projects);
        TestDataFactory.createTimecards(members);

        PageReference logTimeCardPage = Page.LogTimeCard;
        logTimeCardPage.getParameters().put('id', projects[0].Id);
        Test.setCurrentPage(logTimeCardPage);

        Test.startTest();

        LogTimeCardController controller = new LogTimeCardController();
        String todayHours = controller.TodayHours;
        String yesterdayHours = controller.YesterdayHours;

        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }

    @isTest static void testOldUserHasUsedChange()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        List<TeamMember__c> members = TestDataFactory.createTeamMembers(projects);
        TestDataFactory.createTimecards(members);

        PageReference logTimeCardPage = Page.LogTimeCard;
        logTimeCardPage.getParameters().put('id', changes[0].Id);
        Test.setCurrentPage(logTimeCardPage);

        Test.startTest();

        LogTimeCardController controller = new LogTimeCardController();
        String todayHours = controller.TodayHours;
        String yesterdayHours = controller.YesterdayHours;

        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }
}