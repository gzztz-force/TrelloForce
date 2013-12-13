/*
 * Post a chatter feed after a new change is created, in case the followers are not aware of.
 */
trigger PostFeedOnNewChange on Change__c (after insert) 
{
    if(EmailToChangeHandler.EmailServiceIsWorking != true)
    {
        List<FeedItem> items = new List<FeedItem>();
        for(Change__c chg : Trigger.new)
        {
            items.add(new FeedItem(ParentId=chg.Id, Type='TextPost', CreatedById=chg.OpenedBy__c, Body='created this change.'));
        }
        Database.insert(items, false);
    }
}