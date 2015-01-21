@isTest
global class TrelloTestFactory 
{
	private static List<MProject__c> insertProjects;

	public TrelloTestFactory()
	{
		insertProjects = new List<MProject__c>();
	}

	public static MProject__c createProject(String name)
	{
		MProject__c prj = new MProject__c();
		prj.Name = name;
		insert prj;
		return prj;
	}

	public static TrelloUser__c createTrelloUser()
	{
		TrelloUser__c trelloUser = new TrelloUser__c();
		trelloUser.Name = 'testTrelloUserId';
		trelloUser.Token__c = 'testToken';
		insert trelloUser;
		return trelloUser;
	}

	public static TrelloConfig__c createTrelloConfig()
	{
		TrelloConfig__c trelloConfig = new TrelloConfig__c();
		trelloConfig.Key__c = 'testKey';
		insert trelloConfig;
		return trelloConfig;
	}
}