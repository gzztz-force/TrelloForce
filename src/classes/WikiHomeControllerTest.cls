/*
 *Test class for WikiHomeController 
 */
@isTest
public class WikiHomeControllerTest
{
	@isTest
	public static void testContructorAndSimpleMethods()
	{
		// Load the data for the test
		WikiDataFactory dataFactory = new WikiDataFactory();
		dataFactory.createWikiPagesWithSpaces(5, 6,true);

		PageReference pageRef = new ApexPages.PageReference('/apex/WikiHome');
		Test.setCurrentPage(pageRef);
		WikiHomeController controller = new WikiHomeController();
		List<WikiSpace__c> spaceOptions = controller.MySpaces;
		List<WikiPageVersion__c> pagesOptions = controller.MyPages; 
		controller.loadMorePopularPages();
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