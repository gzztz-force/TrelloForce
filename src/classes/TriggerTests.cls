@isTest
private class TriggerTests
{
    @isTest
    static void testFillingTeamMemberName()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id, Name from User where IsActive = true limit 1];
        TeamMember__c tm = new TeamMember__c(Project__c=prj.Id, User__c=u.Id);
        insert tm;
        tm = [select Id, Name from TeamMember__c where Id=:tm.Id];
        System.assertEquals(u.Name, tm.Name);
    }

    @isTest
    static void testSendEmailAfterChangeInsert()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id, Name from User where IsActive = true limit 1];
        Change__c newChange = new Change__c(Project__c=prj.Id, Name = 'acme', AssignedTo__c = u.Id, Type__c='Change', Priority__c='Medium', Status__c='Open');
        insert newChange;
    }

    @isTest
    static void testSendEmailAfterChangeUpdate()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id, Name from User where IsActive = true limit 1];
        Change__c change = new Change__c(Project__c=prj.Id, Name='acme', AssignedTo__c=u.Id, Type__c='Change', Priority__c='Medium', Status__c='Open');
        insert change;
        change.Name = 'acme2';
        update change;
    }
    @isTest
    static void testSendEmailAfterChangeCommentInsert()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id, Name from User where IsActive = true limit 1];
        Change__c change = new Change__c(Project__c=prj.Id, Name='acme', AssignedTo__c=u.Id, Type__c='Change', Priority__c='Medium', Status__c='Open');
        insert change;
        ChangeComment__c com = new ChangeComment__c(Change__c = change.Id);
        insert com;
    }

    @isTest
    static void testSubscribeChange()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id from User where IsActive = true limit 1];
        Change__c change = new Change__c(Project__c=prj.Id, Name='acme', AssignedTo__c=u.Id, Type__c='Change', Priority__c='Medium', Status__c='Open');
        insert change;
        ChangeStakeholder__c holder = new ChangeStakeholder__c(Change__c=change.Id, User__c=UserInfo.getUserId());
        insert holder;
    }

    @isTest
    static void testSubscribeProject()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id, Name from User where IsActive = true limit 1];
        TeamMember__c tm = new TeamMember__c(Project__c=prj.Id, User__c=u.Id);
        insert tm;
    }

    @isTest
    static void testRollupKnowledgeComments()
    {
        KnowledgeEntry__c k = new KnowledgeEntry__c(Name='acme');
        insert k;
        FeedItem post = new FeedItem(ParentId=k.Id, Type='TextPost', Title='acme', Body='acme');
        insert post;
    }
    @isTest
    static void testSyncKnowledgeTags()
    {
        KnowledgeEntry__c entry = new KnowledgeEntry__c(Name = 'acme', Tags__c = 'a, b');
        insert entry;

        List<KnowledgeTag__c> tags = [select Id, Name from KnowledgeTag__c where KnowledgeEntry__c=:entry.Id];
        System.assertEquals(2, tags.size());

        entry.IsPublished__c = true;
        update entry;
        tags = [select Id, Name from KnowledgeTag__c where KnowledgeEntry__c=:entry.Id];
        System.assertEquals(2, tags.size());

        entry.Tags__c = 'a,b, c';
        update entry;
        tags = [select Id, Name from KnowledgeTag__c where KnowledgeEntry__c=:entry.Id];
        System.assertEquals(3, tags.size());
    }

    @isTest
    static void testSendEmailAfterTaskUpdate()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id from User where IsActive = true limit 1];
        Change__c change = new Change__c(Project__c=prj.Id, Name='acme', AssignedTo__c=u.Id, Type__c='Change', Priority__c='Medium', Status__c='Open');
        insert change;
        CHangeTask__c tsk = new ChangeTask__c(Name='acme', Status__c='Open', Description__c='acme', AssignedTo__c=UserInfo.getUserId(), Change__c=change.Id);
        insert tsk;

        tsk.Estimation__c=8;
        update tsk;
    }

    @isTest
    static void testCreateSelfLearningProjectTeamMember()
    {
        Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
        UserRole r = [select Id from UserRole where Name = 'Developer'];

        User user = new User(LastName = 'acme1', Alias = 'acme1', Email = 'acme1@acme1.com', UserName = 'acme1@acmemeginfo.com',
                        CommunityNickname = 'acme1@meginfo', ProfileId = p.Id, UserRoleId = r.Id, EmailEncodingKey = 'UTF-8',
                        LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');

        MProject__c prj = new MProject__c(Name='Project for self-learning and non-work related hours');
        insert prj;

        Test.startTest();
        insert user;
        Test.stopTest();

        List<TeamMember__c> teamMember = [select Id, Name from TeamMember__c where Project__r.Name = 'Project for self-learning and non-work related hours'];
        System.assert(teamMember.size() == 1);
    }
}