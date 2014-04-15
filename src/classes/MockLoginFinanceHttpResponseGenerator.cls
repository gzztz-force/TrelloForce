@isTest
global class MockLoginFinanceHttpResponseGenerator implements HttpCalloutMock
{
	String loginResponse = '{"id":"https://test.salesforce.com/id/00DJ0000002m03tMAA/005J0000001eNRjIAM",' +
	                         '"issued_at":"1397459165675",' +
	                         '"instance_url":"https://cs10.salesforce.com",' +
	                         '"signature":"u02/zNWN3LLwKwusOerZ+lBC2v3rhjCry0m/w6hIH8M=",' +
	                         '"access_token":"00DJ0000002m03t!ARsAQHmVy64JksEwtcM1qoAhYMVlyTTvn9vQWpwOVEaYgzbuunDgndyct.USG04uWlO9MpLY3W1l2fJ0PbMTClHi5uFb2Gk_"}';
	global HTTPResponse respond(HTTPRequest req)
    {
    	HttpResponse res = new HttpResponse();
        // Create a fake response
        res.setHeader('Content-Type', 'application/json');
        res.setBody(loginResponse);
        res.setStatusCode(200);

        return res;
	}
}