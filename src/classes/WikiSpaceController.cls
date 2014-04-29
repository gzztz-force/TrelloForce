public class WikiSpaceController
{
	private String spaceId;
    private ApexPages.StandardSetController wikiPagesSet;

    public WikiSpaceController()
    {
        spaceId = ApexPages.CurrentPage().getParameters().get('Id');
        initSpaces();
        initWikiPages();
    }

    public String SpaceName
    {
        get
        {
           return [select Id, Name from WikiSpace__c where Id = :spaceId][0].Name;
        }
    }

    public List<WikiSpace__c> Spaces { get; set ; }
    public List<WikiPage> WikiPages { get; set; }
    public Boolean HasMorePages { get; set; }

    private void initSpaces()
    {
        Spaces = [select Id, Name from WikiSpace__c];
    }

    private void initWikiPages()
    {
        wikiPagesSet = new ApexPages.StandardSetController(
                                [select Id, Name, WikiSpace__c, TotalPageVersion__c, LastPublishedDate__c,
                                    (select Id, Name, Body__c, Title__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, LastPublishedDate__c, VersionNumber__c, WikiPage__c
                                        from WikiPageVersions__r where IsLatestVersion__c = true) from WikiPage__c where WikiSpace__c = :spaceId]);
        wikiPagesSet.setPageSize(2);
        List<WikiPage__c> pages = (List<WikiPage__c>)wikiPagesSet.getRecords();
        WikiPages = new List<WikiPage>();
        for(WikiPage__c page : pages)
        {
            WikiPages.add(new WikiPage(page.WikiPageVersions__r[0]));
        }
        HasMorePages = wikiPagesSet.getHasNext();
    }

    public void loadMorePages()
    {
        if(HasMorePages)
        {
            wikiPagesSet.next();
            HasMorePages = wikiPagesSet.getHasNext();
            List<WikiPage__c> pages = (List<WikiPage__c>)wikiPagesSet.getRecords();
            for(WikiPage__c page : pages)
            {
               WikiPages.add(new WikiPage(page.WikiPageVersions__r[0]));
            }
        }
    }

    public class WikiPage
    {
        public WikiPage(WikiPageVersion__c version)
        {
            this.WikiPageVersion = version;
        }

        public WikiPageVersion__c WikiPageVersion { get; set; }
    }
}