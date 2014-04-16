@isTest
public class EmployeeLeaveTest
{
    static testmethod void testCallout()
    {
        TestDataFactory.createFinanceServerCustomSetting();

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