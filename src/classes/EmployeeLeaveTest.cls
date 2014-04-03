@isTest
public class EmployeeLeaveTest
{
	static void createData()
    {
        FinanceServer__c setting = new FinanceServer__c();
        setting.ClientId__c = '3MVG9_7ddP9KqTzdeUy2xmOr2N74sReSNZxQSX1g4ZCL8LMxMudc.PFIsdwEPIRM_4lEYiswlk7aUbw_8Jx5A';
        setting.ClientSecret__c = '1823320581773834609';
        setting.Endpoint__c = 'https://test.salesforce.com/services/oauth2/token';
        setting.Username__c = 'jair.zheng@fin.meginfo.com.sandbox';
        setting.Password__c = 'meginfo2008';

        insert setting;
    }

    static testmethod void testCallout()
    {
        createData();

        Test.startTest();

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockFinanceHttpResponseGenerator());
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        List<EmployeeLeave.Leave> leaves = EmployeeLeave.getLeaves('select Id from Leave__c');

        EmployeeLeave.createLeave(Date.today(), Date.today(), 'half day', 'employee id');

        EmployeeLeave.deleteLeave('leave id');

        Test.stopTest();
    }
}