@isTest
public class WikiNewPageControllerTest
{
    @isTest
    public static void testNewPage()
    {
        WikiNewPageController controller = new WikiNewPageController();
        controller.cancel();
        controller.LatestPage.Body__c = 'test';
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

        WikiNewPageController controller = new WikiNewPageController();
        controller.WikiSpaceId = [select Id from Wikispace__c limit 1][0].Id;
        controller.LatestPage.Body__c = 'test';
        controller.save();
        System.assertEquals([select id from WikiPageVersion__c].size(),16);
        controller.LatestPage = null;
        controller.save();
    }
}