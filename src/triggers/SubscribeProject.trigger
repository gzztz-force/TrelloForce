/*
 * makes the team member subscribe the project automatically, after the team member record is created
 */
trigger SubscribeProject on TeamMember__c (after insert) 
{ 
	List<EntitySubscription> subscriptions = new List<EntitySubscription>();
	Set<Id> subscribingUsers = new Set<Id>();
	for(User usr : [select Id, UserPreferencesDisableAutoSubForFeeds from User])
	{
		if(!usr.UserPreferencesDisableAutoSubForFeeds)
		{
			subscribingUsers.add(usr.Id);
		}
	}
	
	for(TeamMember__c member : [select Id, User__c, Project__c from TeamMember__c where Id in :Trigger.new and Project__r.Status__c != 'Closed'])
	{
		if(subscribingUsers.contains(member.User__c))
		{
			subscriptions.add(new EntitySubscription(SubscriberId=member.User__c, ParentId=member.Project__c));
		}
	}
	
	if(subscriptions.size() > 0)
	{
		try
		{
			Database.insert(subscriptions, false);
		}
		catch(Exception ex)
		{
			Trigger.new[0].addError(ex.getMessage());
		}
	}
}