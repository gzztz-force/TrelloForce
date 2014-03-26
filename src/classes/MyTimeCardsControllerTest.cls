/**
 * Test method for MyTimeCardsController
 */
@isTest
private class MyTimeCardsControllerTest
{
    @isTest static void testMyTimeCardsController()
    {
        TestDataFactory.numberOfTimecards = 15;
        TestDataFactory.createTimecards();

        PageReference myTimeCardPage = Page.MyTimeCards;
        Test.setCurrentPage(myTimeCardPage);
        MyTimeCardsController controller = new MyTimeCardsController();
        System.assertEquals(10, controller.TimeCards.size());
    }
}