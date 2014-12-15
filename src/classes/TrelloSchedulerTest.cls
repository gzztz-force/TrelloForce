@isTest
private class TrelloSchedulerTest 
{
	@isTest static void testScheduler() 
	{
		TrelloUser__c testTrelloUser = new TrelloUser__c();
		testTrelloUser.Name = UserInfo.getUserId();
		testTrelloUser.Token__c = 'testToken';
		upsert testTrelloUser ;
		TrelloConfig__C testTrelloConfig = new TrelloConfig__c();
		testTrelloConfig.Key__c = 'testKey';
		upsert testTrelloConfig;
		List<MProject__c> testProjects = new List<MProject__c>();
		for(Integer i=0;i<10;i++)
		{
			MProject__c prj = TrelloTestFactory.createProject('testProject'+i);
			prj.TrelloBoardId__c = 'testTrelloBoardId'+i;
			testProjects.add(prj);
		}
		testProjects[2].TrelloBoardId__c = '545735a69a0da4e4721950fd';
		testProjects[5].TrelloBoardId__c = '5456dd656a8668e557b82685';
		upsert testProjects;

		Test.startTest();
		String CRON_EXP = '0 0 0 15 3 ? 2022';
		String jobId = System.schedule('TrelloSchedulerTest', CRON_EXP, new TrelloScheduler());
		TrelloConnectUtil testTrelloConnectUtil = new TrelloConnectUtil(testProjects);
		Test.setMock(HttpCalloutMock.class, new MockTrelloHttpResponseGenerator());
		MProject__c checkProject = [select Id from MProject__c where TrelloBoardId__c = '545735a69a0da4e4721950fd'];
		List<Change__c> testChanges = [select Id from Change__c where Project__c = :checkProject.Id];
		List<TeamMember__c> testTeamMembers = [select Id from TeamMember__c];
		List<ChangeTask__c> testChangeTasks = [select Id from ChangeTask__c];
		
		Test.stopTest();
		System.assertEquals(testChanges.size(), 1);
		System.assertNotEquals(testTeamMembers.size(), 0);
		System.assertNotEquals(testChangeTasks.size(), 0);
	}
}