/**
 * The controller for LogTimeCard page
 * Use it in Chatter Action
 */
global with sharing class LogTimeCardController
{
    private static final Integer QUERY_PROJECT_NUMBER = 10;
    private static final Integer QUERY_CHANGE_NUMBER = 50;

    private Map<String, String> loggedHoursMap;
    public LogTimeCardController()
    {
        loggedHoursMap = getTodayAndYesterdayHours();
    }

    public String TodayHours
    {
        get
        {
            return (loggedHoursMap != null) ? loggedHoursMap.get('today') : '0.0';
        }
    }

    public String YesterdayHours
    {
        get
        {
            return (loggedHoursMap != null) ? loggedHoursMap.get('yesterday') : '0.0';
        }
    }

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

    private static List<MProject__c> queryProjects(List<String> recentUsedProjectIds)
    {
        List<MProject__c> projects = new List<MProject__c>();

        if(recentUsedProjectIds.size() > 0)
        {
            projects = [select Id, Name,
                 (select Id from TeamMembers__r where User__c = :UserInfo.getUserId()),
                 (select Id, Name from Changes__r where IsClosed__c = 0 order by LastActivityDate desc, CreatedDate desc limit :QUERY_CHANGE_NUMBER)
                 from MProject__c where Id in :recentUsedProjectIds
            ];
        }
        else // New user maybe no used project
        {
            projects = [select Id, Name,
                (select Id from TeamMembers__r where User__c = :UserInfo.getUserId()),
                (select Id, Name from Changes__r where IsClosed__c = 0 order by LastActivityDate desc, CreatedDate desc limit :QUERY_CHANGE_NUMBER)
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

    @remoteAction
    global static Decimal getLoggedTimeToday(){
        Decimal totalHours = 0.0;
        for(TimeCard__c card : [select Hours__c from Timecard__c where Date__c = TODAY and TeamMember__r.User__c = :Userinfo.getUserId()])
        {
            totalHours += card.Hours__c;
        }

        return totalHours;
    }

    @remoteAction
    global static Decimal getLoggedTimeYesterday(){
        Decimal totalHours = 0.0;
        for(TimeCard__c card : [select Hours__c from Timecard__c where Date__c = YESTERDAY and TeamMember__r.User__c = :Userinfo.getUserId()])
        {
            totalHours += card.Hours__c;
        }

        return totalHours;
    }

    @remoteAction
    global static String create(String objtype, String fields)
    {
        Map<String, Object> handleResult = new Map<String, Object>();
        Boolean isSuccess = true;
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objtype);
        if (targetType == null) {
            return makeError('The requested resource does not exist', 'NOT_FOUND');
        }

        SObject obj = targetType.newSObject();
        String error = writeFields(objType, obj, fields);
        if (error != null) {
            return error;
        }

        try {
            insert obj;
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

    private static String makeError(String message, String errorCode)
    {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('message', message);
        gen.writeStringField('errorCode', errorCode);
        gen.writeEndObject();
        gen.writeEndArray();

        return gen.getAsString();
    }

    private static String writeFields(String objtype, SObject obj, String fields) {
        Map<String, Object> fieldMap = null;
        try {
            fieldMap = (Map<String, Object>)JSON.deserializeUntyped(fields);
        } catch (JSONException je) {
            return makeError(je.getMessage(), 'JSON_PARSER_ERROR');
        }

        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objtype);

        Map<String, Schema.sObjectField> targetFields = targetType.getDescribe().fields.getMap();

        try {
            for (String key : fieldMap.keySet()) {
                if (targetFields.get(key) == null) {
                    return '[{"message":"Field '+key+' does not exist on object type '+objtype+'","errorCode":"INVALID_FIELD"}]';
                }

                Object value = fieldMap.get(key);
                Schema.DisplayType valueType = targetFields.get(key).getDescribe().getType();

                if (value instanceof String && valueType != Schema.DisplayType.String) {
                    // Coerce an incoming String to the correct type
                    String svalue = (String)value;

                    if (valueType == Schema.DisplayType.Date) {
                        obj.put(key, Date.valueOf(svalue));
                    } else if (valueType == Schema.DisplayType.Percent ||
                           valueType == Schema.DisplayType.Currency) {
                        obj.put(key, svalue == '' ? null : Decimal.valueOf(svalue));
                    } else if (valueType == Schema.DisplayType.Double) {
                        obj.put(key, svalue == '' ? null : Double.valueOf(svalue));
                    } else if (valueType == Schema.DisplayType.Integer) {
                        obj.put(key, Integer.valueOf(svalue));
                    } else {
                        obj.put(key, svalue);
                    }
                } else {
                    // Just try Ø the incoming value on the object
                    obj.put(key, value);
                }
            }
        } catch (SObjectException soe) {
            return makeError(soe.getMessage(), 'INVALID_FIELD');
        }

        return null;
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
}