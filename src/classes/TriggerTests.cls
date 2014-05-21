@isTest
private class TriggerTests
{
    @isTest
    static void testFillingTeamMemberName()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<TeamMember__c> teamMembers = TestDataFactory.createTeamMembers(projects);
        TeamMember__c tm = [select Id, Name from TeamMember__c where Id= :teamMembers[0].Id];
        System.assertEquals(UserInfo.getName(), tm.Name);
    }

    @isTest
    static void testSendEmailAfterChangeInsert()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        TestDataFactory.createChanges(projects);
    }

    @isTest
    static void testSendEmailAfterChangeUpdate()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        changes[0].Name = 'acme2';
        update changes[0];
    }
    @isTest
    static void testSendEmailAfterChangeCommentInsert()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        ChangeComment__c com = new ChangeComment__c(Change__c = changes[0].Id);
        insert com;
    }

    @isTest
    static void testSubscribeChange()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        ChangeStakeholder__c holder = new ChangeStakeholder__c(Change__c=changes[0].Id, User__c=UserInfo.getUserId());
        insert holder;
    }

    @isTest
    static void testSubscribeProject()
    {
        List<MProject__c> projects = TestDataFactory.createProjects();
        TestDataFactory.createTeamMembers(projects);
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
        List<MProject__c> projects = TestDataFactory.createProjects();
        List<Change__c> changes = TestDataFactory.createChanges(projects);
        CHangeTask__c tsk = new ChangeTask__c(Name='acme', Status__c='Open', Description__c='acme', AssignedTo__c=UserInfo.getUserId(), Change__c=changes[0].Id);
        insert tsk;

        tsk.Estimation__c=8;
        update tsk;
    }

    @isTest
    static void testCreateSelfLearningProjectTeamMember()
    {
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        System.runAs(thisUser)
        {
            Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
            UserRole r = [select Id from UserRole where Name = 'Developer'];

            MProject__c pro = new MProject__c(Name = 'Project for self-learning and non-work related hours');
            insert pro;

            User user = new User(LastName = 'acme1', Alias = 'acme1', Email = 'acme1@acme.com', Birthday__c = Date.valueOf('1991-11-25'), BirthdayType__c = 'Solar',
                    UserName = 'acme1@acme.com', CommunityNickname = 'acme1', ProfileId = p.Id, UserRoleId = r.Id, EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');

            Test.startTest();

            insert user;

            Test.stopTest();

            List<TeamMember__c> teamMember = [select Id, Name from TeamMember__c where Project__c = :pro.Id and User__c = :user.Id];
            System.assertEquals(1, teamMember.size());
        }
    }

    @isTest
    static void testSetLunarSmallMonthBirthday()
    {
        Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
        UserRole r = [select Id from UserRole where Name = 'Developer'];

        User u = new User(LastName = 'acme1', Alias = 'acme1', Email = 'acme1@acme.com', Birthday__c = Date.valueOf('1994-12-30'), BirthdayType__c = 'Lunar',
            UserName = 'acme1@acme.com', CommunityNickname = 'acme1', ProfileId = p.Id, UserRoleId = r.Id, EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');

        insert u;
    }

    @isTest
    static void testSetSolarBirthday()
    {
        Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
        UserRole r = [select Id from UserRole where Name = 'Developer'];

        User u = new User(LastName = 'acme1', Alias = 'acme1', Email = 'acme1@acme.com', Birthday__c = Date.valueOf('1991-2-14'), UserName = 'acme1@acme.com',
            CommunityNickname = 'acme1', ProfileId = p.Id, UserRoleId = r.Id, EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');

        insert u;
    }

    @isTest
    static void testSetLunarBigMonthBirthday()
    {
        Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
        UserRole r = [select Id from UserRole where Name = 'Developer'];

        User u = new User(LastName = 'acme1', Alias = 'acme1', Email = 'acme1@acme.com',
            UserName = 'acme1@acme.com', CommunityNickname = 'acme1', ProfileId = p.Id, UserRoleId = r.Id, EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');

        insert u;

        Group g = new Group(Name = 'BirthdayEmailAlert', Type = 'Regular');

        insert g;

        Group g1 = new Group(Name = 'acmeGroup', Type = 'Regular');

        insert g1;

        GroupMember member = new GroupMember(UserOrGroupId = u.Id, GroupId = g.Id);

        insert member;

        GroupMember member1 = new GroupMember(UserOrGroupId = g1.Id, GroupId = g.Id);

        insert member1;

        u.Birthday__c = Date.today();
        u.BirthdayType__c = 'Solar';
        u.NextBirthday__c = null;

        update u;
    }

    // Test method for UserTrigger.trigger
    @isTest
    public static void testUpdateWeChatIsVerified()
    {
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        System.runAs(thisUser)
        {
            Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
            UserRole r = [select Id from UserRole where Name = 'Developer'];
            User user = new User(LastName = 'acme1', isActive = true, Alias = 'acme1', Email = 'acme1@acme1.com', UserName = 'acme1@acmemeginfo.com',
                                CommunityNickname = 'acme1@meginfo', ProfileId = p.Id, UserRoleId = r.Id, EmailEncodingKey = 'UTF-8',
                             LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles');
            insert user;  
            insert new WeChat__c(Name = '123423acmeopenid', UserId__c = user.Id, IsVerified__c = true, UserEmail__c = 'acme1@acme1.com', UserName__c = 'acme1');
           
            Test.startTest();            
            user.isActive = false;          
            update user;
            Test.stopTest();
            
            WeChat__c newWeChat = WeChat__c.getValues('123423acmeopenid');
            System.assertEquals(newWeChat.IsVerified__c, false);          
        } 
    } 
}