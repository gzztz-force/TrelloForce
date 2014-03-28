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
            MProject__c p = new MProject__c();
            p.Name = 'ProjectA' + i;
            p.Status__c = 'In Progress';
            projects.add(p);
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
            TeamMember__c t = new TeamMember__c(Name= UserInfo.getName(), User__c = UserInfo.getUserId(), Project__c = p.Id);
            teamMembers.add(t);
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
                Change__c c = new Change__c();
                c.Project__c = project.Id;
                c.Name = 'Change' + i;
                c.Priority__c = 'Low';
                changes.add(c);
            }
        }

        insert changes;
        return changes;
    }

    public static void createTimecards()
    {
        List<TeamMember__c> teamMembers = createTeamMembers();

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
                TimeCard__c tm = new TimeCard__c();
                tm.Project__c = memberIdToProjectId.get(t.Id);
                tm.TeamMember__c = t.Id;
                tm.Hours__c = 8;
                tm.Date__c = Date.today().addDays(-i);
                timecards.add(tm);
            }
        }

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

    public static String createCustomer(String customerName)
    {
      Customer__c newCustomer = new Customer__c(Name = customerName);
      insert newCustomer;
      return newCustomer.Id;
    }

    public static String createProject(String customerId, String projectName)
    {
      MProject__c newProject = new MProject__c(Name = projectName, Customer__c = customerId, Status__c = 'In Progress');
      newProject.StartDate__c = Date.today();
      newProject.EndDate__c = Date.today().addYears(1);
      insert newProject;
      return newProject.Id;
    }

    public static String createTeamMember(String projectId)
    {
      TeamMember__c newTeamMember = new TeamMember__c(Project__c = projectId, User__c = UserInfo.getUserId());
      insert newTeamMember;
      return newTeamMember.Id;
    }

    public static List<Change__c> createChanges(String projectId)
    {
      List<Change__c> changes = new List<Change__c>();
      for(Integer i = 0; i < 2; i++)
      {
          changes.add(new Change__c(Project__c = projectId,
                          Name = 'Test Change' + i,
                          Description__c = 'Test Change Details',
                          DueDate__c = Date.today().addMonths(1),
                          Status__c = 'Open',
                          OpenedBy__c = UserInfo.getUserId(),
                          AssignedTo__c = UserInfo.getUserId()));
      }
      // The first chage is created without specifying the External ID.
      changes[1].ExternalID__c = 'external id';
      insert changes;
      return changes;
    }

    public static List<TimeCard__c> createTimeCards(String projectId, String temMemberId, List<Change__c> changes)
    {
      List<TimeCard__c> timeCards = new List<TimeCard__c>();
      for(Integer i = 0; i < 4; i ++)
      {
          timeCards.add(new TimeCard__c(Project__c = projectId,
                              Date__c = Date.today(),
                              TeamMember__c = temMemberId,
                              Hours__c = 8,
                              Description__c = 'Test Time Card' + i));
      }
      // The first TimeCard is created without specifying any Change.
      // The second TimeCard is created with Change field populated, but the specified Change has no External ID.
      // The thrid and fourth TimeCard are created with Change field populated, and the specified Change does have External ID.
      timeCards[1].Change__c = changes[0].Id;
      timeCards[2].Change__c = changes[1].Id;
      timeCards[3].Change__c = changes[1].Id;
      insert timeCards;
      return timeCards;
    }
}