trigger AutoShareProject on TeamMember__c (after insert, after delete) 
{
	if(trigger.isInsert)
	{
		List<MProject__Share> shares = new List<MProject__Share>();
		for(TeamMember__c tm : Trigger.new)
		{		
			if(tm.Project__c != null && tm.User__c != null)
			{
				MProject__Share share = new MProject__Share(ParentId=tm.Project__c, UserOrGroupId=tm.User__c);
				share.AccessLevel = 'Edit';
				share.RowCause = Schema.MProject__Share.RowCause.Manual;
				shares.add(share); 
			}
		}
		Database.insert(shares, false);
	}
	else if(trigger.isDelete)
	{
		for(TeamMember__c tm : Trigger.old)
		{
			List<MProject__Share> shares = [select Id from MProject__Share where ParentId=:tm.Project__c and UserOrGroupId=:tm.User__c];
			delete shares;
		}
	}
}