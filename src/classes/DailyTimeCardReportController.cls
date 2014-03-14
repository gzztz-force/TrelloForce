/*
 * this controller used to correlate to custom component "DailyTimeCardReport".
 */
public class DailyTimeCardReportController
{
    public DailyTimeCardReportController()
    {
    }

    public String UserId { get; set; }
    public String LeaveType { get; set; }

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
                for(User user : getTeamUsers(UserId))
                {
                    userMap.put(user.Id, user.Name);
                    if(user.Name != UserFullName)
                    {
                        table.addValue(user.Name, table.Columns[0], 0);
                    }
                }

                Map<LeaveInFin.Leave, Map<Date, String>> leaveToDaysThisWeek = getLeaveToDaysThisWeek(LeaveInFin.getAllLeaves());
                List<User> users = getLeaveUsersThisWeek(leaveToDaysThisWeek);
                Map<Id, Map<Date, String>> userIdToLeaveDaysThisWeek = getUserIdToLeaveDates(leaveToDaysThisWeek, users);
                Map<Id, Map<Date, Decimal>> userIdToDaysHours = getUserIdToDaysHours(userMap.keySet());

                for(Id userId : userMap.keySet())
                {
                    if(userIdToDaysHours.containsKey(userId))
                    {
                        for(Date d : userIdToDaysHours.get(userId).keySet())
                        {
                            if(userIdToDaysHours.get(userId).get(d) <= 4 && userIdToLeaveDaysThisWeek.containsKey(userId))
                            {
                                Map<Date, String> dayToHalfDay = userIdToLeaveDaysThisWeek.get(userId);
                                if(userIdToLeaveDaysThisWeek.get(userId).keySet().contains(d))
                                {
                                    String type = dayToHalfDay.get(d);
                                    if(type == null)
                                    {
                                        type = 'Whole Day';
                                    }
                                    LeaveType = type;
                                }
                            }
                            table.addValue(userMap.get(userId), getDayOfWeek(d), userIdToDaysHours.get(userId).get(d));
                        }
                    }
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

    // gets user leave info this week , key : userid  value : key: leave date  value : halfday
    public Map<Id, Map<Date, String>> getUserIdToLeaveDates(Map<LeaveInFin.Leave, Map<Date, String>> leaveToDaysThisWeek, List<User> users)
    {
        Map<Id, Map<Date, String>> userIdToLeaveDates = new Map<Id, Map<Date, String>>();

        for(LeaveInFin.Leave leave : leaveToDaysThisWeek.keySet())
        {
            for(User user : users)
            {
                if(user.Email == leave.Employee_r.Email)
                {
                    Map<Date, String> dayToHalfDay = leaveToDaysThisWeek.get(leave);
                    for(Date day : dayToHalfDay.keySet())
                    {
                        if(userIdToLeaveDates.containsKey(user.Id))
                        {
                            userIdToLeaveDates.get(user.Id).put(day, dayToHalfDay.get(day));
                        }
                        else
                        {
                            Map<Date, String> newDayToHalfDay = new Map<Date, String>();
                            newDayToHalfDay.put(day, dayToHalfDay.get(day));
                            userIdToLeaveDates.put(user.Id, newDayToHalfDay);
                        }
                    }
                }
            }
        }
        return userIdToLeaveDates;
    }

    public List<User> getLeaveUsersThisWeek(Map<LeaveInFin.Leave, Map<Date, String>> leaveToDaysThisWeek)
    {
        Set<String> userEmails = new Set<String>();

        for(LeaveInFin.Leave leave : leaveToDaysThisWeek.keySet())
        {
            userEmails.add(leave.Employee_r.Email);
        }

        return [select Id, Name, Email from User where Email in :userEmails];
    }

    // gets leaves in this week.  key: leave value: key-> Date, value: halfday
    public Map<LeaveInFin.Leave, Map<Date, String>> getLeaveToDaysThisWeek(List<LeaveInFin.Leave> leaves)
    {
        Map<LeaveInFin.Leave, Map<Date,String>> leaveToDaysThisWeek = new Map<LeaveInFin.Leave, Map<Date, String>>();
        for(LeaveInFin.Leave leave : leaves)
        {
            if(leave.StartDate_c <= Date.today() && leave.EndDate_c >= Date.today().addDays(-6))
            {
                for(Integer i=0; i<=leave.StartDate_c.daysBetween(leave.EndDate_c); i++)
                {
                    if(leave.StartDate_c.addDays(i) >= Date.today().addDays(-6) && leave.StartDate_c.addDays(i) <= Date.today())
                    {
                        if(leaveToDaysThisWeek.containsKey(leave))
                        {
                            leaveToDaysThisWeek.get(leave).put(leave.StartDate_c.addDays(i), leave.HalfDay_c);
                        }
                        else
                        {
                            Map<Date, String> dayToHalfDay = new Map<Date, String>();
                            dayToHalfDay.put(leave.StartDate_c.addDays(i), leave.HalfDay_c);
                            leaveToDaysThisWeek.put(leave, dayToHalfDay);
                        }
                    }
                }
            }
        }
        return leaveToDaysThisWeek;
    }

    // gets user day hours in this week.  key: user Id, value: key:Date , value : hours
    public Map<Id, Map<Date, Decimal>> getUserIdToDaysHours(Set<Id> userIds)
    {
        Map<Id, Map<Date, Decimal>> userIdToDaysHours = new Map<Id, Map<Date, Decimal>>();
        for(AggregateResult aggResult : [select TeamMember__r.User__c u, sum(Hours__c) h, Date__c d from TimeCard__c where TeamMember__r.User__c in :userIds and Date__c <= :Date.today() and Date__c >= :Date.today().addDays(-6) group by TeamMember__r.User__c, Date__c])
        {
            if(userIdToDaysHours.containsKey((Id)aggResult.get('u')))
            {
                Map<Date, Decimal> dayToHours = userIdToDaysHours.get((Id)aggResult.get('u'));
                dayToHours.put((Date)aggResult.get('d'), (Decimal)aggResult.get('h'));
            }
            else
            {
                Map<Date, Decimal> dayToHours = new Map<Date, Decimal>();
                dayToHours.put((Date)aggResult.get('d'), (Decimal)aggResult.get('h'));
                userIdToDaysHours.put((Id)aggResult.get('u'), dayToHours);
            }
        }
        return userIdToDaysHours;
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