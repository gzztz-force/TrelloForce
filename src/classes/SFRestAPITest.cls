@isTest
public class SFRestAPITest
{

    static testmethod void testLogin()
    {
    	TestDataFactory.createFinanceServerCustomSetting();

    	Test.startTest();

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockLoginFinanceHttpResponseGenerator());
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        SFRestAPI.OAuth2 oauth = SFRestAPI.login();

        Test.stopTest();
    }
}