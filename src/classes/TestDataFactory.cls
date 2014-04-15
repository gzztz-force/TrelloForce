/*
 * A factory can create data for the test method
 */
public class TestDataFactory
{
    public static Integer numberOfProjects = 10;
    public static Integer numberOfChanges = 5;
    public static Integer numberOfTimecards = 10;

    public static List<MProject__c> createProjects()
    {
        // Create Test data
        List<MProject__c> projects = new List<MProject__c>();

        for(Integer i=0; i < numberOfProjects; i++)
        {
            String customerId = createCustomer();

            projects.add(new MProject__c(Name = 'ProjectA' + i,
                               Status__c = 'In Progress',
                               Customer__c = customerId,
                               StartDate__c = Date.today(),
                               EndDate__c = Date.today().addYears(1)));
        }

        insert projects;

        return projects;
    }

    public static List<TeamMember__c> createTeamMembers()
    {
        List<MProject__c> projects = createProjects();

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

    public static List<Change__c> createChanges()
    {
        List<MProject__c> projects = createProjects();

        List<Change__c> changes = new List<Change__c>();

        for(MProject__c project : projects)
        {
            for(Integer i=0; i < numberOfChanges; i++)
            {
                changes.add(new Change__c(Project__c = project.Id,
                                Name = 'Test Change' + i,
                                Description__c = 'Test Change Details',
                                DueDate__c = Date.today().addMonths(1),
                                Status__c = 'Open',
                                Priority__c = 'Low',
                                OpenedBy__c = UserInfo.getUserId(),
                                AssignedTo__c = UserInfo.getUserId()));
            }
        }
        // The first chage is created without specifying the External ID.
        changes[1].ExternalID__c = 'external id';

        insert changes;
        return changes;
    }

    public static void createTimecards()
    {
        List<TeamMember__c> teamMembers = createTeamMembers();
        List<Change__c> changes = createChanges();

        List<TimeCard__c> timecards = new List<TimeCard__c>();

        Map<Id, Id> memberIdToProjectId = new Map<Id, Id>();

        for(TeamMember__c tm : [select Id, Project__c from TeamMember__c where Id in :teamMembers])
        {
            memberIdToProjectId.put(tm.Id, tm.Project__c);
        }

        for(TeamMember__c t : teamMembers)
        {
            for(Integer i=0; i < numberOfTimecards; i++)
            {
                timecards.add(new TimeCard__c(Project__c = memberIdToProjectId.get(t.Id),
                                     TeamMember__c = t.Id,
                                     Hours__c = 8,
                                     Description__c = 'description' + i,
                                     Date__c = Date.today().addDays(-i)));
            }
        }

        insert timecards;
    }

    public static void createChangesAndTimeCards()
    {
        List<TeamMember__c> teamMembers = createTeamMembers();

        List<Change__c> changes = new List<Change__c>();
        List<TimeCard__c> timecards = new List<TimeCard__c>();

        for(Integer i=0; i<2; i++)
        {
            changes.add(new Change__c(Project__c = teamMembers[0].Project__c,
                            Name = 'Test Change' + i,
                            Description__c = 'Test Change Details',
                            DueDate__c = Date.today().addMonths(1),
                            Status__c = 'Open',
                            Priority__c = 'Low',
                            OpenedBy__c = UserInfo.getUserId(),
                            AssignedTo__c = UserInfo.getUserId()));
        }
        insert changes;

        for(Integer i=0; i<4; i++)
        {
            timecards.add(new TimeCard__c(Project__c = teamMembers[0].Project__c,
                                     TeamMember__c = teamMembers[0].Id,
                                     Hours__c = 8,
                                     Description__c = 'description' + i,
                                     Date__c = Date.today().addDays(-i)));
        }
        // The first TimeCard is created without specifying any Change.
        // The second TimeCard is created with Change field populated, but the specified Change has no External ID.
        // The thrid and fourth TimeCard are created with Change field populated, and the specified Change does have External ID.

        timecards[1].Change__c = changes[0].Id;
        timecards[2].Change__c = changes[1].Id;
        timecards[3].Change__c = changes[1].Id;

        insert timecards;
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

    public static String createCustomer()
    {
      Customer__c newCustomer = new Customer__c(Name = 'acme customer');

      insert newCustomer;
      return newCustomer.Id;
    }

    public static void createFinanceServerCustomSetting()
    {
        FinanceServer__c setting = new FinanceServer__c();
        setting.ClientId__c = '3MVG9_7ddP9KqTzdeUy2xmOr2N74sReSNZxQSX1g4ZCL8LMxMudc.PFIsdwEPIRM_4lEYiswlk7aUbw_8Jx5A';
        setting.ClientSecret__c = '1823320581773834609';
        setting.Endpoint__c = 'https://test.salesforce.com/services/oauth2/token';
        setting.Username__c = 'jair.zheng@fin.meginfo.com.sandbox';
        setting.Password__c = 'meginfo2008';

        insert setting;
    }
}
