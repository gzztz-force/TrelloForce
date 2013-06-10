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
        HasError = false;
    }

    public WikiSpace__c NewSpace { get; set; }
    public Boolean HasError { get; set; }
    public List<WikiPageVersion__c> PopularPages { get; set; }

    public List<WikiSpace__c> getMySpaces()
    {
        return [select Name, Summary__c from WikiSpace__c order by CreatedDate desc];
    }

    public List<WikiPageVersion__c> getMyPages()
    {
        return [select Title__c, WikiPage__c from WikiPageVersion__c WHERE IsLatestVersion__c = true AND CreatedById = :UserInfo.getUserId()];
    }

    public void createNewSpace()
    {
        HasError = false;

        try
        {
            insert NewSpace;
            NewSpace = new WikiSpace__c();
        }
        catch(Exception ex)
        {
            HasError = true;
            ApexPages.addMessages(ex);
        }
    }

    public void loadMorePopularPages()
    {
        if(popularPagesSet.getHasNext())
        {
            popularPagesSet.next();
            PopularPages.addAll((List<WikiPageVersion__c>)popularPagesSet.getRecords());
        }
    }

    private List<WikiPageVersion__c> initPopularPages()
    {
        List<WikiPageVersion__c> pages= new List<WikiPageVersion__c>();
        popularPagesSet = new ApexPages.StandardSetController([SELECT Id, Title__c, WikiPage__c, CreatedById, CreatedBy.Name, WikiPage__r.LastPublishedDate__c                                                                FROM WikiPageVersion__c WHERE IsLatestVersion__c = true ORDER BY WikiPage__r.LastPublishedDate__c DESC]);
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