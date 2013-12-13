/*
 * Unsubscribes a change after updated to closed
 */
trigger UnsubscribeChange on Change__c (after insert, after update) 
{
    Set<Id> removingSubscriptions = new Set<Id>();
    for(Change__c change : Trigger.new) 
    {
        if(change.IsClosed__c == 1)
        {
            removingSubscriptions.add(change.Id);
        }
    }
    if(removingSubscriptions.size() > 0)
    {
        delete [select Id from EntitySubscription where ParentId in :removingSubscriptions];
    }
}