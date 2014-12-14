@isTest
private class TrelloBatchTest
{
    
    @isTest static void testCardBatch() 
    {
        TrelloUser__c testTrelloUser = new TrelloUser__c();
        testTrelloUser.Name = UserInfo.getUserId();
        testTrelloUser.Token__c = 'testToken';
        upsert testTrelloUser ;
        TrelloConfig__c testTrelloConfig = new TrelloConfig__c();
        testTrelloConfig.Key__c = 'testKey';
        upsert testTrelloConfig;
        List<MProject__c> testProjects = new List<MProject__c>();
        List<MProject__c> batchProjects = new List<MProject__c>();
        batchProjects = [select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c != null];
        for(Integer i=0;i<10;i++)
        {
            MProject__c prj = TrelloTestFactory.createProject('testProject'+i);
            testProjects.add(prj);
        }
        List<MProject__c> checkProjects = [select Id from MProject__c];
        System.assertEquals(10,checkProjects.size());
        testProjects[5].TrelloBoardId__c = '5456dd656a8668e557b82685';
        upsert testProjects;
        batchProjects.add(testProjects[5]);
        Test.setMock(HttpCalloutMock.class, new MockTrelloHttpResponseGenerator());
        TrelloBatch testBatch = new TrelloBatch();
        
        Test.startTest();
        testBatch.start(null);
        testBatch.execute(null,batchProjects);
        Test.stopTest();
        List<Change__c> changes = [select Id from Change__c limit 100];
        List<TeamMember__c> teamMembers = [select Id from TeamMember__c limit 10];
        System.assertEquals(7,changes.size());
        System.assertEquals(3,teamMembers.size());

        TrelloConnectUtil util = new TrelloConnectUtil(batchProjects);
        MProject__c operateProject = [select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c = '5456dd656a8668e557b82685'];
        util.deleteWithoutBoardId(operateProject);
        changes = [select Id from Change__c limit 100];
        System.assertEquals(7,changes.size());
    
    }
    @isTest static void testTaskBatch()
    {
        TrelloUser__c testTrelloUser = new TrelloUser__c();
        testTrelloUser.Name = UserInfo.getUserId();
        testTrelloUser.Token__c = 'testToken';
        upsert testTrelloUser ;
        TrelloConfig__c testTrelloConfig = new TrelloConfig__c();
        testTrelloConfig.Key__c = 'testKey';
        upsert testTrelloConfig;
        List<MProject__c> testProjects = new List<MProject__c>();
        List<MProject__c> batchProjects = new List<MProject__c>();
        batchProjects = [select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c != null];
        for(Integer i=0;i<10;i++)
        {
            MProject__c prj = TrelloTestFactory.createProject('testProject'+i);
            testProjects.add(prj);
        }
        List<MProject__c> checkProjects = [select Id from MProject__c];
        System.assertEquals(10,checkProjects.size());
        testProjects[5].TrelloBoardId__c = '5456dd656a8668e557b82685';
        upsert testProjects;
        batchProjects.add(testProjects[5]);
        Test.setMock(HttpCalloutMock.class, new MockTrelloHttpResponseGenerator());
        TrelloChangeTaskBatch testChangeTaskBatch = new TrelloChangeTaskBatch();

        Test.startTest();
        testChangeTaskBatch.start(null);
        testChangeTaskBatch.execute(null,batchProjects);
        testChangeTaskBatch.finish(null);
        Test.stopTest();
        List<ChangeTask__c> tasks = [select Id from ChangeTask__c limit 100];
        System.assertEquals(0,tasks.size());
    }

    @isTest static void testGetBoardInfo()
    {
        TrelloUser__c testTrelloUser = new TrelloUser__c();
        testTrelloUser.Name = UserInfo.getUserId();
        testTrelloUser.Token__c = 'testToken';
        upsert testTrelloUser ;
        TrelloConfig__c testTrelloConfig = new TrelloConfig__c();
        testTrelloConfig.Key__c = 'testKey';
        upsert testTrelloConfig;
        Test.setMock(HttpCalloutMock.class, new MockTrelloHttpResponseGenerator());
        TrelloAPI api = new TrelloAPI('testKey','testToken');
        Test.startTest();
        List<TrelloModel.Board> trelloBoards = api.getBoardInfo();
        Test.stopTest();
        System.assertEquals(4,trelloBoards.size());
    }


}