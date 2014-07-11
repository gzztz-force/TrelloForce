@isTest
public class EmployeeCreditTest
{
	@isTest
    static void testCallout()
    {
        TestDataFactory.createFinanceServerCustomSetting();

        Test.startTest();
        List<EmployeeCredit.Credit> credits = EmployeeCredit.getCredit('select Id from Credit__c');
        System.assert(credits != null);
        Test.stopTest();
    }

    @isTest
    static void testConstructor()
    {
        EmployeeCredit.Employee employee = new EmployeeCredit.Employee('test');
        EmployeeCredit.Credit credit = new EmployeeCredit.Credit('test');
    }
}