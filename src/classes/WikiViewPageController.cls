/**
 * A controller for WikiViewPage
 */
public with sharing class WikiViewPageController
{
    private String pageId;
    
    public WikiViewPageController()
    {
        pageId = ApexPages.currentPage().getParameters().get('id');
        if(string.isNotBlank(pageId))
        {
            getPubishedPage();
        }
    }

    public PublishedPage PubPage { get; set; }
    
    private void getPubishedPage()
    {
        List<WikiPage__c> publishedPages = [select Id, WikiSpace__r.Name, WikiSpace__c, CreatedById, LastModifiedById, LastPublishedDate__c,
                                             (select Id, Body__c, Title__c, CreatedById, LastModifiedDate from WikiPageVersions__r
                                              where IsLatestVersion__c = true)
                                              from WikiPage__c where Id = :pageId];
        if(publishedPages.size() > 0)
        {
            PubPage = new PublishedPage(publishedPages[0]);
        }
    }

    public class PublishedPage
    {
        public PublishedPage(WikiPage__c wikiPage)
        {
            this.WikiPage = wikiPage;
            this.WikiPageVersion = wikiPage.WikiPageVersions__r[0];
        }

        public WikiPage__c WikiPage { get; set; }
        public WikiPageVersion__c WikiPageVersion { get; set; }
    }
}