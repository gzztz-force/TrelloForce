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
            MProject__c prj = TrelloTestFactory.createProject('testProject' + i);
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
        System.assertEquals(7, changes.size());
        System.assertEquals(3, teamMembers.size());

        MProject__c deleteProject = [select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c = null limit 1];
        Change__c deleteChange = new Change__c();
        deleteChange.Project__c = deleteProject.Id;
        deleteChange.Name = 'deleteChange';
        deleteChange.TrelloCardId__c = 'testDeleteTrelloCardId';
        insert deleteChange;
        changes = [select Id, Name from Change__c limit 100];
        System.assertEquals(8, changes.size());
        TrelloConnectUtil util = new TrelloConnectUtil(batchProjects);
        util.deleteWithoutBoardId(deleteProject);
        changes = [select Id, Name from Change__c limit 100];
        System.assertEquals(7, changes.size());
    }

    @isTest (SeeAllData=true)
    static void testTaskBatch()
    {
        List<MProject__c> batchProjects = new List<MProject__c>();
        batchProjects = [select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c = '5456dd656a8668e557b82685'];
        Test.setMock(HttpCalloutMock.class, new MockTrelloHttpResponseGenerator());
        TrelloChangeTaskBatch testChangeTaskBatch = new TrelloChangeTaskBatch();
        List<ChangeTask__c> tasks = [select Id from ChangeTask__c limit 100];
        System.assertEquals(12, tasks.size());

        Test.startTest();
        testChangeTaskBatch.start(null);
        testChangeTaskBatch.execute(null, batchProjects);
        testChangeTaskBatch.finish(null);
        Test.stopTest();

        tasks = [select Id from ChangeTask__c limit 100];
        System.assertEquals(7, tasks.size());
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
        TrelloAPI api = new TrelloAPI('testKey', 'testToken');

        Test.startTest();
        List<TrelloModel.Board> trelloBoards = api.getBoardInfo();
        Test.stopTest();

        System.assertEquals(4, trelloBoards.size());
    }

    @isTest static void testTrelloModel()
    {
        TrelloModel model = new TrelloModel();
        TrelloModel.Board boardModel = new TrelloModel.Board();
        boardModel.Id = 'id';
        boardModel.Name = 'name';
        TrelloModel.Card cardModel = new TrelloModel.Card();
        TrelloModel.Member memberModel = new TrelloModel.member();
        TrelloModel.MemberShips membershipsModel = new TrelloModel.MemberShips();


    }

}