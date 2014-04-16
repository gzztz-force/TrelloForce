/*
 * this controller used to correlate to custom component "DailyTimeCardReport".
 */
public class DailyTimeCardReportController
{
    private String userName;
    private Map<Id, String> userMap = new Map<Id, String>();
    private Map<String, Id> finUNToUserId = new Map<String, Id>();
    private Map<Id, String> userIdToFinUN = new Map<Id, String>();
    private List<User> teamUsers = new List<User>();

    public String UserId { get; set; }

    public String UserFullName
    {
        get
        {
            return userName;
        }
    }

    // Gets the total hour of today
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
            initUserData();

            if(String.isEmpty(UserId)) return new ChartTable();

            ChartTable table = generateBlankTable(userMap, UserId, teamUsers);

            // Gets user logged time cards in one week
            Map<Id, Map<Date, Decimal>> userIdToDaysHours = getUserIdToDaysHours(userMap.keySet());

            // Gets user leave info in Fin system in one week
            Map<Id, Map<Date, EmployeeLeave.LeaveType>> userIdToDaysLeaveTypes = getUserIdToDaysLeaveTypes(userIdToDaysHours);

            for(Id userId : userMap.keySet())
            {
                for(Integer i = 0; i > -7; i--)
                {
                    Date d = Date.today().addDays(i);

                    Decimal hours = (userIdToDaysHours.containsKey(userId) && userIdToDaysHours.get(userId).containsKey(Date.today().addDays(i))) ?
                                    userIdToDaysHours.get(userId).get(d) : 0;

                    EmployeeLeave.LeaveType leaveType = (userIdToDaysLeaveTypes.containsKey(userId) && userIdToDaysLeaveTypes.get(userId).containsKey(d)) ?
                                    userIdToDaysLeaveTypes.get(userId).get(d) : EmployeeLeave.LeaveType.NONE;

                    String imageName = getImageName(leaveType, hours);

                    table.addValue(userMap.get(userId), getDayOfWeek(d), new ChartTable.CellInfo(hours, leaveType.name(), imageName));
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
            for(Change__c change : [select Id, ChangeNumber__c, Name, OpenedBy__c, OpenedBy__r.Name, Type__c, Age__c,
                Estimate__c, DueDate__c, Status__c, AssignedTo__c, AssignedTo__r.Name, Priority__c, Project__c, Project__r.Name
                 from Change__c where AssignedTo__c = :UserId and Status__c not in ('Closed', 'Cancelled')
                 order by Project__r.Name, Status__c limit 100])
            {
                result.add(new ChangeInfo(change));
            }
            return result;
        }
    }

    private void initUserData()
    {
        teamUsers = getTeamUsers(UserId);

        for(User user : teamUsers)
        {
            userMap.put(user.Id, user.Name);
            finUNToUserId.put(user.FinUserName__c, user.Id);
            userIdToFinUN.put(user.Id, user.FinUserName__c);
        }

        userName = userMap.get(UserId);
    }

    // Get a table with a date header(7 days) and user name as first column of each row
    private static ChartTable generateBlankTable(Map<Id, String> userMap, String userId, List<User> teamUsers)
    {
        ChartTable table = new ChartTable(true); // Cumulative table

        for(Integer i = 0; i > -7; i--)
        {
            table.Columns.add(getDayOfWeek(Date.today().addDays(i)));
        }

        // Put current use as a first row
        table.addValue(userMap.get(userId), table.Columns[0], new ChartTable.CellInfo(0));

        for(User user : teamUsers)
        {
            if(user.Id != userId)
            {
                table.addValue(user.Name, table.Columns[0], new ChartTable.CellInfo(0));
            }
        }

        return table;
    }

    //returns the day of week of specified date, e.g. Tue 30
    private static String getDayOfWeek(Date d)
    {
        return DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEE d');
    }

