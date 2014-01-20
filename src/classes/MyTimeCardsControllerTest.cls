/**
 * Test method for MyTimeCardsController
 */
@isTest(seeAllData=true)
private class MyTimeCardsControllerTest
{
    @isTest static void testMyTimeCardsController()
    {
        PageReference myTimeCardPage = Page.MyTimeCards;
        Test.setCurrentPage(myTimeCardPage);
        MyTimeCardsController controller = new MyTimeCardsController();
        system.assertEquals(10, controller.TimeCards.size());
    }
}