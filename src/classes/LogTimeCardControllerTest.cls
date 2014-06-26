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
        String userName = controller.CurrentUserName;

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

    @isTest(SeeAllData=true)
    static void testRemoteAction()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        List<TeamMember__c> members = TestDataFactory.createTeamMembers(projects);
        String fields = '{"Project__c": "' + projects[0].Id +
                        '", "TeamMember__c": "' + members[0].Id +
                        '", "Change__c": "' + changes[0].Id +
                        '", "Hours__c": "8", "Date__c": "' + Date.today() +
                        '", "Description__c": "acme", "Billable__c": ' + true + '}';

        Test.startTest();
        LogTimeCardController.create('TimeCard__c', fields);
        Test.stopTest();
    }

    @isTest(SeeAllData=true)
    static void testException()
    {
        String fields = '{"Project__c": "", "TeamMember__c": "", "Change__c": ""' +
                        ',"Hours__c": "8", "Date__c": "' + Date.today() +
                        '", "Description__c": "acme", "Billable__c": ' + true + '}';
        Test.startTest();
        LogTimeCardController.create('TimeCard__c', fields);
        Test.stopTest();
    }

    @isTest static void testError()
    {
        String fields = '{"Project": "", "TeamMember__c": "", "Change__c": ""' +
                        ',"Hours__c": "8", "Date__c": "' + Date.today() +
                        '", "Description__c": "acme", "Billable__c": ' + true + '}';
        Test.startTest();
        LogTimeCardController.create(null, fields);
        LogTimeCardController.create('TimeCard__c', fields);
        Test.stopTest();
    }

}