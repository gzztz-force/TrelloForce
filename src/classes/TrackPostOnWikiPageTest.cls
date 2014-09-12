@isTest
public class TrackPostOnWikiPageTest
{
    @isTest
    static void testInsertFeedItemForWikiPage()
    {
        WikiDataFactory dataFactory = new WikiDataFactory();
        dataFactory.createWikiPagesWithSpaces(3,5,true);
        List<FeedItem> feedItems = new List<FeedItem>();
        for(WikiPage__c page : [select Id from WikiPage__c])
        {
             for(Integer i= 0; i<3; i++)
            {
                FeedItem post = new FeedItem();
                post.ParentId = page.Id;
                post.Body = 'welcome';
                feedItems.add(post);
            }
        }
       insert feedItems;
    }
}