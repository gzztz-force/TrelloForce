@isTest
public class WikiNewPageControllerTest
{
    @isTest
    public static void testNewPage()
    {
        WikiNewPageController controller = new WikiNewPageController();
        controller.cancel();
        controller.LatestPage.Body__c = 'test';
        controller.LatestPage.Title__c = 'SummerTest';
        controller.save();
        System.assertEquals([select id from WikiPage__c].size(),1);
        controller.LatestPage = null;
        controller.save();
    }

    @isTest
    public static void testEditPage()
    {
        WikiDataFactory dataFactory = new WikiDataFactory();
        dataFactory.createWikiPagesWithSpaces(3,5,true);

        PageReference pageRef = new ApexPages.PageReference('/apex/WikiNewPageTest');
        Id pageId = [select id from WikiPage__c limit 1].Id;
        pageRef.getParameters().put('id',pageId);
        Test.setCurrentPage(pageRef);
        //Test pages with pageVersion
        WikiNewPageController controller = new WikiNewPageController();
        controller.WikiSpaceId = [select Id from Wikispace__c limit 1][0].Id;
        controller.LatestPage.Body__c = 'test';
        controller.LatestPage.Title__c = 'SummerTest';
        controller.save();

        //Test with Space exits.
        List<SelectOption> spaceOptions = controller.SpaceOptions;
        controller.getUserInfo();
        System.assertEquals(spaceOptions.size(), 4);
        System.assertEquals([select id from WikiPageVersion__c].size(),16);

        //Test pages without page Version and the WikiSpaceId is null
        delete [select Id from WikiPageVersion__c];
        PageReference pageRef2 = new ApexPages.PageReference('/apex/WikiNewPageTest');
        pageRef2.getParameters().put('spaceid', null);
        Test.setCurrentPage(pageRef2);
        WikiNewPageController controller2 = new WikiNewPageController();

        //Test with no Space.
        delete [select Id from WikiSpace__c];
        List<SelectOption> spaceOptions2 = controller.SpaceOptions;
        controller.cancel();


        controller.LatestPage = null;
        controller.save();
    }
}