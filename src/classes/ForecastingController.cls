/*
 * Controller of page Forecasting
 */
public class ForecastingController
{
    public ForecastingController()
    {
        DateFrame = ApexPages.currentPage().getParameters().get('date');
        if(DateFrame == null || DateFrame == '')
        {
            DateFrame = 'ThisWeek';
            if(Date.today().toStartOfWeek().daysBetween(Date.today()) < 3)
            {
                //Default to 'LastWeek' before Wednesday
                DateFrame = 'LastWeek';
            }
        }
        String uid = ApexPages.currentPage().getParameters().get('uid');
        buildNavigation(uid);
        buildTeamMembers(uid);
    }

    public List<User> TeamMembers { get; set; }
    public String DateFrame { get; set; }
    public List<User> Navigations { get; set; }
    public User CurrentViewingUser
    {
        get
        {
            return (Navigations.size() > 0) ? Navigations[Navigations.size() - 1] : null;
        }
    }
    public Date StartDate
    {
        get
        {
            if(DateFrame == 'ThisWeek')
            {
                return Date.today().toStartOfWeek();
            }
            else if(DateFrame == 'LastWeek')
            {
                return Date.today().toStartOfWeek().addDays(-7);
            }
            else if(DateFrame == 'ThisMonth')
            {
                return Date.today().toStartOfMonth();
            }
            else if(DateFrame == 'LastMonth')
            {
                return Date.today().toStartOfMonth().addMonths(-1);
            }
            else if(DateFrame == 'ThisYear')
            {
                return Date.newInstance(Date.today().year(), 1, 1);
            }
            else if(DateFrame == 'LastYear')
            {
                return Date.newInstance(Date.today().year() - 1, 1, 1);
            }
            else
            {
                return Date.today();
            }
        }
    }

    public Date EndDate
    {
        get
        {
            if(DateFrame == 'ThisWeek')
            {
                return Date.today().toStartOfWeek().addDays(6);
            }
            else if(DateFrame == 'LastWeek')
            {
                return Date.today().toStartOfWeek().addDays(-1);
            }
            else if(DateFrame == 'ThisMonth')
            {
                return Date.today().toStartOfMonth().addMonths(1).addDays(-1);
            }
            else if(DateFrame == 'LastMonth')
            {
                return Date.today().toStartOfMonth().addDays(-1);
            }
            else if(DateFrame == 'ThisYear')
            {
                return Date.newInstance(Date.today().year() + 1, 1, 1).addDays(-1);
            }
            else if(DateFrame == 'LastYear')
            {
                return Date.newInstance(Date.today().year(), 1, 1).addDays(-1);
            }
            else
            {
                return Date.today();
            }
        }
    }

    @ReadOnly
    @RemoteAction
    public static ForecastingResult getUserForecasting(ForecastingParam param)
    {
        param.UserId = (param.UserId == null) ? UserInfo.getUserId() : param.UserId;
        List<Id> userIds = (param.RollupSummary) ? getTeamMemberIds(param.UserId) : new List<Id> { param.UserId };
        ForecastingResult forecasting = new ForecastingResult(param.UserId, param.StartDate, param.EndDate, param.RollupSummary);
        forecasting.ChangeCount = getChangesInvolved(userIds, param.StartDate, param.EndDate);
        forecasting.LoggedHours = getHoursLogged(userIds, param.StartDate, param.EndDate);
        forecasting.TimeByProjects = getTimeByProject(userIds, param.StartDate, param.EndDate);
        forecasting.TimeByCustomers = getTimeByCustomer(userIds, param.StartDate, param.EndDate);
        forecasting.Context = param.Context;
        return forecasting;
    }

    private static ChartTable getTimeByCustomer(List<Id> userIds, Date startDate, Date endDate)
    {
        ChartTable table = new ChartTable();
        for(AggregateResult aggregation : [select sum(Hours__c) h, Project__r.Customer__r.Name c from TimeCard__c where Date__c>=:startDate and Date__c<=:endDate and TeamMember__r.User__c in :userIds group by Project__r.Customer__r.Name])
        {
            String customer = (String)aggregation.get('c');
            Decimal hours = (Decimal)aggregation.get('h');
            hours = (hours == null) ? 0 : hours;
            table.addColumn(customer);
            table.addValue('Hours', customer, hours);
        }
        return table;
    }

    private static ChartTable getTimeByProject(List<Id> userIds, Date startDate, Date endDate)
    {
        ChartTable table = new ChartTable();
        for(AggregateResult aggregation : [select sum(Hours__c) h, Project__r.Name p from TimeCard__c where Date__c>=:startDate and Date__c<=:endDate and TeamMember__r.User__c in :userIds group by Project__r.Name order by Project__r.Name])
        {

            String project = (String)aggregation.get('p');
            Decimal hours = (Decimal)aggregation.get('h');
            hours = (hours == null) ? 0 : hours;
            table.addColumn(project);
            table.addValue('Hours', project, hours);
        }
        return table;
    }

    private static Integer getChangesInvolved(List<Id> userIds, Date startDate, Date endDate)
    {
        Integer count = [select count() from Change__c where Id in (select Change__c from TimeCard__c where Date__c>=:startDate and Date__c<=:endDate and TeamMember__r.User__c in :userIds)];
        return count;
    }

