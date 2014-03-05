/*
 * controller for WikiHome Page
 * display spaces, pages data; add new page; add new space.
 */
public with sharing class WikiHomeController
{
    private ApexPages.StandardSetController popularPagesSet;   

    public WikiSpace__c NewSpace { get; set; }
    public Boolean HasError { get; set; }
    public Boolean HasNext { get; set; }
    public List<WikiPageVersion__c> PopularPages { get; set; }

    
    public Id FavorSpaceId { get; set; }
    
    public WikiHomeController()
    {
        NewSpace = new WikiSpace__c();
        PopularPages = initPopularPages();
        HasError = false;
    }

    public List<WikiSpace__c> getMySpaces()
    {
        return [select Name, Summary__c,(select id from BookMarks__r where CreatedById = :UserInfo.getUserId()) from WikiSpace__c order by CreatedDate desc];

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
            HasNext = popularPagesSet.getHasNext();
        }
    }

    private List<WikiPageVersion__c> initPopularPages()
    {
        List<WikiPageVersion__c> pages= new List<WikiPageVersion__c>();
        popularPagesSet = new ApexPages.StandardSetController([SELECT Id, Title__c, WikiPage__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, WikiPage__r.LastPublishedDate__c   
                                                               FROM WikiPageVersion__c WHERE IsLatestVersion__c = true ORDER BY WikiPage__r.LastPublishedDate__c DESC]);

        popularPagesSet.setPageSize(4);
        HasNext = popularPagesSet.getHasNext();
        pages.addAll((List<WikiPageVersion__c>)popularPagesSet.getRecords());
        return pages;
    }
    
    public void favorSpace()
    {
        for(WikiSpace__c space : getMySpaces())
        {
            if(FavorSpaceId == space.Id)
            {
                if(space.BookMarks__r.size() == 0)
                {
                    insert new BookMark__c(Space__c = space.Id,WhatId__c = 'whatid',ParentSobjectType__c='ParentSobjectType_');
                }
                break;
            }
        }
    }
    public void unFavorSpace()
    {
        for(WikiSpace__c space : getMySpaces())
        {
            if(FavorSpaceId == space.Id)
            {
                if(space.BookMarks__r.size() > 0)
                {
                    delete space.BookMarks__r[0];
                }
                break;
            }
        }
    }
    public List<BookMark__c> getFavoriteSpaces()
    {
        return [select id,Space__c, space__r.Name,space__r.Summary__c from BookMark__c where CreatedBy.Id = :UserInfo.getUserId() order by CreatedDate desc];
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