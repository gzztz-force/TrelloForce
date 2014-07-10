/*
 * Controller for WikiSpace page to get spaces and related pages.
 */
public class WikiSpaceController
{
    public WikiSpaceController()
    {
        initSpaces();

        SpaceId = ApexPages.CurrentPage().getParameters().get('Id');
        if(String.isBlank(SpaceId) && Spaces.size() > 0)
        {
            SpaceId = Spaces[0].Id;
        }

        initWikiPages();
    }

    public String SpaceName
    {
        get
        {
           return [select Id, Name from WikiSpace__c where Id = :SpaceId][0].Name;
        }
    }
    public String SpaceId { get; private set; }
    public List<WikiSpace__c> Spaces { get; set ; }
    public List<WikiPage> WikiPages { get; set; }

    private void initSpaces()
    {
        Spaces = [select Id, Name from WikiSpace__c];
    }

    private void initWikiPages()
    {
        List<WikiPage__c> pages = [select Id, Name, (select Id, Name, Body__c, Title__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl,
                LastPublishedDate__c, WikiPage__c from WikiPageVersions__r where IsLatestVersion__c = true) from WikiPage__c where WikiSpace__c = :SpaceId];

        WikiPages = new List<WikiPage>();
        for(WikiPage__c page : pages)
        {
            WikiPages.add(new WikiPage(page.WikiPageVersions__r[0]));
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
