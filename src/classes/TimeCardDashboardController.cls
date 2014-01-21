/*
* Controller for page TimeCardDashboard
* Test method in LogTimeCardControllerTest class
*/
public without sharing class TimeCardDashboardController 
{
    public TimeCardDashboardController() 
    {
        initData();
    }

    public List<String> TeamMemberHours { get; private set; }

    private void initData()
    {
        // ['Bruce Yue', 60, 19]
        TeamMemberHours = new List<String>();
        String firstRow = '[' + '\'Member\'' + ', ' + '\'Billable\'' + ', ' + '\'Non-Billable\'' + ']';
        TeamMemberHours.add(firstRow);
        Map<String, Decimal> teamMemberToBillableHoursMap = new Map<String, Decimal>();
        Map<String, Decimal> teamMemberToNonBillableHoursMap = new Map<String, Decimal>();
        List<AggregateResult> timeCards = [select sum(Hours__c), Billable__c b, TeamMember__r.Name m from TimeCard__c where  Date__c <= :Date.today() and Date__c >= :Date.today().addDays(-30) GROUP BY TeamMember__r.Name, Billable__c ORDER BY TeamMember__r.Name];
        for(AggregateResult result : timeCards)
        {
            if(result.get('b') == true)
            {
                teamMemberToBillableHoursMap.put((String)result.get('m'), (Decimal)result.get('expr0'));
            }
            if(result.get('b') == false)
            {
                teamMemberToNonBillableHoursMap.put((String)result.get('m'), (Decimal)result.get('expr0'));
            }
        }
        buildTeamMemberHoursList(teamMemberToBillableHoursMap, teamMemberToNonBillableHoursMap);
    }

    private void buildTeamMemberHoursList(Map<String, Decimal> teamMemberToBillableHoursMap, Map<String, Decimal> teamMemberToNonBillableHoursMap)
    {
        // Billed = ['allen', 10], ['aaron', 9], ['bruce', 9]
        // Nonbilled = ['allen', 8], ['jair, 10']
        // All = ['allen', 10, 8], ['aaron', 9, 0], ['bruce', 9, 0], ['jair, 0, 10]
        for(String bMember : teamMemberToBillableHoursMap.keySet())
        {
            String rowData = '[\'' + bMember + '\', ';
            rowData += teamMemberToBillableHoursMap.get(bMember);
            Decimal unbilledHours = teamMemberToNonBillableHoursMap.get(bMember) != null ? teamMemberToNonBillableHoursMap.get(bMember) : 0;
            rowData += ',' + unbilledHours;
            rowData += ']';
            TeamMemberHours.add(rowData);
        }
        for(String nMember : teamMemberToNonBillableHoursMap.keySet())
        {
            if(!teamMemberToBillableHoursMap.containsKey(nMember))
            {
                String rowData = '[\'' + nMember + '\', ';
                rowData += 0;
                rowData += ',' + teamMemberToNonBillableHoursMap.get(nMember);
                rowData += ']';
                TeamMemberHours.add(rowData);
            }
        }
    }
}