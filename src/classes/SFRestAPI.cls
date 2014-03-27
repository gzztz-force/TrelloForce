public class SFRestAPI
{
    public static OAuth2 login()
    {
        OAuth2 oauth;
        //Here write a sample query or fetch from custom settings the consumer ,client secret and username and password of destination org
        String requestBody = 'grant_type=password&client_id=' + FinanceServer__c.getInstance().ClientId__c +
                             '&client_secret=' + FinanceServer__c.getInstance().ClientSecret__c +
                             '&username=' + FinanceServer__c.getInstance().Username__c +
                             '&password=' + FinanceServer__c.getInstance().Password__c;

        HttpRequest request = new HttpRequest();
        request.setBody(requestBody);
        request.setMethod('POST');
        request.setEndpoint(FinanceServer__c.getInstance().EndPoint__c);//Note if my domain is set up use the proper domain name else use login.salesforce.com for prod or developer or test.salesforce.com for sandbox instance
        HttpResponse response = (new Http()).send(request);

        OAuth2 objAuthenticationInfo = (OAuth2)JSON.deserialize(response.getbody(), OAuth2.class);

        if(String.isBlank(objAuthenticationInfo.access_token) || String.isBlank(objAuthenticationInfo.instance_url))
        {
            throw new LoginException('Login failed!');
            oauth = null;
        }
        else
        {
            oauth = objAuthenticationInfo;
        }

        return oauth;
    }

    public static HttpResponse query(String q)
    {
        OAuth2 oauth = login();

        HttpResponse response;
        if(oauth != null)
        {
            PageReference theUrl = new PageReference(oauth.instance_url + '/services/data/v22.0/query/');

            theUrl.getParameters().put('q', q);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(theUrl.getUrl());
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + oauth.access_token);

            response = (new Http()).send(request);
        }

        return response;
    }

    public static void create(String sObj, String jsonBody)
    {
        OAuth2 oauth = login();
        if(oauth != null)
        {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(oauth.instance_url + '/services/data/v20.0/sobjects/' + sObj + '/');
            request.setMethod('POST');
            request.setBody(jsonBody);
            request.setHeader('Authorization', 'Bearer ' + oauth.access_token);
            request.setHeader('Content-Type', 'application/json');
            (new Http()).send(request);
        }
    }

    public static void del(String sObj, String id)
    {
        OAuth2 oauth = login();
        if(oauth != null)
        {
            HttpRequest request = new HttpRequest();

            request.setEndpoint(oauth.instance_url + '/services/data/v20.0/sobjects/' + sObj + '/' + id);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + oauth.access_token);
            (new Http()).send(request);
        }
    }

    //To get aouthentication detail Wrapper
    public class OAuth2
    {
        public String id { get; set; }
        public String issued_at { get; set; }
        public String instance_url { get; set; }
        public String signature { get; set; }
        public String access_token { get; set; }
    }

    public class LoginException extends Exception{}
}