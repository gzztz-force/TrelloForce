public with sharing class EmployeeLeave
{
	private static final String clientId = '3MVG9_7ddP9KqTzdeUy2xmOr2N74sReSNZxQSX1g4ZCL8LMxMudc.PFIsdwEPIRM_4lEYiswlk7aUbw_8Jx5A';
    private static final String clientSecret = '1823320581773834609';
    private static final String username = 'jair.zheng@fin.meginfo.com.sandbox';
    private static final String password = 'meginfo2008';

    public static OAuth2 login()
    {
        OAuth2 oauth;
        //Here write a sample query or fetch from custom settings the consumer ,client secret and username and password of destination org
        String requestBody = 'grant_type=password&client_id=' + clientId + '&client_secret=' + clientSecret + 
                             '&username=' + username + '&password=' + password;

        HttpRequest request = new HttpRequest();
        request.setBody(requestBody);
        request.setMethod('POST');
        request.setEndpoint('https://test.salesforce.com/services/oauth2/token');//Note if my domain is set up use the proper domain name else use login.salesforce.com for prod or developer or test.salesforce.com for sandbox instance
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

    public static List<Leave> getAllLeaves()
    {
        List<Leave> leaves;
        OAuth2 oauth = login();

        if(oauth != null)
        {
            Date upperLimit = Date.today();
            Date lowerLimit = Date.today().addDays(-6);
            PageReference theUrl = new PageReference(oauth.instance_url + '/services/data/v22.0/query/');

            theUrl.getParameters().put('q', 'select Id, StartDate__c, EndDate__c, HalfDay__c, Employee__r.Name, Employee__r.Email from Leave__c');
            HttpRequest request = new HttpRequest();
            request.setEndpoint(theUrl.getUrl());
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + oauth.access_token);

            HttpResponse response = (new Http()).send(request);
            System.debug('@@@query: ' + response.getBody());
            String body = replaceCustomFieldSuffix(response.getBody());
            JSONParser parser = JSON.createParser(replaceRelationFieldSuffix(body));

            do
            {
                parser.nextToken();
            }
            while(parser.hasCurrentToken() && !'records'.equals(parser.getCurrentName()));

            parser.nextToken();

            leaves = (List<Leave>) parser.readValueAs(List<Leave>.class);
        }
        return leaves;
    }

    public static void createLeave()
    {
        OAuth2 oauth = login();
        if(oauth != null)
        {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(oauth.instance_url + '/services/data/v20.0/sobjects/Leave__c/');
            request.setMethod('POST');
            request.setBody('{ "StartDate__c" : "2014-3-17", "EndDate__c": "2014-3-17", "Employee__c" : "005J0000001eNRj"}');
            request.setHeader('Authorization', 'Bearer ' + oauth.access_token);
            request.setHeader('Content-Type', 'application/json');
            HttpResponse response = (new Http()).send(request);

            System.debug('@@@create: ' + response.getBody());
        }
    }

    public static void deleteLeave(String leaveId)
    {
        OAuth2 oauth = login();
        if(oauth != null)
        {
            HttpRequest request = new HttpRequest();

            request.setEndpoint(oauth.instance_url + '/services/data/v20.0/sobjects/Leave__c/' + leaveId);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + oauth.access_token);
            (new Http()).send(request);
        }
    }

    private static String replaceCustomFieldSuffix(String body)
    {
        //regex not thoroughly tested
        return body.replaceAll('_c"\\s*:', 'c" :');
    }

    private static String replaceRelationFieldSuffix(String body)
    {
        return body.replaceAll('_r"\\s*:', 'r" :');
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

    public class Leave
    {
        public String Id { get; set; }
        public Date StartDate_c { get; set; }
        public Date EndDate_c { get; set; }
        public String HalfDay_c { get; set; }
        public Employee Employee_r { get; set; }
    }

    public class Employee
    {
        public String Name { get; set; }
        public String Email { get; set; }
    }

    public class LoginException extends Exception{}

    public enum LeaveType { NONE, MORNING, AFTERNOON, WHOLEDAY }
}