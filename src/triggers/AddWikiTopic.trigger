trigger AddWikiTopic on FeedItem (after insert) 
{
    List<TopicAssignment> assignments = new List<TopicAssignment>();
    Topic topic;
    List<Topic> topics = [select id from Topic where name = 'Wiki' limit 1];
    System.debug(topics.size()+'**********************');
    if(topics.size() == 0)
    {
        String tempName = 'Wiki';
        if(Test.isRunningTest())
        {
            tempName = String.valueOf(datetime.now());
        }
        topic = new Topic();
        topic.name = tempName;
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