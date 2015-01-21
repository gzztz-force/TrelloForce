@isTest(seeAllData= true)
private class TrelloBoardConnectionControllerTest 
{
    @isTest static void testConnectBoard()
    {
        MProject__c project = new MProject__c (Name = 'testByVicky');
        insert project;
        PageReference pageRef = Page.TrelloBoardConnection;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(new MProject__c());
        TrelloBoardConnectionController testController = new TrelloBoardConnectionController(stdController);
        testController.prj = project;
        System.assertEquals(testController.IsSychronized, false);
        System.assertEquals(testController.BoardId, null);
        
        testController.addMsgConnected();
        System.assertEquals(ApexPages.getMessages().size(), 1);
        testController.addMsgNotConnected();
        testController.addMsgStartSync();
        System.assertEquals(ApexPages.getMessages().size(), 3);
        
        testController.saveToken();
        System.assertEquals(testController.Token, null);
        testController.editToken();

        testController.BoardId = '5456dd656a8668e557b82685';
        testController.connectBoard();
        System.assertEquals(testController.prj.TrelloBoardId__c, '5456dd656a8668e557b82685');
        System.assertEquals(ApexPages.getMessages().size(), 1);
        System.assertEquals(ApexPages.getMessages().get(0).getDetail(), 'Connect Successfully. You can synchronize your data now.');

        List<TrelloBoardConnectionController.Board> boards = new List<TrelloBoardConnectionController.Board>();
        TrelloBoardConnectionController.Board b = new TrelloBoardConnectionController.Board('5456dd656a8668e557b82685', 'Trello with PM', false);
        boards.add(b);
        testController.Boards = boards;
        testController.reSelect();
        System.assertEquals(testController.IsSychronized, true);
        System.assertEquals(b.IsSelected, true);

        testController.BoardId = null;
        boards.add(new TrelloBoardConnectionController.Board(null, 'test', false));
        testController.reSelect();
        System.assertEquals(b.IsSelected, false);
        System.assertEquals(testController.IsSychronized, false);

        testController.prj.trelloBoardId__c = '5456dd656a8668e557b82685';
        testController.BoardId = null;
        testController.connectBoard();

    }

    @isTest static void testSyncChanges()
    {
        MProject__c project = new MProject__c();
        project.trelloBoardId__c ='5456dd656a8668e557b82685';
        upsert project trelloBoardId__c;
        PageReference pageRef = Page.TrelloBoardConnection;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(new MProject__c());
        TrelloBoardConnectionController testController = new TrelloBoardConnectionController(stdController);
        testController.prj = project;
        testController.BoardId = '5456dd656a8668e557b82685';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new MockTrelloHttpResponseGenerator());
        testController.syncChanges();
        Test.stopTest();
        List<Change__c> changes = [select Id, Name from Change__c where Project__c = :testController.prj.Id];
        System.assertEquals(changes.size(), 7);
    }

    @isTest static void testSyncChangeTasks()
    {
        MProject__c project = new MProject__c();
        project.trelloBoardId__c ='5456dd656a8668e557b82685';
        upsert project trelloBoardId__c;
        PageReference pageRef = Page.TrelloBoardConnection;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(new MProject__c());
        TrelloBoardConnectionController testController = new TrelloBoardConnectionController(stdController);
        testController.prj = project;
        testController.BoardId = '5456dd656a8668e557b82685';

        List<TrelloBoardConnectionController.Board> boards = new List<TrelloBoardConnectionController.Board>();
        TrelloBoardConnectionController.Board b = new TrelloBoardConnectionController.Board('5456dd656a8668e557b82685', 'Trello with PM', false);
        boards.add(b);
        testController.Boards = boards;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new MockTrelloHttpResponseGenerator());
        testController.syncChangeTasks();
        Test.stopTest();
        List<ChangeTask__c> changeTasks = [select Id, Name from ChangeTask__c where TrelloItemId__c != null];
        System.assertEquals(changeTasks.size(), 6);
    }

    @isTest static void testTrelloModel()
    {
        TrelloModel model = new TrelloModel();
        TrelloModel.Board boardModel = new TrelloModel.Board();
        TrelloModel.Card cardModel = new TrelloModel.Card();
        TrelloModel.Member memberModel = new TrelloModel.member();
        TrelloModel.MemberShips membershipsModel = new TrelloModel.MemberShips();

    }
    
}