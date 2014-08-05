@isTest
public class EmployeeCreditTest
{
	@isTest
    static void testCallout()
    {
        TestDataFactory.createFinanceServerCustomSetting();

        Test.startTest();
        List<EmployeeCredit.Credit> credits = EmployeeCredit.getCredit('select Id from Credit__c');
        Test.stopTest();
        System.assert(credits != null);
    }

    @isTest
    static void testConstructor()
    {
        EmployeeCredit.Employee employee = new EmployeeCredit.Employee('test');
        EmployeeCredit.Credit credit = new EmployeeCredit.Credit('test');
    }

    @isTest
    static void testGetData()
    {
        Map<String, String> allUser = new Map<String, String>();
        allUser.put('005A0000001R7vFIAS', 'jair.zheng@meginfo.com');
        Map<String, String> allCredit = EmployeeCredit.getCreditsInFin(allUser);
        System.assert(allCredit != null);
    }
}