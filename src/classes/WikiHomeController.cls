/**
 *
 */
public with sharing class WikiHomeController
{
    public WikiHomeController()
    {
    	NewSpace = new WikiSpace__c();
    	NewSpaceSuccess = false;
        getPopularPages();
    }

    public WikiSpace__c NewSpace { get; set; }
    public Boolean NewSpaceSuccess { get; set; }

    public List<WikiSpace__c> getMySpaces()
    {
        return [SELECT Name__c, Summary__c FROM WikiSpace__c];
    }

    public List<WikiPageVersion__c> getMyPages()
    {
        return [SELECT Title__c FROM WikiPageVersion__c WHERE IsLatestVersion__c = true AND CreatedById = :UserInfo.getUserId()];
    }

    public String getPopularPages()
    {
        return '';
    }

    public void createNewSpace()
    {
    	try
    	{
    	    insert NewSpace;
    	    NewSpaceSuccess = true;
    	}
    	catch(Exception ex)
    	{
    		ApexPages.addMessages(ex);
    	}
    }

    @isTest
    static void testWikiHome()
    {
    	WikiHomeController controller = new WikiHomeController();
    	controller.NewSpace.Name__c = 'test';
    	controller.NewSpace.Summary__c = 'test';
    	controller.createNewSpace();
    	system.assertEquals('test', [select Name__c from WikiSpace__c WHERE id = :controller.NewSpace.Id][0].Name__c);
    }
}