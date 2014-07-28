/**
*  Test for the FeedItemTrigger	
*/
@isTest
public class FeedItemTriggerTest 
{
	@isTest
	static void testfeedItemTrigger()
	{
		WikiDataFactory wikiDateFactory = new WikiDataFactory();
		wikiDateFactory.createWikiPageVersions(wikiDateFactory.createWikiPagesWithSpaces(2, 3, false));
		Boolean flage = false;
		System.assertEquals(2, [select Id, Title__c, Post_Count__c from WikiPage__c where Title__c = 'title0'].get(0).Post_Count__c);
		
		delete [select Id from FeedItem];
		
		WikiPageFeedTriggerHandler wikiPageFeedTriggerHandlerTest = new WikiPageFeedTriggerHandler();
		wikiPageFeedTriggerHandlerTest.bulkBefore();
		wikiPageFeedTriggerHandlerTest.beforeDelete(new FeedItem());
		wikiPageFeedTriggerHandlerTest.beforeInsert(new FeedItem());
		wikiPageFeedTriggerHandlerTest.beforeUpdate(new FeedItem(), new FeedItem());
		wikiPageFeedTriggerHandlerTest.afterUpdate(new FeedItem(), new FeedItem());
		try 
		{
			TriggerFactory.createHandler(null);
		} 
		catch(TriggerException ex) 
		{
			System.assertEquals('No Trigger Handler registered for Object Type: null', ex.getMessage());
			System.debug(ex.getMessage());
		}
		
	}	
}