    private static Decimal getHoursLogged(List<Id> userIds, Date startDate, Date endDate)
    {
        List<AggregateResult> aggregate = [select sum(Hours__c) h from TimeCard__c where TeamMember__r.User__c in :userIds and Date__c>=:startDate and Date__c<=:endDate];
        Decimal result = (aggregate.size() > 0) ? (Decimal)aggregate[0].get('h') : 0;
        return (result == null) ? 0 : result;
    }

    public static List<Id> getTeamMemberIds(Id managerId)
    {
        Set<Id> userIds = new Set<Id>();
        Id viewForecastAs = null;
        userIds.add(managerId);
        if(managerId == UserInfo.getUserId())
        {
            User me = [select Id, ViewForecastAs__c from User where Id=:managerId limit 1];
            if(me.ViewForecastAs__c != null)
            {
                viewForecastAs = me.ViewForecastAs__c;
                userIds.add(viewForecastAs);
            }
        }
        while(true)
        {
            Integer oldSize = userIds.size();
            for(User member : [select Id from User where ManagerId in :userIds and IsActive=true and IsEmployee__c=1])
            {
                userIds.add(member.Id);
            }
            if(oldSize == userIds.size()) //no new users added
            {
                break;
            }
        }
        userIds.remove(viewForecastAs);
        List<Id> result = new List<Id>();
        result.addAll(userIds);
        return result;
    }

    private void buildNavigation(String uid)
    {
        List<User> temp = new List<User>();
        User me = [select Id, ViewForecastAs__c from User where Id=:UserInfo.getUserId() limit 1];
        if(uid == null || uid == '')
        {
            uid = (me.ViewForecastAs__c != null) ? me.ViewForecastAs__c : me.Id;
            temp.add([select Id, Name from User where Id=:me.Id limit 1]);
        }
        else
        {
            temp.add([select Id, Name from User where Id=:uid limit 1]);
        }

        while(uid != me.Id && uid != me.ViewForecastAs__c)
        {
            User usr = [select Id, Name, ManagerId from User where Id=:uid limit 1];
            uid = usr.ManagerId;
            if(uid == null)
            {
                break;
            }
            if(uid == me.ViewForecastAs__c)
            {
                temp.add([select Id, Name from User where Id=:me.Id limit 1]);
            }
            else
            {
                temp.add([select Id, Name from User where Id=:uid limit 1]);
            }
        }
        Navigations = new List<User>();
        for(Integer i = temp.size() - 1; i >= 0; i--)
        {
            Navigations.add(temp[i]);
        }
    }

    private void buildTeamMembers(String uid)
    {
        if(uid == null || uid == '')
        {
            uid = UserInfo.getUserId();
        }
        Set<Id> userIds = new Set<Id>();
        userIds.add(uid);
        if(uid instanceOf Id && (Id)uid == UserInfo.getUserId())
        {
            User me = [select Id, ViewForecastAs__c from User where Id=:uid limit 1];
            userIds.add(me.ViewForecastAs__c);
        }
        userIds.remove(null);
        TeamMembers = [select Id, Name from User where ManagerId in :userIds and Id not in :userIds and IsEmployee__c=1 and IsActive=true order by FirstName];
    }

    public class ForecastingParam
    {
        public Id UserId { get; set; }
        public Date StartDate { get; set; }
        public Date EndDate { get; set; }
        public Boolean RollupSummary { get; set; }
        public String Context { get; set; }
    }

    public class ForecastingResult
    {
        public ForecastingResult(Id userId, Date startDate, Date endDate, Boolean rollupSummary)
        {
            this.UserId = userId;
            this.StartDate = startDate;
            this.EndDate = endDate;
            this.RollupSummary = rollupSummary;
        }

        public Id UserId { get; set; }
        public Date StartDate { get; set; }
        public Date EndDate { get; set; }
        public Boolean RollupSummary { get; set; }
        public Integer ChangeCount { get; set; }
        public Decimal LoggedHours { get; set; }
        public ChartTable TimeByProjects { get; set; }
        public ChartTable TimeByCustomers { get; set; }
        public String Context { get; set; }
    }

    @isTest
    static void testForecastingController()
    {
        Profile p = [select Id from Profile where Name = 'Force.com - Developer'];
        UserRole r = [select Id, Name from UserRole where Name = 'Developer'];

        User user = TestDataFactory.newUser(p.Id, r.Id);
        insert user;

        MProject__c pro = TestDataFactory.generateSampleActiveProject('acme');
        insert pro;

        TeamMember__c member = TestDataFactory.generateSampleTeamMember(pro);
        insert member;

        TimeCard__c card = new TimeCard__c(Project__c=pro.Id, TeamMember__c=member.Id, Date__c=Date.today().toStartOfWeek().addDays(-1), Hours__c=3, Description__c='acme');
        insert card;

        ForecastingController controller = new ForecastingController();
        controller.DateFrame = 'LastWeek';
        System.assert(controller.TeamMembers.size() > 0);
        System.assert(controller.CurrentViewingUser != null);

        ForecastingParam param = new ForecastingParam();
        param.UserId = UserInfo.getUserId();
        param.StartDate = controller.StartDate;
        param.EndDate = controller.EndDate;
        param.RollupSummary = true;
        ForecastingResult result = ForecastingController.getUserForecasting(param);
        System.assertEquals(3, result.LoggedHours);
    }
}