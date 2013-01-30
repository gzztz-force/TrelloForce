/*
 * adds or removes a device token for iOS notification
 */
@RestResource(urlMapping = '/ios/*')
global with sharing class DeviceTokenResolver 
{
    @HttpGet
    global static String doGet()
    {
        RestRequest req = RestContext.request;
        return doGetHelper(req.params, req.requestURI);
    }
    
    global static String doGetHelper(Map<String, String> parameters, String url)
    {
        String userId = null;
        String tempUserId = parameters.get('userId');
        List<User> users = [select Id from User where Id = :tempUserId limit 1];
        if(users.size() > 0)
        {
            userId = users[0].Id;
        }
        String deviceToken = parameters.get('deviceToken');
        String deviceType = parameters.get('deviceType');
        deviceType = (String.isEmpty(deviceType)) ? 'ios' : deviceType;
        
        if(String.isNotEmpty(userId) && String.isNotEmpty(deviceToken))
        {
            List<MobileDevice__c> mobileDevices = [select Id from MobileDevice__c where UserId__c = :userId and DeviceToken__c = :deviceToken and DeviceType__c = :deviceType];
            String urlStatus = getUrlStatus(url);
            if(urlStatus.equals('add'))
            {
                if(mobileDevices.size() > 0)
                {
                    return 'OK';
                }
                else
                {
                    try
                    {
                        insert new MobileDevice__c(Name = getNameByName(UserInfo.getName()), UserId__c = userId, DeviceToken__c = deviceToken, DeviceType__c = deviceType);
                    }
                    catch(Exception ex)
                    {
                        return ex.getMessage();
                    }
                    
                    return 'OK';
                }
            }
            else if(urlStatus.equals('remove'))
            {
                if(mobileDevices.size() > 0)
                {
                    try
                    {
                        delete mobileDevices;
                    }
                    catch(Exception ex)
                    {
                        return ex.getMessage();
                    }
                    
                    return 'OK';
                }
                else
                {
                    return 'Specified Device Token Not Found.';
                }
            }
            else
            {
                return 'Unknown function.';
            }
        }
        else
        {
            return 'There are not enough parameters.';
        }
    }
    
    static String getNameByName(String name)
    {
        String fixedName = name + '%';
        List<MobileDevice__c> mobileDevices = [select Id from MobileDevice__c where Name like :fixedName];
        if(mobileDevices.size() > 0)
        {
            return name + mobileDevices.size();
        }
        return name;
    }
    
    static String getUrlStatus(String url)
    {
        String urlPath = url.toLowerCase();
        if(urlPath.contains('addtoken'))
        {
            return 'add';
        }
        else if(urlPath.contains('removetoken'))
        {
            return 'remove';
        }
        else
        {
            return 'unknown';
        }
    }
    
    @isTest
    static void testDeviceTokenResolver()
    {
        List<User> users = [select Id from User limit 3];
        Map<String, String> result1Map = new Map<String, String>();
        result1Map.put('userId', users[0].Id);
        result1Map.put('deviceToken', 'result1');
        result1Map.put('deviceType', 'ios');
        String result1 = doGetHelper(result1Map, 'https://na6.salesforce.com/services/apexrest/ios/addToken?userId=111&deviceToken=result1&deviceType=ios');
        System.assertEquals('OK', result1);
        
        String result5 = doGetHelper(result1Map, 'https://na6.salesforce.com/services/apexrest/ios/addToken?userId=111&deviceToken=result1&deviceType=ios');
        System.assertEquals('OK', result5);
        
        String result6 = doGetHelper(result1Map, 'https://na6.salesforce.com/services/apexrest/ios/abc?userId=111&deviceToken=result1&deviceType=ios');
        System.assertEquals('Unknown function.', result6);
        
        Map<String, String> result2Map = new Map<String, String>();
        result2Map.put('userd', users[0].Id);
        result2Map.put('deviceToken', 'result1');
        String result7 = doGetHelper(result2Map, 'https://na6.salesforce.com/services/apexrest/ios/addToken?userd=111&deviceToken=result1&deviceType=ios');
        System.assertEquals('There are not enough parameters.', result7);
        
        Map<String, String> result3Map = new Map<String, String>();
        result3Map.put('userId', users[1].Id);
        result3Map.put('deviceToken', 'result2');
        result3Map.put('name', 'xiao');
        result3Map.put('deviceType', 'ios');
        String result2 = doGetHelper(result3Map, 'https://cs1.salesforce.com/services/apexrest/ios/addToken?name=xiao&deviceToken=result2&userId=222&deviceType=ios');
        System.assertEquals('OK', result2);
        
        Map<String, String> result4Map = new Map<String, String>();
        result4Map.put('userId', users[2].Id);
        result4Map.put('deviceToken', 'result3');
        result4Map.put('deviceType', 'ios');
        String result3 = doGetHelper(result4Map, 'https://cs1.salesforce.com/services/apexrest/ios/removeToken?userId=333&deviceToken=result3&deviceType=ios');
        System.assertEquals('Specified Device Token Not Found.', result3);
        
        String result4 = doGetHelper(result1Map, 'https://cs1.salesforce.com/services/apexrest/ios/removeToken?userId=111&deviceToken=result1&deviceType=ios');
        System.assertEquals('OK', result4);
    }
}