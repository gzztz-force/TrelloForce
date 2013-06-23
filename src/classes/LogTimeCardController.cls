/**
 * The controller for LogTimeCard page
 * Use it in Chatter Action
 */
public with sharing class LogTimeCardController
{
    private static final Integer QUERY_PROJECT_NUMBER = 10;
    private static final Integer QUERY_CHANGE_NUMBER = 50;

    public List<ProjectWithChanges> RecentProjects
    {
        get
        {
            return getRecentUsedProjects();
        }
    }

    private static List<ProjectWithChanges> getRecentUsedProjects()
    {
        List<ProjectWithChanges> result = new List<ProjectWithChanges>();

        List<String> projectIds = getRecentUsedProjectIds();
        List<MProject__c> recentProjects = queryProjects(projectIds);

        for(MProject__c project : recentProjects)
        {
            ProjectWithChanges pc = new ProjectWithChanges(project);

            // The first element of Project Id List is the latest used prject id
            // It is selected by default
            if(projectIds.size() > 0 && projectIds[0] == project.Id)
            {
                pc.IsLatestUsedProject = true;
            }

            // Only the project's team member can log time card
            if(pc.TeamMemberId != null)
            {
                result.add(pc);
            }
        }

        return result;
    }

    private static List<String> getRecentUsedProjectIds()
    {
        List<String> projectIds = new List<String>();

        AggregateResult[] arProjects = [select Project__c from TimeCard__c
             group by Project__c
             Having Max(TeamMember__r.User__c) = :UserInfo.getUserId()
             order by Max(Date__c) desc, Max(CreatedDate) desc limit :QUERY_PROJECT_NUMBER
        ];

        for(AggregateResult ar : arProjects)
        {
            String id = String.valueOf(ar.get('Project__c'));
            projectIds.add(id);
        }

        return projectIds;
    }

    private static List<MProject__c> queryProjects(List<String> recentUsedProjectIds)
    {
        List<MProject__c> projects = new List<MProject__c>();

        if(recentUsedProjectIds.size() > 0)
        {
            projects = [select Id, Name,
                 (select Id from TeamMembers__r where User__c = :UserInfo.getUserId()),
                 (select Id, Name from Changes__r order by LastActivityDate desc, CreatedDate desc limit :QUERY_CHANGE_NUMBER)
                 from MProject__c where Id in :recentUsedProjectIds
            ];
        }
        else // New user maybe no used project
        {
            projects = [select Id, Name,
                (select Id from TeamMembers__r where User__c = :UserInfo.getUserId()),
                (select Id, Name from Changes__r order by LastActivityDate desc, CreatedDate desc limit :QUERY_CHANGE_NUMBER)
                from MProject__c order by CreatedDate desc limit :QUERY_PROJECT_NUMBER
            ];
        }

        return projects;
    }

    public class ProjectWithChanges
    {
        public ProjectWithChanges(MProject__c project)
        {
            this.Project = project;
            this.Changes = project.Changes__r;
            this.IsLatestUsedProject = false;
            this.TeamMemberId = (project.TeamMembers__r.size() > 0) ? project.TeamMembers__r[0].Id : null;
            this.ChangesJsonData = JSON.serialize(project.Changes__r);
        }

        public Boolean IsLatestUsedProject { get; set; }
        public String TeamMemberId { get; set; }
        public MProject__c Project { get; set; }
        public List<Change__c> Changes { get; set; }
        public String ChangesJsonData { get; set; }
    }
}