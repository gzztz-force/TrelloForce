public class WikiNewPageController
{
    private String pageId, operationType;
    private WikiPage__c parentPage;
    private WikiPageVersion__c versionPageClone;

    public WikiNewPageController()
    {
        IsValid = true;
        pageId = ApexPages.currentPage().getParameters().get('id');
        operationType = ApexPages.currentPage().getParameters().get('type');

        if (operationType == 'new')
        {
            parentPage = new WikiPage__c();
            LatestPage = new WikiPageVersion__c();
            LatestPage.Title__c = 'Type your title';
        }
        else if (operationType == 'edit')
        {
            List<WikiPage__c> pages = [select Id from WikiPage__c where Id =: pageId];
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
        else
        {
                ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.Error, 'Illigal Operation', 'Illigal Operation');
                ApexPages.addMessage(message);
                IsValid = false;
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
            if (operationType == 'new')
            {
                insert parentPage;

            }
            else if(operationType == 'edit')
            {
                update parentPage;
                versionPageClone.IsLatestVersion__c = false;
                update versionPageClone;
            }
            else
            {
                ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.Error, 'Illigal Operation', 'Illigal Operation');
                ApexPages.addMessage(message);
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
        WikiPage__c newPage = new WikiPage__c();
        insert newPage;
        ApexPages.currentPage().getParameters().put('id', newPage.Id);
        WikiNewPageController controller = new WikiNewPageController();
        system.assertEquals('expect value', 'real value');
    }
}
