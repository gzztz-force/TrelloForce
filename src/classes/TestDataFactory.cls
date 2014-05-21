/*
 * A factory can create data for the test method
 */
public class TestDataFactory
{
    public static Integer numberOfProjects = 10;
    public static Integer numberOfChanges = 5;
    public static Integer numberOfTimecards = 10;

    public static MProject__c generateSampleProject(String name)
    {
        MProject__c pro = new MProject__c();
        pro.Name = name + ''+ Datetime.now().getTime();
        return pro;
    }

    public static MProject__c generateSampleActiveProject(String name)
    {
        MProject__c pro = TestDataFactory.generateSampleProject(name);
        pro.Status__c = 'In Progress';
        pro.StartDate__c = Date.today();
        pro.EndDate__c = Date.today().addYears(1);
        return pro;
    }

    public static MProject__c generateActiveProjectForCustomer(String name, Id customerId)
    {
        MProject__c pro = TestDataFactory.generateSampleActiveProject(name);
        pro.Customer__c = customerId;
        return pro;
    }

    public static Change__c generateSampleChange(Id projectId, String name)
    {
        Change__c change = new Change__c(Project__c = projectId,
                                Name = name,
                                Description__c = 'Test Change Details',
                                DueDate__c = Date.today().addMonths(1),
                                Status__c = 'Open',
                                Priority__c = 'Low',
                                OpenedBy__c = UserInfo.getUserId(),
                                AssignedTo__c = UserInfo.getUserId());
        return change;
    }

    public static TeamMember__c generateSampleTeamMember(MProject__c pro)
    {
        TeamMember__c member = new TeamMember__c(User__c=UserInfo.getUserId(), Project__c=pro.Id);
        member.Name = 'acme' + Datetime.now().getTime();

        return member;
    }

    public static List<MProject__c> createProjects()
    {
        // Create Test data
        List<MProject__c> projects = new List<MProject__c>();

        String customerId = createCustomer();

        for(Integer i=0; i < numberOfProjects; i++)
        {
            projects.add(TestDataFactory.generateActiveProjectForCustomer('ProjectA' + i, customerId));
        }

        insert projects;

        return projects;
    }

    public static List<TeamMember__c> createTeamMembers(List<MProject__c> projects)
    {
        List<TeamMember__c> teamMembers = new List<TeamMember__c>();

        for(MProject__c p : projects)
        {
            teamMembers.add(new TeamMember__c(Name= UserInfo.getName(),
                                  User__c = UserInfo.getUserId(),
                                  Project__c = p.Id));
        }

        insert teamMembers;

        return teamMembers;
    }

    public static List<Change__c> createChanges(List<MProject__c> projects)
    {
        List<Change__c> changes = new List<Change__c>();

        for(MProject__c project : projects)
        {
            for(Integer i=0; i < numberOfChanges; i++)
            {
                changes.add(TestDataFactory.generateSampleChange(project.Id, 'Change' + i));
            }
        }
        // The first chage is created without specifying the External ID.
        changes[1].ExternalID__c = 'external id';

        insert changes;
        return changes;
    }

    public static void createTimecards(List<TeamMember__c> teamMembers)
    {
        List<TimeCard__c> timecards = new List<TimeCard__c>();

        for(TeamMember__c t : teamMembers)
        {
            for(Integer i=0; i < numberOfTimecards; i++)
            {
                timecards.add(new TimeCard__c(Project__c = t.Project__c,
                                     TeamMember__c = t.Id,
                                     Hours__c = 8,
                                     Description__c = 'description' + i,
                                     Date__c = Date.today().addDays(-i)));
            }
        }

        insert timecards;
    }

    public static String createCustomer()
    {
        Customer__c newCustomer = new Customer__c(Name = 'acme customer');

        insert newCustomer;
        return newCustomer.Id;
    }

    public static void createTimeCardSyncSettings()
    {
        TimeCardSyncSetting__c setting = new TimeCardSyncSetting__c();
        setting.Name__c = 'Eric He';
        setting.Email__c = 'eric.he@meginfo.com';
        setting.Endpoint__c = 'https://inlab-developer-edition.ap1.force.com/services/apexrest/TimeCardManagment/';
        setting.CustomerName__c = 'Touchpoint Solutions';

        insert setting;
    }

    public static void createFinanceServerCustomSetting()
    {
        FinanceServer__c setting = new FinanceServer__c();
        setting.ClientId__c = 'X1g4ZCL8LMxMudc.PFIsdwEPIRM_4lEYiswlk7aUbw_8Jx5A';
        setting.ClientSecret__c = '18233205812388';
        setting.Endpoint__c = 'https://test.salesforce.com/services/oauth2/token';
        setting.Username__c = 'acme@fin.meginfo.com.sandbox';
        setting.Password__c = 'acme';

        insert setting;
    }

    public static User newUser(Id profileId, Id roleId)
    {
        String ret = 'user' + Math.rint(Math.random() * 100000);

        User testUser = new User();
        testUser.Email = 'test@test.com';
        testUser.Username = ret + '@testuser.com';
        testUser.LastName = 'test';
        testUser.Alias = 'test';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.TimeZoneSidKey = 'America/Chicago';
        testUser.EmailEncodingKey = 'UTF-8';

        testUser.UserRoleId = roleId;
        testUser.ProfileId = profileId;
        testUser.ManagerId = UserInfo.getUserId();

        return testUser;
    }
}