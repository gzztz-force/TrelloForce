/*
 * controller for WikiHome Page
 * display spaces, pages data; add new page; add new space.
 */
public with sharing class WikiHomeController
{
    private ApexPages.StandardSetController popularPagesSet;

    public WikiHomeController()
    {
    	NewSpace = new WikiSpace__c();
        PopularPages = initPopularPages();
    	NewSpaceIsSuccess = false;
    }

    public WikiSpace__c NewSpace { get; set; }
    public Boolean NewSpaceIsSuccess { get; set; }
    public List<WikiPageVersion__c> PopularPages { get; set; }

    public List<WikiSpace__c> getMySpaces()
    {
        return [SELECT Name__c, Summary__c FROM WikiSpace__c];
    }

    public List<WikiPageVersion__c> getMyPages()
    {
        return [SELECT Title__c, WikiPage__c FROM WikiPageVersion__c WHERE IsLatestVersion__c = true AND CreatedById = :UserInfo.getUserId()];
    }

    public void createNewSpace()
    {
    	try
    	{
    	    insert NewSpace;
    	    NewSpaceIsSuccess = true;
    	}
    	catch(Exception ex)
    	{
    		ApexPages.addMessages(ex);
    	}
    }

    public void loadMorePopularPages()
    {
        if(popularPagesSet.getHasNext())
        {
            popularPagesSet.next();
            system.assertEquals(null, (List<WikiPageVersion__c>)popularPagesSet.getRecords());
            PopularPages.addAll((List<WikiPageVersion__c>)popularPagesSet.getRecords());
        }
    }

    private List<WikiPageVersion__c> initPopularPages()
    {
        List<WikiPageVersion__c> pages= new List<WikiPageVersion__c>();
        popularPagesSet = new ApexPages.StandardSetController([SELECT Id, Title__c, CreatedBy.Name, LastPublishedDate__c FROM WikiPageVersion__c WHERE IsLatestVersion__c = true]);
        popularPagesSet.setPageSize(4);
        pages.addAll((List<WikiPageVersion__c>)popularPagesSet.getRecords());
        return pages;
    }

    @isTest
    static void testWikiHome()
    {
    	WikiHomeController controller = new WikiHomeController();
    	controller.NewSpace.Name__c = 'test';
    	controller.NewSpace.Summary__c = 'test';
    	controller.createNewSpace();
    	system.assertEquals('test', [select Name__c from WikiSpace__c WHERE id = :controller.NewSpace.Id][0].Name__c);
    }
}