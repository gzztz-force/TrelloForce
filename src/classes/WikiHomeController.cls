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