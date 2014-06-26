/**
 * The controller for LogTimeCard page
 * Use it in Chatter Action
 */
global with sharing class LogTimeCardController
{
    private static final Integer QUERY_PROJECT_NUMBER = 10;
    private static final Integer QUERY_CHANGE_NUMBER = 50;

    private Map<String, String> loggedHoursMap;
    private String objectId;
    private String currentProjectId;
    private String currentChangeId;

    public LogTimeCardController()
    {
        objectId = ApexPages.currentPage().getParameters().get('id');

        CurrentChange = new Change__c();
        if(String.isNotBlank(objectId))
        {
            if(objectId.startsWith(Schema.getGlobalDescribe().get('Change__c').getDescribe().getKeyPrefix()))
            {
                //Set default change and project when in change detail page.
                currentChangeId = objectId;
                CurrentChange = [select Id, Name, Project__c, Project__r.Name from Change__c where Id = :objectId][0];
                currentProjectId = CurrentChange.Project__c;
            }

            else if(objectId.startsWith(Schema.getGlobalDescribe().get('MProject__c').getDescribe().getKeyPrefix()))
            {
                currentProjectId = objectId;
            }
        }
        loggedHoursMap = getTodayAndYesterdayHours();
    }

    public Change__c CurrentChange { get; set; }

    public String TodayHours
    {
        get
        {
            return (loggedHoursMap.get('today') != null) ? loggedHoursMap.get('today') : '0.0';
        }
    }

    public String YesterdayHours
    {
        get
        {
            return (loggedHoursMap.get('yesterday') != null) ? loggedHoursMap.get('yesterday') : '0.0';
        }
    }

    public List<ProjectWithChanges> RecentProjects
    {
        get
        {
            return getRecentUsedProjects(CurrentChange, currentProjectId);
        }
    }

    public String CurrentUserName
    {
        get
        {
            return UserInfo.getName();
        }
    }

    private static List<ProjectWithChanges> getRecentUsedProjects(Change__c currentChange, String currentProjectId)
    {
        List<ProjectWithChanges> result = new List<ProjectWithChanges>();

        List<String> recentUsedProjectIds = getRecentUsedProjectIds();

        Set<String> projectIds = new Set<String>();
        projectIds.addAll(recentUsedProjectIds);
        projectIds.add(currentProjectId);

        List<MProject__c> recentProjects = queryProjects(projectIds, currentChange);

        String selectedProjectId = (String.isBlank(currentProjectId) && recentUsedProjectIds.size() >0) ? recentProjects[0].Id : currentProjectId;

        for(MProject__c project : recentProjects)
        {
            ProjectWithChanges pc = new ProjectWithChanges(project);

            // The current project or the first element of project Id list
            // will be selected by default
            pc.IsSelectedProject = (selectedProjectId == project.Id);

            // When query projects we didn't query current change, put it in.
            if(currentChange != null && currentChange.Project__c == project.Id)
            {
                pc.addChange(currentChange);
            }

            pc.setChangesJsonData(pc.changes);

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
             where TeamMember__r.User__c = :UserInfo.getUserId()
             group by Project__c
             order by Max(Date__c) desc, Max(CreatedDate) desc limit :QUERY_PROJECT_NUMBER
        ];

        for(AggregateResult ar : arProjects)
        {
            String id = String.valueOf(ar.get('Project__c'));
            projectIds.add(id);
        }

        return projectIds;
    }

    private static List<MProject__c> queryProjects(Set<String> projectIds, Change__c currentChange)
    {
        List<MProject__c> projects = new List<MProject__c>();

        projectIds.remove(null);

        if(projectIds.size() > 0)
        {
            projects = [select Id, Name,
                 (select Id from TeamMembers__r where User__c = :UserInfo.getUserId()),
                 (select Id, Name from Changes__r where IsClosed__c = 0 and Id != :currentChange.Id order by LastActivityDate desc, CreatedDate desc limit :QUERY_CHANGE_NUMBER)
                 from MProject__c where Id in :projectIds and IsClosed__c = false
            ];
        }
        else // New user maybe no used project
        {
            projects = [select Id, Name,
                (select Id from TeamMembers__r where User__c = :UserInfo.getUserId()),
                (select Id, Name from Changes__r where IsClosed__c = 0 and Id != :currentChange.Id order by LastActivityDate desc, CreatedDate desc limit :QUERY_CHANGE_NUMBER)
                from MProject__c where IsClosed__c = false order by CreatedDate desc limit :QUERY_PROJECT_NUMBER
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
            this.IsSelectedProject = false;
            this.TeamMemberId = (project.TeamMembers__r.size() > 0) ? project.TeamMembers__r[0].Id : null;
        }

        public Boolean IsSelectedProject { get; set; }
        public String TeamMemberId { get; set; }
        public MProject__c Project { get; set; }
        public List<Change__c> Changes { get; set; }
        public String ChangesJsonData { get; set; }

        private void addChange(Change__c change)
        {
            this.Changes.add(change);
        }

        private void setChangesJsonData(List<Change__c> changes)
        {
            this.ChangesJsonData = JSON.serialize(changes);
        }
    }

    @remoteAction
    global static String create(String objtype, String fields)
    {
        Map<String, Object> handleResult = new Map<String, Object>();
        Boolean isSuccess = true;
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objtype);
        if (targetType == null) {
            return RemoteTKController.makeError('The requested resource does not exist', 'NOT_FOUND');
        }

        SObject obj = targetType.newSObject();
        String error = RemoteTKController.writeFields(objType, obj, fields);
        if (error != null) {
            return error;
        }


        try {
            insert obj;
            createTopicForTimecardRecord(obj.Id);
        } catch (DMLException dmle) {
            String fieldNames = '';
            for (String field : dmle.getDmlFieldNames(0)) {
                if (fieldNames.length() > 0) {
                    fieldNames += ',';
                }
                fieldNames += '"'+field+'"';
            }
            isSuccess = false;
            handleResult.put('error', '{"fields":['+fieldNames+'],"message":"'+dmle.getDmlMessage(0)+'","errorCode":"'+dmle.getDmlType(0).name()+'"}');
        }
        handleResult.put('id', obj.id);
        handleResult.put('success', isSuccess);
        handleResult.put('data', getTodayAndYesterdayHours());

        return JSON.serialize(handleResult);
    }

    //Map Key: today, yesterday
    private static Map<String, String> getTodayAndYesterdayHours()
    {
        List<AggregateResult> hoursSet = [select SUM(Hours__c), Date__c from Timecard__c where (Date__c = YESTERDAY or Date__c = TODAY) and TeamMember__r.User__c = :Userinfo.getUserId() Group by Date__c];
        Map<String, String> hoursMap = new Map<String, String>();
        for(AggregateResult result : hoursSet)
        {
            if(Date.today() == result.get('Date__c'))
            {
                hoursMap.put('today', String.valueOf(result.get('expr0')));
            }
            else
            {
                hoursMap.put('yesterday', String.valueOf(result.get('expr0')));
            }
        }
        return hoursMap;
    }

    // When timecard created by global action, add topic for the record
    private static void createTopicForTimecardRecord(Id objId)
    {
        ConnectApi.Topics.assignTopicByName(null, String.valueOf(objId), 'Global Action');
    }
}