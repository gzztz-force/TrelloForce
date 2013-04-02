public class WikiNewPageController
{
    private String pageId;
    private Boolean isNew;
    private WikiPage__c parentPage;
    private WikiPageVersion__c versionPageClone;

    public WikiNewPageController()
    {
        IsValid = true;
        List<WikiPage__c> pages = [select Id from WikiPage__c where Id = :ApexPages.currentPage().getParameters().get('id')];
        isNew = (pages.size() <= 0 ? true : false);
        if (isNew)
        {
            parentPage = new WikiPage__c();
            LatestPage = new WikiPageVersion__c();
            LatestPage.Title__c = 'Type your title';
        }
        else
        {

            List<WikiPageVersion__c> pageVersions = [select Id, WikiPage__c, Title__c, Body__c, Label__c, WikiPage__r.WikiSpace__r.Name from WikiPageVersion__c where WikiPage__c = : pageId and IsLatestVersion__c = true];
            if (pageVersions.size() > 0 && pages.size() > 0)
            {
                parentPage = pages[0];
                LatestPage = pageVersions[0];
                versionPageClone = LatestPage.clone();
            }
            else
            {
                ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid Id', 'Invalid Id');
                ApexPages.addMessage(message);
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
            options.add(new SelectOption('', 'Space'));
            for(WikiSpace__c s : [select Id, Name from WikiSpace__c])
            {
                options.add(new SelectOption(s.Id, s.Name));
            }
            return options;
        }
    }

    public PageReference save()
    {
        try
        {
            parentPage.WikiSpace__c = LatestPage.WikiPage__r.WikiSpace__c;
            parentPage.LastPublishedDate__c = Date.today();
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
            WikiPageVersion__c newVersionPage = new WikiPageVersion__c(Title__c = LatestPage.Title__c, Body__c = LatestPage.Body__c, Label__c = LatestPage.Label__c, WikiPage__c = parentPage.Id, IsLatestVersion__c = true);
            insert newVersionPage;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference cancel()
    {
        return null;
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
