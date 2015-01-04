trigger TrackPostOnWikiPage on WikiPage__c (after insert) 
{
    if(Trigger.isAfter && Trigger.isInsert )
    {
        insertFeedItemForWikiPage(Trigger.New);        
    }
    private void insertFeedItemForWikiPage(List<WikiPage__c> pages)
    {
        List<FeedItem> feedItems = new List<FeedItem>();
        for(WikiPage__c page : pages)
        {
            FeedItem feed = new FeedItem();
            feed.Body = 'created this page : '+page.title__c;
            feed.Type = 'TextPost';
            feed.ParentId = page.Id;
            feedItems.add(feed);
        }  
        insert feedItems;
    }
}