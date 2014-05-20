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
		System.assertEquals(controller.getMyPopularPages().size(), 20);
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