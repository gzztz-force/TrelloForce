/*
 * this controller used to correlate to custom component "DailyTimeCardReport".
 */
public class DailyTimeCardReportController
{
    private String userName = '';

    public String UserId { get; set; }

    public String UserFullName
    {
        get
        {
            List<User> users = [select Id, Name from User where Id=:UserId limit 1];
            if(users.size() > 0)
            {
                userName = users[0].Name;
            }
            return userName;
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
            table.addValue(userName, table.Columns[0], new ChartTable.CellInfo(0));
            if(String.isNotEmpty(UserId))
            {
                for(User user : getTeamUsers(UserId))
                {
                    userMap.put(user.Id, user.Name);
                    if(user.Name != userName)
                    {
                        table.addValue(user.Name, table.Columns[0], new ChartTable.CellInfo(0));
                    }
                }

                Map<EmployeeLeave.Leave, Map<Date, String>> leaveToDaysLeaveTypes = getLeaveToDaysLeaveTypes(EmployeeLeave.getAllLeaves());
                List<User> users = getLeaveUsers(leaveToDaysLeaveTypes);
                Map<Id, Map<Date, String>> userIdToDaysLeaveTypes = getUserIdToDaysLeaveTypes(leaveToDaysLeaveTypes, users);
                Map<Id, Map<Date, Decimal>> userIdToDaysHours = getUserIdToDaysHours(userMap.keySet());

                for(Id userId : userMap.keySet())
                {
                    String imageName = '';
                    for(Integer i = 0; i > -7; i--)
                    {
                        Date d = Date.today().addDays(i);
                        if(userIdToDaysLeaveTypes.containsKey(userId) && userIdToDaysLeaveTypes.get(userId).containsKey(d))
                        {
                            String leaveType = userIdToDaysLeaveTypes.get(userId).get(d);

                            if(userIdToDaysHours.containsKey(userId) && userIdToDaysHours.get(userId).containsKey(Date.today().addDays(i)))
                            {
                                Decimal hours = userIdToDaysHours.get(userId).get(d);

                                imageName = getImageName(leaveType, hours);
                                table.addValue(userMap.get(userId), getDayOfWeek(d), new ChartTable.CellInfo(hours, leaveType, imageName));
                            }
                            else
                            {
                                imageName = getImageName(leaveType, 0);
                                table.addValue(userMap.get(userId), getDayOfWeek(d), new ChartTable.CellInfo(0, leaveType, imageName));
                            }
                        }
                        else
                        {
                            if(userIdToDaysHours.containsKey(userId) && userIdToDaysHours.get(userId).containsKey(Date.today().addDays(i)))
                            {
                                Decimal hours = userIdToDaysHours.get(userId).get(d);
                                String leaveType = EmployeeLeave.LeaveType.NONE.name();

                                imageName = getImageName(leaveType, hours);
                                table.addValue(userMap.get(userId), getDayOfWeek(d), new ChartTable.CellInfo(hours, leaveType, imageName));
                            }
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
    public Map<Id, Map<Date, String>> getUserIdToDaysLeaveTypes(Map<EmployeeLeave.Leave, Map<Date, String>> leaveToDaysLeaveTypes, List<User> leaveUsers)
    {
        Map<Id, Map<Date, String>> userIdToDaysLeaveTypes = new Map<Id, Map<Date, String>>();

        for(EmployeeLeave.Leave leave : leaveToDaysLeaveTypes.keySet())
        {
            for(User user : leaveUsers)
            {
                if(user.Email == leave.Employee_r.Email)
                {
                    Map<Date, String> dayToLeaveType = leaveToDaysLeaveTypes.get(leave);
                    for(Date day : dayToLeaveType.keySet())
                    {
                        if(userIdToDaysLeaveTypes.containsKey(user.Id))
                        {
                            userIdToDaysLeaveTypes.get(user.Id).put(day, dayToLeaveType.get(day));
                        }
                        else
                        {
                            Map<Date, String> newDayToLeaveType = new Map<Date, String>();
                            newDayToLeaveType.put(day, dayToLeaveType.get(day));
                            userIdToDaysLeaveTypes.put(user.Id, newDayToLeaveType);
                        }
                    }
                }
            }
        }
        return userIdToDaysLeaveTypes;
    }

    public List<User> getLeaveUsers(Map<EmployeeLeave.Leave, Map<Date, String>> leaveToDaysLeaveTypes)
    {
        Set<String> userEmails = new Set<String>();

        for(EmployeeLeave.Leave leave : leaveToDaysLeaveTypes.keySet())
        {
            userEmails.add(leave.Employee_r.Email);
        }

        return [select Id, Name, Email from User where Email in :userEmails];
    }

    // gets leaves in this week.  key: leave value: key-> Date, value: halfday
    public Map<EmployeeLeave.Leave, Map<Date, String>> getLeaveToDaysLeaveTypes(List<EmployeeLeave.Leave> leaves)
    {
        Map<EmployeeLeave.Leave, Map<Date, String>> leaveToDaysLeaveTypes = new Map<EmployeeLeave.Leave, Map<Date, String>>();
        for(EmployeeLeave.Leave leave : leaves)
        {
            if(leave.StartDate_c <= Date.today() && leave.EndDate_c >= Date.today().addDays(-6))
            {
                String leaveType = getLeaveType(leave.HalfDay_c);

                for(Integer i=0; i<=leave.StartDate_c.daysBetween(leave.EndDate_c); i++)
                {
                    if(leave.StartDate_c.addDays(i) >= Date.today().addDays(-6) && leave.StartDate_c.addDays(i) <= Date.today())
                    {
                        if(leaveToDaysLeaveTypes.containsKey(leave))
                        {
                            leaveToDaysLeaveTypes.get(leave).put(leave.StartDate_c.addDays(i), leaveType);
                        }
                        else
                        {
                            Map<Date, String> dayToLeaveType = new Map<Date, String>();
                            dayToLeaveType.put(leave.StartDate_c.addDays(i), leaveType);
                            leaveToDaysLeaveTypes.put(leave, dayToLeaveType);
                        }
                    }
                }
            }
        }
        return leaveToDaysLeaveTypes;
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

    public String getLeaveType(String halfDay)
    {
        String leaveType = EmployeeLeave.LeaveType.NONE.name();
        if(halfDay == null)
        {
            leaveType = EmployeeLeave.LeaveType.WHOLEDAY.name();
        }
        if(halfDay == 'Morning')
        {
            leaveType = EmployeeLeave.LeaveType.MORNING.name();
        }
        if(halfDay == 'Afternoon')
        {
            leaveType = EmployeeLeave.LeaveType.AFTERNOON.name();
        }
        return leaveType;
    }

    public String getImageName(String leaveType, Decimal hours)
    {
        String imageName = '';

        if(leaveType == 'WHOLEDAY')
        {
            imageName = 'grayCircle.png';
        }
        else if(leaveType == 'MORNING')
        {
            imageName = 'greenCircle-left-gray.png';
        }
        else if(leaveType == 'AFTERNOON')
        {
            imageName = 'greenCircle-right-gray.png';
        }
        else
        {
            if(hours >= 6)
            {
                imageName = 'greenCircle.png';
            }
            else if(hours >= 4)
            {
                imageName = 'yellowCircle.png';
            }
            else
            {
                imageName = 'redCircle.png';
            }
        }
        return imageName;
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
        String name = controller.userName;
        System.assert(controller.TotalHours != -1);
        System.assert(controller.MyMembers != null);
        System.assert(controller.Changes != null);
    }
}