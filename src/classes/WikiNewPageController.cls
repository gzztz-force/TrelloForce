/*
 * This controller is Referenced by WikiNewPage and used to create/edit WikiPage.
 */
public class WikiNewPageController
{
    private String pageId;
    private Boolean isNew;
    private WikiPage__c parentPage;
    private WikiPageVersion__c versionPageClone;

    public WikiNewPageController()
    {
        IsValid = true;
        HasError = false;
        CurrentUserInfo = [select Id, Name, SmallPhotoUrl from User where Id = :UserInfo.getUserId()];
        pageId = ApexPages.currentPage().getParameters().get('id');
        WikiSpaceId = ApexPages.currentPage().getParameters().get('spaceid');
        List<WikiPage__c> pages = [select Id, LastPublishedDate__c, (select Id, VersionNumber__c, WikiPage__c, Title__c, Body__c, WikiPage__r.WikiSpace__r.Name, WikiPage__r.WikiSpace__r.Id
                                    from WikiPageVersions__r where WikiPage__c = :pageId and IsLatestVersion__c = true)
                                    from WikiPage__c where Id = :pageId];
        isNew = (pages.isEmpty()) ? true : false;
        if(isNew)
        {
            parentPage = new WikiPage__c();
            LatestPage = new WikiPageVersion__c();
            LatestPage.VersionNumber__c = 0;
        }
        else
        {
            List<WikiPageVersion__c> pageVersions = pages[0].WikiPageVersions__r;
            if (pageVersions.size() > 0)
            {
                parentPage = pages[0];
                LatestPage = pageVersions[0];
                WikiSpaceId = pageVersions[0].WikiPage__r.WikiSpace__r.Id;
                versionPageClone = LatestPage.clone(true);
            }
        }

    }

    public Id WikiSpaceId { get; set; }
    public Boolean IsValid { get; set; }
    public WikiPageVersion__c LatestPage { get; set; }
    public User CurrentUserInfo { get; set; }
    public Boolean HasError { get; set; }

    public List<SelectOption> SpaceOptions
    {
       get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--None--'));
            List<WikiSpace__c> spaces;
            if(SpaceOptions == null )
            {
                spaces = [select Id, Name from WikiSpace__c];
                if(spaces.isEmpty())
                {
                    WikiSpace__c space =  new WikiSpace__c(Name = 'Other');
                    insert space;
                    options.add(new SelectOption(space.Id, space.Name));
                }
                else
                {
                    for(WikiSpace__c item : spaces)
                    {
                        options.add(new SelectOption(item.Id, item.Name));
                    }
                }
            }
            return options;
        }
    }

    public PageReference save()
    {
        Savepoint savePoint = Database.setSavepoint();
        try
        {
            if(String.isBlank(WikiSpaceId))
            {
                WikiSpaceId = SpaceOptions[1].getValue();
            }
            parentPage.WikiSpace__c = WikiSpaceId;
            parentPage.LastPublishedDate__c = System.now();
            parentPage.Title__c = LatestPage.Title__c;
            parentPage.Name = LatestPage.Title__c.abbreviate(80);
            if(isNew)
            {
                insert parentPage;
            }
            else
            {
                update parentPage;
                versionPageClone.IsLatestVersion__c = false;
                update versionPageClone;
            }

            WikiPageVersion__c newVersionPage = new WikiPageVersion__c(Title__c = LatestPage.Title__c, Body__c = LatestPage.Body__c, WikiPage__c = parentPage.Id, IsLatestVersion__c = true, VersionNumber__c = LatestPage.VersionNumber__c + 1, LastPublishedDate__c = System.Now());
            insert newVersionPage;
        }
        catch(Exception ex)
        {
            HasError = true;
            Database.rollback(savePoint);
            ApexPages.addMessages(ex);
            return null;
        }
        return new PageReference('/apex/WikiViewPage?id=' + parentPage.Id);
    }

    public PageReference cancel()
    {
        if(!isNew)
        {
            return new PageReference('/apex/WikiViewPage?id=' + parentPage.Id);
        }
        return new PageReference('/apex/WikiHome');
    }
}