    public static List<User> getTeamUsers(Id userId)
    {
        List<User> users = [select Id, UserRoleId, UserRole.ParentRoleId from User where Id=:userId limit 1];
        if(users.size() > 0)
        {
            Set<Id> teamRoles = new Set<Id>();
            teamRoles.addAll(getSubordinateRoles(users[0].UserRoleId));
            teamRoles.add(users[0].UserRole.ParentRoleId);
            return [select Id, Name, FinUserName__c from User where IsActive=true and IsEmployee__c=1 and UserRoleId in :teamRoles order by Name];
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

    // Gets user day hours in this week.  key: user Id, value: key:Date , value : hours
    public Map<Id, Map<Date, Decimal>> getUserIdToDaysHours(Set<Id> userIds)
    {
        Map<Id, Map<Date, Decimal>> userIdToDaysHours = new Map<Id, Map<Date, Decimal>>();
        for(AggregateResult aggResult : [select TeamMember__r.User__c u, sum(Hours__c) h, Date__c d from TimeCard__c
                                 where TeamMember__r.User__c in :userIds and Date__c <= :Date.today() and Date__c >= :Date.today().addDays(-6)
                                  group by TeamMember__r.User__c, Date__c])
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

    // Gets user leave info this week , key : userid  value : key: leave date  value : halfday
    public Map<Id, Map<Date, EmployeeLeave.LeaveType>> getUserIdToDaysLeaveTypes(Map<Id, Map<Date, Decimal>> userIdToDaysHours)
    {
        //Map<EmployeeLeave.Leave, Map<Date, String>> leaveToDaysLeaveTypes, List<User> leaveUsers
        Map<Id, Map<Date, EmployeeLeave.LeaveType>> userIdToDaysLeaveTypes = new Map<Id, Map<Date, EmployeeLeave.LeaveType>>();

        Set<Id> userIds = getUserMayLeaveIds(userIdToDaysHours, userMap);
        Set<String> leaveUserNames = new Set<String>();

        for(Id uId : userIds)
        {
            leaveUserNames.add(userIdToFinUN.get(uId));
        }
        List<EmployeeLeave.Leave> leaves = getLeavesInFin(leaveUserNames);

        for(EmployeeLeave.Leave leave : leaves)
        {
            Id userId = finUNToUserId.get(leave.Employee_r.UserName);

            for(Integer i=0; i <= leave.StartDate_c.daysBetween(leave.EndDate_c); i++)
            {
                EmployeeLeave.LeaveType leaveType = getLeaveType(leave.HalfDay_c);

                if(userIdToDaysLeaveTypes.containsKey(userId))
                {
                    userIdToDaysLeaveTypes.get(userId).put(leave.StartDate_c.addDays(i), leaveType);
                }
                else
                {
                    Map<Date, EmployeeLeave.LeaveType> dayToLeaveType = new Map<Date, EmployeeLeave.LeaveType>();
                    dayToLeaveType.put(leave.StartDate_c.addDays(i), leaveType);
                    userIdToDaysLeaveTypes.put(userId, dayToLeaveType);
                }
            }
        }

        return userIdToDaysLeaveTypes;
    }

    // Get user does not log time card or logged hours less than 4 hours
    // These users who need post to Fin system to check leave info
    private static Set<Id> getUserMayLeaveIds(Map<Id, Map<Date, Decimal>> userIdToDaysHours, Map<Id, String> userMap)
    {
        Set<Id> userMayLeaveIds = new Set<Id>();

        for(Id userId : userMap.keySet())
        {
            // User doesn't log any time cards in one week
            if(!userIdToDaysHours.containsKey(userId))
            {
                userMayLeaveIds.add(userId);
                continue;
            }

            Map<Date, Decimal> dateToHours = userIdToDaysHours.get(userId);
            for(Integer i = 0; i > -7; i--)
            {
                Date d = Date.today().addDays(i);
                Decimal oneDayhours = dateToHours.get(d);

                // User does not log time card for one day or logged hours less than 4 hours
                if(oneDayhours == null || oneDayhours < 4)
                {
                    userMayLeaveIds.add(userId);
                    break;
                }
            }
        }
        return userMayLeaveIds;
    }

    private static List<EmployeeLeave.Leave> getLeavesInFin(Set<String> leaveUserNames)
    {
        String todayStr = String.valueOf(Date.today());
        String sevenDaysAgo = String.valueOf(Date.today().addDays(-6));

        String soql = 'select Id, StartDate__c, EndDate__c, HalfDay__c, Employee__c, Employee__r.Name, Employee__r.UserName from Leave__c' +
                    ' where (StartDate__c <= ' + todayStr + ' or EndDate__c >= ' + sevenDaysAgo + ') and Employee__r.UserName in (';

        for(String userName : leaveUserNames)
        {
            if(String.isNotBlank(userName))
            {
                soql += '\'' + userName + '\',';
            }
        }

        soql = soql.removeEnd(',');

        soql += ')';

        return EmployeeLeave.getLeaves(soql);
    }

    public EmployeeLeave.LeaveType getLeaveType(String halfDay)
    {
        EmployeeLeave.LeaveType leaveType = EmployeeLeave.LeaveType.NONE;
        if(halfDay == null)
        {
            leaveType = EmployeeLeave.LeaveType.WHOLEDAY;
        }
        if(halfDay == EmployeeLeave.LeaveType.MORNING.name())
        {
            leaveType = EmployeeLeave.LeaveType.MORNING;
        }
        if(halfDay == EmployeeLeave.LeaveType.AFTERNOON.name())
        {
            leaveType = EmployeeLeave.LeaveType.AFTERNOON;
        }
        return leaveType;
    }

    public String getImageName(EmployeeLeave.LeaveType leaveType, Decimal hours)
    {
        String imageName = '';

        if(leaveType == EmployeeLeave.LeaveType.WHOLEDAY)
        {
            imageName = 'grayCircle.png';
        }
        else if(leaveType == EmployeeLeave.LeaveType.MORNING)
        {
            imageName = 'greenCircle-left-gray.png';
        }
        else if(leaveType == EmployeeLeave.LeaveType.AFTERNOON)
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
                Boolean isOpen = this.IsOpen;
                String dueDateColor = this.DueDateColor;
                String priorityColor = this.PriorityColor;
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
 }