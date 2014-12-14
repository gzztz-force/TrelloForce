@isTest
private class TrelloConnectUtilTest {

	@isTest static void testUpsertChange() 
	{
		Test.startTest();
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
		TrelloConnectUtil testTrelloConnectUtil = new TrelloConnectUtil(testProjects);
		Test.setMock(HttpCalloutMock.class, new MockTrelloHttpResponseGenerator());
		testTrelloConnectUtil.upsertChange();
		//testTrelloConnectUtil.upsertChangeTask();
		MProject__c checkProject = [select Id from MProject__c where TrelloBoardId__c = '545735a69a0da4e4721950fd'];
		List<Change__c> testChanges = [select Id from Change__c where Project__c = :checkProject.Id];
		List<TeamMember__c> testTeamMembers = [select Id from TeamMember__c];
		List<ChangeTask__c> testChangeTasks = [select Id from ChangeTask__c];
		System.assertEquals(testChanges.size(), 1);
		System.assertNotEquals(testTeamMembers.size(), 0);
		System.assertNotEquals(testChangeTasks.size(), 0);
		MProject__c deleteProject = [select Id, Name from MProject__c where Name = 'testProject4' limit 1 ];
		testTrelloConnectUtil.deleteWithoutBoardId(deleteProject);
		Test.stopTest();
	}
	
	//@isTest static void testDeletWithoutBoardId() 
	//{
	//	List<MProject__c> testProjects = new List<MProject__c>();
	//	for(Integer i=0;i<3;i++)
	//	{
	//		MProject__c prj = TrelloTestFactory.createProject('testProject'+i);
	//		testProjects.add(prj);
	//	}
	//	upsert testProjects;
	//	TrelloConnectUtil testTrelloConnectUtil = new TrelloConnectUtil(testProjects);
	//	MProject__c deleteProject = [select Id, Name from MProject__c limit 1];
		
	//}
	
}