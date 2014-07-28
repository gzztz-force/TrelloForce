/*
 * To create data for WikiNewPageControllerTest, WikiHomeControllerTest and WikiViewPageControllerTest class
 */
@isTest
public class WikiDataFactory
{
    public List<WikiSpace__c> createWikiSpaces(Integer spaceCount)
    {
        List<WikiSpace__c> spaces = new List<WikiSpace__c>();
        for(Integer i = 0; i < spaceCount; i++)
        {
            WikiSpace__c space = new WikiSpace__c(Name = 'test', Summary__c = 'this is a test record.');
            spaces.add(space);
        }
        insert spaces;
        return spaces;
    }

    public List<WikiPage__c> createWikiPagesWithSpaces(Integer spacesCount, Integer pageCount, Boolean withPageVersion)
    {
        List<WikiSpace__c> spaces = createWikiSpaces(spacesCount);
        List<WikiPage__c> pages = new List<WikiPage__c>();
        List<FeedItem> feedItems = new List<FeedItem>();
        for(WikiSpace__c space :spaces)
        {
            for(Integer i = 0; i < pageCount; i++)
            {
                WikiPage__c page = new WikiPage__c(Title__c = 'title'+i, WikiSpace__c = space.Id);
                pages.add(page);
            }
        }
        insert pages;
        Boolean flage = false;
        for(WikiPage__c page : pages) 
        {
            if(flage)
            {
                FeedItem feedItem1 = new FeedItem(ParentId = page.Id, Body = 'testBody');
                FeedItem feedItem2 = new FeedItem(ParentId = page.Id, Body = 'testBody');
                feedItems.add(feedItem1);
                feedItems.add(feedItem2);
                flage = false;
            }
            else
            {
                FeedItem feedItem = new FeedItem(ParentId = page.Id, Body = 'testBody2');
                feedItems.add(feedItem);
                flage = true;
            }
        }
        insert feedItems;
        if(withPageVersion)
        {
            createWikiPageVersions(pages);
        }
        return pages;
    }
    public void createWikiPageVersions(List<WikiPage__c> pages)
    {
        List<WikiPageVersion__c> pageVersions = new List<WikiPageVersion__c>();
        for(WikiPage__c page : pages)
        {
            WikiPageVersion__c pageVersion = new WikiPageVersion__c(Title__c = 'title', Body__c = 'body', WikiPage__c = page.Id, IsLatestVersion__c = true,VersionNumber__c = 1, LastPublishedDate__c = System.Now());
            pageVersions.add(pageVersion);
        }
        insert pageVersions;
    }
}