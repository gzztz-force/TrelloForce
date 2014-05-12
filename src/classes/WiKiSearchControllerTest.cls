@isTest
public with sharing class WiKiSearchControllerTest
{
    @isTest
    public static void testWiKiSearchController()
    {
        List<WiKiPage__c> wikiPages = new List<WiKiPage__c>();
        for(Integer i = 0; i < 125; i++)
        {
            WiKiPage__c wikiPage = new WiKiPage__c(Title__c = 'Title' + i);
            wikiPages.add(wikiPage);
        }
        WiKiPage__c page1 = new WiKiPage__c(Title__c = 'Apex');
        WiKiPage__c page2 = new WiKiPage__c(Title__c = 'Java');
        for(Integer i = 0; i < 120; i++)
        {
            WiKiPage__c wikiPage = new WiKiPage__c(Title__c = 'Stefan xu' + i);
            wikiPages.add(wikiPage);
        }
        wikiPages.add(page1);
        wikiPages.add(page2);
        insert wikiPages;

        List<WiKiPageVersion__c> versions = new List<WiKiPageVersion__c>();
        for(WiKiPage__c page : wikiPages)
        {
            WiKiPageVersion__c v = new WiKiPageVersion__c(WiKiPage__c = page.Id, Title__c = page.Title__c, IsLatestVersion__c = true, Body__c = 'Test the first one,Just something whatever you like');   
            versions.add(v);
        }
        insert versions;
        
        List<Id> versionIds = new List<Id>();
        for(WiKiPageVersion__c v : versions)
        {
            versionIds.add(v.Id);
        }
        
        Test.setFixedSearchResults(versionIds);

        WiKiSearchController controller = new WiKiSearchController();
        ApexPages.currentPage().getParameters().put('Key', 'nothing');
        controller = new WiKiSearchController();
        controller.Key = 'Title';
        controller.search();
        controller.next();
        controller.next();
        controller.previous();
        controller.PageNumber = 4;
        controller.paging();
        controller.PageNumber = 6;
        controller.resetLinks();
        controller.PageNumber = 22;
        controller.resetLinks();
        controller.PageNumber = 23;
        controller.resetLinks();
        controller.PageNumber = 24;
        controller.resetLinks();
        controller.PageNumber = 25;

        controller.Key = 'first one';
        controller.search();

        controller.Key = '*?*?';
        controller.search();
    }
}