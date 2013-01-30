trigger FillNameOfTeamMember on TeamMember__c (before insert) 
{
	//only support one record inserted at one time
	for(TeamMember__c tm : Trigger.new)
	{
		if(tm.User__c != null)
		{
			User u = [Select Name from User where Id=:tm.User__c];
			tm.Name = u.Name; 
		} 
	}
}