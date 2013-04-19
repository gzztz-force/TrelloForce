/*
 * This controller is Referenced by WikiNewPage and used to create/edit WikiPages.
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
        pageId = ApexPages.currentPage().getParameters().get('id');
        List<WikiPage__c> pages = [select Id, LastPublishedDate__c, (select Id, WikiPage__c, Title__c, Body__c, Label__c, WikiPage__r.WikiSpace__r.Name
                                    from WikiPageVersions__r where WikiPage__c = :pageId and IsLatestVersion__c = true)
                                    from WikiPage__c where Id = :pageId];
        isNew = (pages.size() <= 0) ? true : false;
        if (isNew)
        {
            parentPage = new WikiPage__c();
            LatestPage = new WikiPageVersion__c();
            LatestPage.Title__c = 'Type your title';
        }
        else
        {

            List<WikiPageVersion__c> pageVersions = pages[0].WikiPageVersions__r;
            if (pageVersions.size() > 0)
            {
                parentPage = pages[0];
                LatestPage = pageVersions[0];
                versionPageClone = LatestPage.clone(true);
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Invalid Id', 'Invalid Id'));
                IsValid = false;
            }
        }
    }

    public Boolean IsValid { get; set; }
    public WikiPageVersion__c LatestPage { get; set; }

    public List<SelectOption> SpaceOptions
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--None--'));
            for(WikiSpace__c s : [select Id, Name__c from WikiSpace__c])
            {
                options.add(new SelectOption(s.Id, s.Name__c));
            }
            return options;
        }
    }

    public PageReference save()
    {
        Savepoint sp = Database.setSavepoint();
        try
        {
            parentPage.WikiSpace__c = LatestPage.WikiPage__r.WikiSpace__c;
            parentPage.LastPublishedDate__c = System.now();
            if (isNew)
            {
                insert parentPage;
            }
            else
            {
                update parentPage;
                versionPageClone.IsLatestVersion__c = false;
                update versionPageClone;
            }
            WikiPageVersion__c newVersionPage = new WikiPageVersion__c(Title__c = LatestPage.Title__c, Body__c = LatestPage.Body__c, Label__c = LatestPage.Label__c, WikiPage__c = parentPage.Id, IsLatestVersion__c = true, LastPublishedDate__c = System.Now());
            insert newVersionPage;
        }
        catch(Exception ex)
        {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
        return new PageReference('/apex/WikiHome');
    }

    public PageReference cancel()
    {
        return new PageReference('/apex/WikiHome');
    }

    @isTest
    static void testNewPage()
    {
        ApexPages.currentPage().getParameters().put('type', 'new');
        WikiNewPageController controller = new WikiNewPageController();
        controller.LatestPage.Title__c = 'test';
        controller.LatestPage.Body__c = 'test';
        controller.save();

        WikiPage__c newPage = new WikiPage__c();
        insert newPage;
        WikiPageVersion__c newPageVersion = new WikiPageVersion__c(WikiPage__c=newPage.Id, Title__c='title', Body__c='body');
        insert newPageVersion;
        ApexPages.currentPage().getParameters().put('id', newPage.Id);
        ApexPages.currentPage().getParameters().put('type', 'edit');
        WikiNewPageController controller2 = new WikiNewPageController();
        controller2.LatestPage.Title__c = 'title1';
        controller2.LatestPage.Body__c = 'body1';
        controller2.save();
        for (WikiPageVersion__c version : [select Title__c, WikiPage__c from WikiPageVersion__c where WikiPage__c= :newPage.Id] )
        {
            if (version.IsLatestVersion__c)
            {
                system.assertEquals('title1', version.Title__c);
            }
            else
            {
                system.assertEquals('title', version.Title__c);
            }
        }
    }
}
