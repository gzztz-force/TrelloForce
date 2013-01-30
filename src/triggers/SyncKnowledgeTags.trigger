/**
 * Converts KnowledgeTag from a text field to the child objects
 * If a knowledge entry has a tag 'a,b,c', the trigger creates 3 tags on the entry 'a', 'b' and 'c'.
 */
trigger SyncKnowledgeTags on KnowledgeEntry__c (after insert, after update) 
{
    List<KnowledgeTag__c> tags = new List<KnowledgeTag__c>();
    Set<Id> publishedEntries = new Set<Id>();
    
    if(Trigger.isInsert)
    {
        for(KnowledgeEntry__c entry : Trigger.new) 
        {   
            tags.addAll(parseTags(entry));
            if(entry.IsPublished__c == true)
            {
                publishedEntries.add(entry.Id);
            }
        }
    }
    else if(Trigger.isUpdate)
    {
        Set<Id> updatingEntries = new Set<Id>();
        
        for(KnowledgeEntry__c entry : Trigger.new)
        {
            KnowledgeEntry__c oldEntry = Trigger.oldMap.get(entry.Id);
            if(entry.Tags__c != oldEntry.Tags__c)
            {
                updatingEntries.add(entry.Id);
                tags.addAll(parseTags(entry));
            }
            if(oldEntry.IsPublished__c == false && entry.IsPublished__c == true)
            {
                publishedEntries.add(entry.Id);
            }
        }
        if(updatingEntries.size() > 0)
        {
            delete [select Id from KnowledgeTag__c where KnowledgeEntry__c in :updatingEntries];
        }
    }
    
    if(tags.size() > 0)
    {
        insert tags;
    }
    addFollowers(publishedEntries);
        
    private List<KnowledgeTag__c> parseTags(KnowledgeEntry__c knowledge)
    {
        List<KnowledgeTag__c> result = new List<KnowledgeTag__c>();
        if(knowledge != null && knowledge.Tags__c != null)
        {
            List<String> knowledgeTags = knowledge.Tags__c.split(',');
            for(String tag : knowledgeTags)
            {
                KnowledgeTag__c knowledgeTag = new KnowledgeTag__c(KnowledgeEntry__c = knowledge.Id, Name = tag.trim());
                result.add(knowledgeTag);
            }
        }
        return result;
    }
    
    private void addFollowers(Set<Id> entryIds)
    {
        List<EntitySubscription> subscribers = new List<EntitySubscription>();
        List<User> users = [select Id from User where IsActive = true and IsEmployee__c=1];
        for(Id entryId : entryIds)
        {
            for(User user : users)
            {
                subscribers.add(new EntitySubscription(ParentId = entryId, SubscriberId = user.Id));  
            }
        }
        if(subscribers.size() > 0)
        {
            Database.insert(subscribers, false);
        }
    }
}