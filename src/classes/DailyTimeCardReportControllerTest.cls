@isTest(seeAllData=true)
public class DailyTimeCardReportControllerTest
{
    static testmethod void testDailyTimeCardReportController()
    {
        List<Id> userIds = new List<Id>();
        for(Change__c change : [select Id, AssignedTo__c from Change__c where Status__c != 'closed' and Status__c != 'Cancelled'])
        {
            userIds.add(change.AssignedTo__c);
        }

        List<AggregateResult> aggResults = [select TeamMember__r.User__c u, sum(Hours__c) h, Date__c d from TimeCard__c
                                         where TeamMember__r.User__c in :userIds and Date__c <= :Date.today() and Date__c >= :Date.today().addDays(-6)
                                          group by TeamMember__r.User__c, Date__c limit 1];

        DailyTimeCardReportController controller = new DailyTimeCardReportController();
        controller.UserId = String.valueOf(aggResults[0].get('u'));
        String name = controller.UserFullName;
        Decimal totalHours = controller.TotalHours;
        List<DailyTimeCardReportController.ChangeInfo> changes = controller.Changes;

        Test.startTest();
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockFinanceHttpResponseGenerator());
        ChartTable teamMembers = controller.MyMembers;
        Test.stopTest();
    }

}