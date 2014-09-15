/*
 * Test class for WikiViewController.
 */
@isTest
public class WikiViewPageControllerTest
{
	@isTest
	public static void testMethodOne()
	{
		WikiDataFactory dataFactory = new WikiDataFactory();
		dataFactory.createWikiPagesWithSpaces(5, 6,true);
		PageReference pageRef = new ApexPages.PageReference('/apex/WikiViewPage');
		WikiPage__c page = [select Id from WikiPage__c limit 1];
		pageRef.getParameters().put('id',page.Id);
		Test.setCurrentPage(pageRef);
		WikiViewPageController controller = new WikiViewPageController();		
	}
}