/*
 * this controller used to correlate to custom component "DailyTimeCardReport".
 */
public class DailyTimeCardReportController
{
    public DailyTimeCardReportController()
    {
    }
    
    public String UserId { get; set; }
    
    public String UserFullName
    {
        get
        {
            List<User> users = [select Id, Name from User where Id=:UserId limit 1];
            if(users.size() > 0)
            {
                return users[0].Name;
            }
            else
            {
                return '';  
            }
        }
    }
    
    //gets the total hour of today
    public Decimal TotalHours
    {
        get
        {
            List<AggregateResult> results = [select sum(Hours__c) hour from TimeCard__c where TeamMember__r.User__c=:UserId and Date__c = :Date.today() and Hours__c != null];
            if(results.size() > 0)
            {
                Decimal result = (Decimal)results[0].get('hour');
                return (result != null) ? result : 0;
            }
            else
            {
                return 0;
            }
        }
    }
    
    
    public ChartTable MyMembers
    {
        get
        {
            ChartTable table = new ChartTable();
            table.Cumulative = true;
            for(Integer i = 0; i > -7; i--)
            {
                table.Columns.add(getDayOfWeek(Date.today().addDays(i)));
            }
            Map<Id, String> userMap = new Map<Id, String>();
            table.addValue(UserFullName, table.Columns[0], 0);
            if(String.isNotEmpty(UserId))
            {
                for(User usr : getTeamUsers(UserId))
                {
                    userMap.put(usr.Id, usr.Name);
                    if(usr.Name != UserFullName)
                    {
                        table.addValue(usr.Name, table.Columns[0], 0);
                    }
                }
                
                for(AggregateResult aggResult : [select TeamMember__r.User__c u, sum(Hours__c) h, Date__c d from TimeCard__c where TeamMember__r.User__c in :userMap.keyset() and Date__c <= :Date.today() and Date__c >= :Date.today().addDays(-6) group by TeamMember__r.User__c, Date__c])
                {
                    Id userId = (Id)aggResult.get('u');
                    table.addValue(userMap.get(userId), getDayOfWeek((Date)aggResult.get('d')), (Decimal)aggResult.get('h'));
                }
            }
            return table;
        }
    }

    public List<ChangeInfo> Changes
    {
        get
        {
            List<ChangeInfo> result = new List<ChangeInfo>();
            for(Change__c change : [select Id, ChangeNumber__c, Name, OpenedBy__c, OpenedBy__r.Name, Type__c, Age__c, Estimate__c, DueDate__c, Status__c, AssignedTo__c, AssignedTo__r.Name, Priority__c, Project__c, Project__r.Name from Change__c where AssignedTo__c = :UserId and Status__c not in ('Closed', 'Cancelled') order by Project__r.Name, Status__c limit 100])
            {
                result.add(new ChangeInfo(change));
            }
            return result;
        }
    }
    
    //returns the day of week of specified date, e.g. Tuesday
    private static String getDayOfWeek(Date d)
    {
        return DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEEE');
    }
    
    public static List<User> getTeamUsers(Id userId)
    {
        List<User> users = [select Id, UserRoleId, UserRole.ParentRoleId from User where Id=:userId limit 1];
        if(users.size() > 0)
        {
            Set<Id> teamRoles = new Set<Id>();
            teamRoles.addAll(getSubordinateRoles(users[0].UserRoleId));
            teamRoles.add(users[0].UserRole.ParentRoleId);
            return [select Id, Name from User where IsActive=true and IsEmployee__c=1 and UserRoleId in :teamRoles order by Name];
        }
        return null;
    }
    
    private static Set<Id> getSubordinateRoles(Id roleId)
    {
        return getSubordinateRoles(new Set<Id> {roleId});
    }
    
    private static Set<Id> getSubordinateRoles(Set<Id> roleIds)
    {
        List<UserRole> subRoles = [select Id from UserRole where Id in :roleIds or ParentRoleId in :roleIds];
        if(subroles.size() > roleIds.size())
        {
            for(UserRole role : subRoles)
            {
                roleIds.add(role.Id);
            }
            return getSubordinateRoles(roleIds);
        }
        return roleIds;
    }
    
    public class MemberInfo
    {
        public MemberInfo(String name, Decimal hour)
        {
            this.MemberName = name;
            this.LoggedHour = hour;
            this.LoggedHour = (this.LoggedHour == null) ? 0 : this.LoggedHour;
        }
    
        public String MemberName { get; set; }
        public Decimal LoggedHour { get; set; }
    }
    
    public class ChangeInfo
    {
        public ChangeInfo(Change__c change)
        {
            if(change != null)
            {
                this.ChangeUrl = Url.getSalesforceBaseUrl().toExternalForm().replaceAll('http://', 'https://') + '/' + change.Id;
                this.ChangeId = change.Id;
                this.ChangeNumber = change.ChangeNumber__c;
                this.ChangeName = change.Name;
                this.Age = change.Age__c;
                this.DueDate = change.DueDate__c;
                this.Status = change.Status__c;
                this.Priority = change.Priority__c;
            }   
        }
        
        public String ChangeUrl { get; set; }
        public String ChangeId { get; set; }
        public String ChangeNumber { get; set; }
        public String ChangeName { get; set; }
        public Decimal Age { get; set; }
        public Date DueDate { get; set; }
        public String Status { get; set; }
        public String Priority { get; set; }
        public Boolean IsOpen
        {
            get
            {
                return Status == 'Open' || Status == 'In Progress' || Status == 'Reopened';
            }
        }
        public String DueDateColor 
        { 
            get 
            { 
                return ( DueDate != null && DueDate <= Date.today() && IsOpen)? 'red': 'black'; 
            } 
        }
        public String PriorityColor 
        { 
            get 
            { 
                return (Priority != null && Priority.contains('High') && IsOpen)? 'red' : 'black'; 
            } 
        }
    }

    @isTest
    static void testDailyTimeCardReportController()
    {
        MProject__c project = new MProject__c(Name= 'ProjectTesting', Priority__c = 'medium', EstimatedHours__c = 300, Status__c = 'In Progress');
        insert project;
        Change__c change = new Change__c(Name = 'Testing', Project__c = project.Id, OpenedBy__c = UserInfo.getUserId(), Type__c = 'Change', Estimate__c = 56, DueDate__c = Date.today().addDays(7), Status__c = 'In Progress', AssignedTo__c = UserInfo.getUserId(), Priority__c = 'Medium');
        insert change;
        List<TeamMember__c> members = new List<TeamMember__c> { new TeamMember__c(Name = 'Acme', Project__c = project.Id, User__c = UserInfo.getUserId(),  Role__c = 'Project Manager') };
        insert members;
        List<TimeCard__c> cards = new List<TimeCard__c>{
                                        new TimeCard__c(Date__c = Date.today(), Hours__c = 8, Project__c = project.Id, TeamMember__c = members[0].Id), 
                                        new TimeCard__c(Date__c = Date.today(), Hours__c = 7, Project__c = project.Id, TeamMember__c = members[0].Id)}; 
        insert cards; 

        DailyTimeCardReportController controller = new DailyTimeCardReportController();
        controller.UserId = UserInfo.getUserId();
        String name = controller.UserFullName;
        System.assert(controller.TotalHours != -1);
        System.assert(controller.MyMembers != null);
        System.assert(controller.Changes != null);
    }
}