/*
 * Rollup the chatter comments to KnowledgeEntry
 * calculates the comments number and last comment date
 */
trigger RollupKnowledgeComments on FeedItem (after insert)  
{
    Set<Id> knowledgeIds = new Set<Id>();
    for(FeedItem comment : Trigger.new)
    {
        knowledgeIds.add(comment.ParentId);
    }
    
    List<KnowledgeEntry__c> knowledges = [select Id, (select Id from Feeds) from KnowledgeEntry__c where Id in :knowledgeIds];
    if(knowledges.size() > 0)
    {
        for(KnowledgeEntry__c knowledge : knowledges)
        {
            knowledge.CommentsCount__c = knowledge.Feeds.size();
            knowledge.LastCommentDate__c = DateTime.now();
        }
        update knowledges;
    }
}