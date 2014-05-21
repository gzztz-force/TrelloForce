/**
 * Test method for MyTimeCardsController
 */
@isTest
private class MyTimeCardsControllerTest
{
    @isTest static void testMyTimeCardsController()
    {
        TestDataFactory.numberOfTimecards = 15;
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<TeamMember__c> teamMembers = TestDataFactory.createTeamMembers(projects);
        TestDataFactory.createTimecards(teamMembers);

        PageReference myTimeCardPage = Page.MyTimeCards;
        Test.setCurrentPage(myTimeCardPage);
        MyTimeCardsController controller = new MyTimeCardsController();
        System.assertEquals(10, controller.TimeCards.size());
    }
}