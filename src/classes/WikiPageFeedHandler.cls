public class WikiPageFeedHandler implements ITrigger
{
	Map<FeedItem, WikiPage__c> feedItemtoWikiPageMap = new Map<FeedItem, WikiPage__c>();
    List<Id> wikiPageIds = new List<Id>();
    List<FeedItem> feedItemsFiltered = new List<FeedItem>();
    AggregateResult[] feedItemsFromWikiPageResult;
    List<WikiPage__c> wikiPages = new List<WikiPage__c>();
	public WikiPageFeedHandler()
	{

	}
	/**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {

    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter()
    {
    	if(Trigger.isInsert)
    	{	
    		feedItemtoWikiPageMap(trigger.new);
    	}
    	if(Trigger.isDelete)
    	{
    		feedItemtoWikiPageMap(trigger.old);
    	}
        feedItemsFromWikiPageResult = [select count(Id) cou, ParentId from WikiPage__Feed where Type != 'TrackedChange' group by ParentId];
    }

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(SObject so)
    {

    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(SObject oldSo, SObject so)
    {

    }

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so)
    {

    }

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(SObject so)
    {
    	FeedItem feedItem = (FeedItem)so;
    	getWikipages(feedItem);
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(SObject oldSo, SObject so)
    {

    }

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(SObject so)
    {
		FeedItem feedItem = (FeedItem)so;
    	getWikipages(feedItem);
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally()
    {
    	if(wikiPages.size() > 0)
    	{
    		updateWikiPage();
    	}
    }

    //update the field Post_Count__c on the wikiPage__c.
    public void updateWikiPage()
    {
    	update wikiPages;
    }

    //select the feedItems on the wikiPage
    public void feedItemtoWikiPageMap(List<FeedItem> feedItems)
    {
    	for (SObject obj : feedItems)
        {
        	FeedItem feedItem = (FeedItem)obj;
            if (feedItem.ParentId.getSObjectType() == WikiPage__c.SObjectType && !feedItem.Type.equals('TrackedChange'))
            {
                wikiPageIds.add(feedItem.ParentId);
                feedItemsFiltered.add(feedItem);
            }
        }
        List<WikiPage__c> wikiPages = [select Id, Post_Count__c from WikiPage__c where Id in :wikiPageIds];
        for(FeedItem feedItem : feedItemsFiltered)
        {
            for(WikiPage__c tempWikiPage : wikiPages)
            {
                if(feedItem.ParentId == tempWikiPage.Id)
                {
                    feedItemtoWikiPageMap.put(feedItem, tempWikiPage);
                }
            }
        }
    }
    
    //get the wikipages when the feedItem count is changed
    public void getWikipages(FeedItem feedItem)
    {
    	for(AggregateResult result : feedItemsFromWikiPageResult)
    	{
    		if(result.get('ParentId').equals(feedItem.ParentId))
    		{
    			feedItemtoWikiPageMap.get(feedItem).Post_Count__c = feedItemtoWikiPageMap.get(feedItem).Post_Count__c == null ? 0 : Integer.valueOf(result.get('cou'));
    			wikiPages.add(feedItemtoWikiPageMap.get(feedItem));
    		}
    	}
    }
}