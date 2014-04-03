@isTest
global class MockFinanceHttpResponseGenerator implements HttpCalloutMock
{
    private String queryResponse = '{"totalSize":1,"done":true,' +
                                        '"records":[{' +
                                            '"attributes":{' +
                                                '"type":"Leave__c",' +
                                                '"url":"/services/data/v22.0/sobjects/Leave__c/a07J0000006BFL3IAO"},' +
                                                    '"Id":"a07J0000006BFL3IAO",' +
                                                    '"StartDate__c":"2014-01-28",' +
                                                    '"EndDate__c":"2014-01-28",' +
                                                    '"HalfDay__c":null,' +
                                                    '"Employee__c":"005A0000001R7vFIAS",' +
                                                    '"Employee__r":{' +
                                                        '"attributes":{' +
                                                            '"type":"User",' +
                                                            '"url":"/services/data/v22.0/sobjects/User/005A0000001R7vFIAS"},' +
                                                                '"Name":"Jair Zheng",' +
                                                                '"Username":"jair.zheng@fin.meginfo.com.apex"}}]}';
    private String loginResponse = '{"id":"https://test.salesforce.com/id/00DJ0000002m03tMAA/005J0000001eNRjIAM",' +
                          '"issued_at":"1396428493905",' +
                          '"token_type":"Bearer",' +
                          '"instance_url":"https://cs10.salesforce.com",' +
                          '"signature":"VWbWqpTYtAYIR7zejrejbcExwn+M/PqKxyNrSJdw1Oc=",' +
                          '"access_token":"00DJ0000002m03t!ARsAQBOx7sM9zv9LJW0pGBES65qJbvcep6gDYHzbhokLdbXJWgija5SEDBNEX7UEsfhynzvHaX5GQj9_LLhAZ8cfgk5YZYrF"}';

    global HTTPResponse respond(HTTPRequest req)
    {
    	HttpResponse res = new HttpResponse();
        // Create a fake response
        res.setHeader('Content-Type', 'application/json');

        if(req.getBody().contains('query'))
        {
	        res.setBody(queryResponse);
        }
        else if(req.getBody().contains('username'))
        {
        	res.setBody(loginResponse);
        }
        else if(req.getBody().contains('delete'))
        {
        	res.setStatus('deleted');
        }
        else
        {
        	res.setStatus('created');
        }

        res.setStatusCode(200);

        return res;
	}
}