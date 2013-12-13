/*
 * Controller of the component TimeCardAreaChart
 */
public class TimeCardAreaChartController 
{
    public Id ProjectId { get; set; }
    public String ChartType { get; set; } //'Day', 'Week', or 'Month' 
    public ChartBuilder Builder
    {
        get
        {
            if(ChartType == 'Month')
            {
                return new ChartBuilder(MonthlyTimeCards);
            }
            else if(ChartType == 'Week')
            {
                return new ChartBuilder(WeeklyTimeCards);
            }
            else
            {
                return new ChartBuilder(DailyTimeCards);
            }
        }
    }
    public ChartTable DailyTimeCards
    {
        get
        {
            ChartTable table = new ChartTable();
            Date startDate = Date.today().addDays(-10);
            for(Date d = startDate; d <= Date.today(); d = d.addDays(1))
            {
                String columnName = translateMonthName(d.month()) + ' ' + d.day();
                table.addColumn(columnName);
            }
            for(AggregateResult result : [select sum(Hours__c) h, TeamMember__r.Name u, Date__c d from TimeCard__c where TeamMember__r.Project__c=:ProjectId and Date__c>:startDate group by TeamMember__r.Name, Date__c order by Date__c, TeamMember__r.Name])
            {
                Decimal hours = (Decimal)result.get('h');
                String memberName = (String)result.get('u');
                Date d = (Date)result.get('d');
                String columnName = translateMonthName(d.month()) + ' ' + d.day();
                table.addValue(memberName, columnName, hours);
            }
            setRowVisibility(table);
            return table;
        }
    }
    
    public ChartTable WeeklyTimeCards
    {
        get
        {
            ChartTable table = new ChartTable();
            table.Cumulative = true;
            Date startDate = Date.today().addDays(-56).toStartOfWeek();
            for(Date d = startDate; d <= Date.today(); d = d.addDays(7))
            {
                table.addColumn(formatWeek(d));
            }
            for(AggregateResult result : [select sum(Hours__c) h, TeamMember__r.Name u, Date__c d from TimeCard__c where TeamMember__r.Project__c=:ProjectId and Date__c>:startDate group by TeamMember__r.Name, Date__c order by Date__c, TeamMember__r.Name])
            {
                Decimal hours = (Decimal)result.get('h');
                String memberName = (String)result.get('u');
                Date d = (Date)result.get('d');
                
                table.addValue(memberName, formatWeek(d), hours);
            }
            setRowVisibility(table);
            return table;
        }
    }
    
    public ChartTable MonthlyTimeCards
    {
        get
        {
            ChartTable table = new ChartTable();
            table.Cumulative = true;
            Date startDate = Date.today().addMonths(-5);
            for(Date d = Date.today().addMonths(-5); d <= Date.today(); d = d.addMonths(1))
            {
                table.addColumn(translateMonthName(d.month()));
            }
            for(AggregateResult result : [select sum(Hours__c) h, TeamMember__r.Name u, Date__c d from TimeCard__c where TeamMember__r.Project__c=:ProjectId and Date__c>:startDate group by TeamMember__r.Name, Date__c order by Date__c, TeamMember__r.Name])
            {
                Decimal hours = (Decimal)result.get('h');
                String memberName = (String)result.get('u');
                Date d = (Date)result.get('d');
                
                table.addValue(memberName, translateMonthName(d.month()), hours);
            }
            setRowVisibility(table);
            return table;
        }
    }
    
    private void setRowVisibility(ChartTable table)
    {
        Set<String> invisibleMembers = new Set<String>();
        for(TeamMember__c invisibleMember : [select Id, Name from TeamMember__c where Project__c=:ProjectId and User__r.IsActive=false])
        {
            invisibleMembers.add(invisibleMember.Name);
        }
        for(ChartTable.RowInfo row : table.Rows)
        {
            if(invisibleMembers.contains(row.PrimaryKey))
            {
                row.Visible = false;
            }
        }
    }
    
    //gets a string like 'Mar 1-7' or 'Feb 28-Mar6'
    private String formatWeek(Date d)
    {
        Date startOfWeek = d.toStartOfWeek();
        Date endOfWeek = startOfWeek.addDays(6);
        String result = translateMonthName(startOfWeek.month()) + ' ' + startOfWeek.day();
        if(startOfWeek.month() == endOfWeek.month())
        {
            result += '-' + endOfWeek.day();
        }
        else
        {
            result += '-' + translateMonthName(endOfWeek.month()) + ' ' + endOfWeek.day();
        }
        return result;
    }
    
    private String translateMonthName(Integer monthIndex)
    {
        String[] monthNames = new String[] { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
        return monthNames[monthIndex - 1];
    }
    
    @isTest
    static void testTimeCardAreaChartController()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        User u = [select Id, Name from User limit 1];
        TeamMember__c tm = new TeamMember__c(Project__c=prj.Id, User__c=u.Id, Name='acme');
        insert tm;
        TimeCard__c tc = new TimeCard__c(TeamMember__c=tm.Id, Project__c=prj.Id, Hours__c=8, Description__c='acme', Date__c=Date.today());
        insert tc;
        
        TimeCardAreaChartController controller = new TimeCardAreaChartController();
        controller.ProjectId = prj.Id;
        ChartTable table = controller.DailyTimeCards;
        table = controller.WeeklyTimeCards;
        table = controller.MonthlyTimeCards;
        ChartBuilder b = controller.Builder;
    }
}