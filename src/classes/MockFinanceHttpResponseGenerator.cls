@isTest
global class MockFinanceHttpResponseGenerator implements HttpCalloutMock
{
    String startDate = String.valueOf(Date.today());
    String endDate = String.valueOf(Date.today());

    String startDate1 = String.valueOf(Date.today().addDays(-1));
    String endDate1 = String.valueOf(Date.today().addDays(-1));

    String startDate2 = String.valueOf(Date.today().addDays(-2));
    String endDate2 = String.valueOf(Date.today().addDays(-2));



    private String queryResponse = '{"totalSize":3,"done":true,' +
                                        '"records":[{' +
                                            '"attributes":{' +
                                                '"type":"Leave__c",' +
                                                '"url":"/services/data/v22.0/sobjects/Leave__c/a07J0000006BFL3IAO"},' +
                                                    '"Id":"a07J0000006BFL3IAO",' +
                                                    '"StartDate__c":"' + startDate +'",' +
                                                    '"EndDate__c":"' + endDate + '",' +
                                                    '"HalfDay__c":null,' +
                                                    '"Employee__r":{' +
                                                        '"attributes":{' +
                                                            '"type":"User",' +
                                                            '"url":"/services/data/v22.0/sobjects/User/005A0000001R7vFIAS"},' +
                                                                '"Name":"Jair Zheng",' +
                                                                '"Username":"jair.zheng@fin.meginfo.com.apex"}},' +
                                            '{"attributes":{' +
                                                '"type":"Leave__c",' +
                                                '"url":"/services/data/v22.0/sobjects/Leave__c/a07J0000006uPjuIAE"},' +
                                                    '"Id":"a07J0000006uPjuIAE",' +
                                                    '"StartDate__c":"' + startDate1 + '",' +
                                                    '"EndDate__c":"' + endDate1 + '",' +
                                                    '"HalfDay__c":"Morning",' +
                                                    '"Employee__r":{' +
                                                        '"attributes":{' +
                                                            '"type":"User",' +
                                                            '"url":"/services/data/v22.0/sobjects/User/005A0000001R7vFIAS"},' +
                                                            '"Username":"jair.zheng@fin.meginfo.com.apex"}},' +
                                            '{"attributes":{' +
                                                '"type":"Leave__c",' +
                                                '"url":"/services/data/v22.0/sobjects/Leave__c/a07J0000006uU2jIAE"},' +
                                                    '"Id":"a07J0000006uU2jIAE",' +
                                                    '"StartDate__c":"' + startDate2 + '",' +
                                                    '"EndDate__c":"' + endDate2 + '",' +
                                                    '"HalfDay__c":"Afternoon",' +
                                                    '"Employee__r":{' +
                                                        '"attributes":{' +
                                                            '"type":"User",' +
                                                            '"url":"/services/data/v22.0/sobjects/User/005A0000001R7vFIAS"},' +
                                                            '"Username":"jair.zheng@fin.meginfo.com.apex"}}]}';

    global HTTPResponse respond(HTTPRequest req)
    {
    	HttpResponse res = new HttpResponse();
        // Create a fake response
        res.setHeader('Content-Type', 'application/json');
        res.setBody(queryResponse);
        res.setStatusCode(200);

        return res;
	}
}