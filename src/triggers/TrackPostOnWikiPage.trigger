trigger TrackPostOnWikiPage on WikiPage__c (after insert, after update) 
{
    if(Trigger.isAfter &&Trigger.isInsert )
    {
        insertFeedItem('created this page',Trigger.newMap.keySet());        
    }

    else if(Trigger.isAfter && Trigger.isUpdate)
    {
        Set<Id> ids = new Set<Id>();
        for(WikiPage__c page : Trigger.New)
        {
            WikiPage__c oldPage = Trigger.oldMap.get(page.Id);
            if(page.TotalPageVersion__c == oldPage.TotalPageVersion__c)
            {
                ids.add(page.Id);
            }
        }
        insertFeedItem('edited this page',ids);
    }

    private void insertFeedItem(String itemBody,Set<Id> ids)
    {
        List<FeedItem> feedItems = new List<FeedItem>();
        for(Id pageId : ids)
        {
            FeedItem feed = new FeedItem();
            feed.Body = itemBody;
            feed.Type = 'TextPost';
            feed.ParentId = pageId;
            feedItems.add(feed);
        }  
        insert feedItems;
    }
}