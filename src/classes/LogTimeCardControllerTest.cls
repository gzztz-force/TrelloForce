/**
 * Test method for LogTimeCardController
 */
@isTest
public class LogTimeCardControllerTest
{
    @isTest static void testNewUserNoUsedProject()
    {
        TestDataFactory.numberOfProjects = 20;
        TestDataFactory.createTeamMembers();

        Test.startTest();
        LogTimeCardController controller = new LogTimeCardController();
        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }

    @isTest static void testOldUserHasUsedProject()
    {
        TestDataFactory.numberOfProjects = 20;
        TestDataFactory.createTimecards();

        Test.startTest();
        LogTimeCardController controller = new LogTimeCardController();
        Test.stopTest();

        System.assertEquals(10, controller.RecentProjects.size());
    }
}