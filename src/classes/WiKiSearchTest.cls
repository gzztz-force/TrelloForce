@isTest
public with sharing class WiKiSearchTest
{
    
    @isTest
    public static void testSearch()
    {

        List<WiKiPage__c> wikiPages = new List<WiKiPage__c>();
        /*for(Integer i = 0; i < 25; i++)
        {
            WiKiPage__c wikiPage = new WiKiPage__c(Title__c = 'Title' + i);
            wikiPages.add(wikiPage);
        }*/
        WiKiPage__c page1 = new WiKiPage__c(Title__c = 'Apex');
        WiKiPage__c page2 = new WiKiPage__c(Title__c = 'Java');
        wikiPages.add(page1);
        wikiPages.add(page2);
        insert page1;

        List<WiKiPageVersion__c> versions = new List<WiKiPageVersion__c>();
        for(WiKiPage__c page : wikiPages)
        {
            WiKiPageVersion__c version = new WiKiPageVersion__c(WiKiPage__c = page.Id, Title__c = page.Title__c, IsLatestVersion__c = true, Body__c = 'Just something whatever you like');
            versions.add(version);
        }
        insert versions;

        ApexPages.currentPage().getParameters().put('Key', 'nothing');
        WiKiSearchController controller = new WiKiSearchController();
        controller.Key = 'Title';
        controller.search();
        controller.next();
        controller.next();
        controller.previous();
    }
}