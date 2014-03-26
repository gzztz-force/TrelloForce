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

    public static void createChanges()
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
                changes.add(c);
            }
        }

        insert changes;
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
}