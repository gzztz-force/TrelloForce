@isTest
public class EmployeeCreditTransactionTest
{
    @isTest
    static void testCallout()
    {
        TestDataFactory.createFinanceServerCustomSetting();

        Test.startTest();
        List<EmployeeCreditTransaction.CreditTransaction> creditTransactions = EmployeeCreditTransaction.getCreditTransaction('select Id from CreditTransaction__c');
        Test.stopTest();
    }

    @isTest
    static void testConstructor()
    {
        EmployeeCreditTransaction.CreditTransaction creditTransaction = new EmployeeCreditTransaction.CreditTransaction( 2, 'creditId', 'test', Date.today(), false, 'test');
	}

    @isTest
	static void testCreateCreditTransaction()
	{
        List<EmployeeCreditTransaction.CreditTransaction> creditTransactions = new List<EmployeeCreditTransaction.CreditTransaction>();
        EmployeeCreditTransaction.CreditTransaction creditTransaction = new EmployeeCreditTransaction.CreditTransaction( 2, 'creditId', 'test', Date.today(), false, 'test');
        creditTransactions.add(creditTransaction);
		EmployeeCreditTransaction.createCreditTransactions(creditTransactions);
	}
}