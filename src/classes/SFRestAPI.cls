public class SFRestAPI
{
    private static OAuth2 oauth;

    public static HttpResponse query(String q)
    {
        if(oauth == null)
        {
            oauth = Test.isRunningTest()?testLogin():login();
        }

        HttpResponse response;
        HttpRequest request = new HttpRequest();

        PageReference theUrl = new PageReference(oauth.Instance_Url + '/services/data/v22.0/query/');
        theUrl.getParameters().put('q', q);

        request.setEndpoint(theUrl.getUrl());
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + oauth.Access_Token);
        if(Test.isRunningTest())
        {
            String queryResponse = '{"totalSize":1,"done":true,' +
                                        '"records":[{' +
                                            '"attributes":{' +
                                                '"type":"Credit__c",' +
                                                '"url":"/services/data/v22.0/sobjects/Credit__c/a07J0000006BFL3IAO"},' +
                                                    '"Id":"a07J0000006BFL3IAO",' +
                                                    '"Balance__c":"0",' +
                                                    '"Employee__r":{' +
                                                        '"attributes":{' +
                                                            '"type":"User",' +
                                                            '"url":"/services/data/v22.0/sobjects/User/005A0000001R7vFIAS"},' +
                                                                '"Name":"Jair Zheng",' +
                                                                '"Email":"jair.zheng@meginfo.com"}}]}';

            response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(queryResponse);
            response.setStatusCode(200);
        }
        else
        {
           response = (new Http()).send(request);
        }

        return response;
    }

    public static void create(String sObj, String jsonBody)
    {
        if(oauth == null)
        {
            oauth = Test.isRunningTest()?testLogin():login();
        }

        HttpRequest request = new HttpRequest();

        request.setEndpoint(oauth.Instance_Url + '/services/data/v20.0/sobjects/' + sObj + '/');
        request.setMethod('POST');
        request.setBody(jsonBody);
        request.setHeader('Authorization', 'Bearer ' + oauth.Access_Token);
        request.setHeader('Content-Type', 'application/json');
        if(Test.isRunningTest())
        {

        }
        else
        {
            (new Http()).send(request);
        }
    }

    public static void del(String sObj, String id)
    {
        if(oauth == null)
        {
            oauth = Test.isRunningTest()?testLogin():login();
        }

        HttpRequest request = new HttpRequest();

        request.setEndpoint(oauth.Instance_Url + '/services/data/v20.0/sobjects/' + sObj + '/' + id);
        request.setMethod('DELETE');
        request.setHeader('Authorization', 'Bearer ' + oauth.Access_Token);

        (new Http()).send(request);
    }

    public static OAuth2 login()
    {
        FinanceServer__c financeServer = FinanceServer__c.getInstance();

        //Here write a sample query or fetch from custom settings the consumer ,client secret and username and password of destination org
        String requestBody = 'grant_type=password&client_id=' + financeServer.ClientId__c +
                             '&client_secret=' + financeServer.ClientSecret__c +
                             '&username=' + financeServer.Username__c +
                             '&password=' + financeServer.Password__c;

        HttpRequest request = new HttpRequest();
        request.setBody(requestBody);
        request.setMethod('POST');
        request.setEndpoint(financeServer.EndPoint__c);//Note if my domain is set up use the proper domain name else use login.salesforce.com for prod or developer or test.salesforce.com for sandbox instance

        HttpResponse response = (new Http()).send(request);

        OAuth2 objAuth = (OAuth2)JSON.deserialize(response.getbody(), OAuth2.class);

        if(String.isBlank(objAuth.Access_Token) || String.isBlank(objAuth.Instance_Url))
        {
            oauth = null;
        }
        else
        {
            oauth = objAuth;
        }
        return oauth;
    }

    private static OAuth2 testLogin()
    {
        oauth = new OAuth2();
        oauth.Access_Token = 'test token';
        oauth.Instance_Url = 'http://acme.com';

        return oauth;
    }

    //To get aouthentication detail Wrapper
    public class OAuth2
    {
        public String Id { get; set; }
        public String Issued_At { get; set; }
        public String Instance_Url { get; set; }
        public String Signature { get; set; }
        public String Access_Token { get; set; }
    }

    public class LoginException extends Exception{}
}