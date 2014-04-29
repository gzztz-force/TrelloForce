/*
 * To create data for WikiNewPageControllerTest and WikiHomeControllerTest class
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
        for(WikiSpace__c space :spaces)
        {
            for(Integer i = 0; i < pageCount; i++)
            {
                WikiPage__c page = new WikiPage__c(Title__c = 'title', WikiSpace__c = space.Id);
                pages.add(page);
            }
        }
        insert pages;
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