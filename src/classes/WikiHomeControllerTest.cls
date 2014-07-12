/*
 *Test class for WikiHomeController 
 */
@isTest
public class WikiHomeControllerTest
{
	@isTest
	public static void testContructorAndSimpleMethods()
	{
		WikiDataFactory dataFactory = new WikiDataFactory();

		PageReference pageRef = new ApexPages.PageReference('/apex/WikiHomeTest');
		Test.setCurrentPage(pageRef);
		dataFactory.createWikiPagesWithSpaces(5, 6,true);

		WikiHomeController controller = new WikiHomeController();
		List<WikiSpace__c> spaces = controller.getMySpaces();
		System.assertEquals(spaces.size(), 5);
		System.assertEquals(spaces[0].WikiPages__r.size(), 6);
		controller.getMyPages();
		controller.loadMorePopularPagesAction();
		List<WikiPage__c> pages = [select LastPublishedDate__c from WikiPage__c limit 3];
		List<WikiPage__c> modifiedFiledPages = new List<WikiPage__c>();
		Date testDate = date.newinstance(2014,12,12);
		for(WikiPage__c wikipage : pages)
		{
			wikipage.LastPublishedDate__c = testDate;
			modifiedFiledPages.add(wikipage);
		}
		update modifiedFiledPages;
		controller.getWikiPageFieldLabelMap();
		System.assertEquals(controller.getPopularPages().size(), 24);
	}

	@isTest
	public static void testCreateNewSpace()
	{	
		WikiHomeController controller = new WikiHomeController();		

		controller.NewSpace.Summary__c = 'test';
		controller.createNewSpace();
		controller.NewSpace.Name = 'test';
		controller.createNewSpace();

		List<WikiSpace__c> spaces = [select Id from WikiSpace__c];
		System.assertEquals(spaces.size(), 1);		
	}
}