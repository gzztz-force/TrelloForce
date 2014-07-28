public class WikiPageFeedTriggerHandler implements ITrigger
{
    AggregateResult[] feedItemAggregateResults;
    Set<WikiPage__c> wikiPagesSet = new Set<WikiPage__c>();
    public void bulkBefore() {}

    public void bulkAfter()
    {
        Set<Id> wikiPageIds = new Set<Id>();
        if(Trigger.isInsert)
        {
            for(SObject obj : trigger.new)
            {
                FeedItem feedItem = (FeedItem)obj;
                wikiPageIds.add(feedItem.ParentId);
            }
        }
        if(Trigger.isDelete)
        {
            for(SObject obj : trigger.old)
            {
                FeedItem feedItem = (FeedItem)obj;
                wikiPageIds.add(feedItem.ParentId);
            }
        }
        feedItemAggregateResults = [select count(Id) cou, ParentId from WikiPage__Feed where Type != 'TrackedChange' and ParentId in : wikiPageIds group by ParentId];
    }

    public void beforeInsert(SObject so) {}

    public void beforeUpdate(SObject oldSo, SObject so) {}
    
    public void beforeDelete(SObject so) {}

    public void afterInsert(SObject so)
    {
        FeedItem feedItem = (FeedItem)so;
        setPostCountValue(feedItem);
    }

    public void afterUpdate(SObject oldSo, SObject so) {}

    public void afterDelete(SObject so)
    {
        FeedItem feedItem = (FeedItem)so;
        setPostCountValue(feedItem);
    }

    public void andFinally()
    {
        List<WikiPage__c> wikiPagesList = new List<WikiPage__c>();
        if(wikiPagesSet.size() > 0)
        {
            for(WikiPage__c wikiPage : wikiPagesSet)
            {
                wikiPagesList.add(wikiPage);
            }
            Database.update(wikiPagesList, false);
        }
    }
    
    // Set the Post_Count__c field value of the WikiPage
    public void setPostCountValue(FeedItem feedItem)
    {
        if(feedItemAggregateResults.size() > 0 && feedItem.ParentId.getSObjectType() == WikiPage__c.SObjectType && feedItem.Type != 'TrackedChange')
        {
            for(AggregateResult result : feedItemAggregateResults)
            {
                if(result.get('ParentId').equals(feedItem.ParentId))
                {
                    Integer postCount =  Integer.valueOf(result.get('cou'));
                    wikiPagesSet.add(new WikiPage__c(Id = feedItem.ParentId, Post_Count__c = postCount));
                }
            }
        }
    }
}