trigger AddWikiTopic on FeedItem (after insert) 
{
    List<TopicAssignment> assignments = new List<TopicAssignment>();
    Topic topic;
    List<Topic> topics = [select id from Topic where name = 'wiki' limit 1];
    if(topics.size() == 0)
    {
        topic = new Topic();
        topic.name = 'Wiki';
        insert topic;
    }
    else
    {
        topic = topics[0];
    }
	for(FeedItem item : Trigger.New)
    {
		if(String.valueOf(item.ParentId.getSObjectType().getDescribe().getName()).equalsIgnoreCase('WikiPage__c'))
        {               
            TopicAssignment assignment = new TopicAssignment();
            assignment.EntityId = item.Id;
            assignment.TopicId = topic.Id;
            assignments.add(assignment);
        }
    }
    if(assignments.size() > 0)
    {
        insert assignments;
    }  
}