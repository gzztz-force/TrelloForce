/*
 * Base class for mobile notification. IOS and android service are potential inheritence.
 */
public abstract class MobileNotificationService
{
    private static final String PASSWORD = '123456';
    
    public abstract void push(List<Change__c> oldChanges, List<Change__c> newChanges);
    public abstract void pushNotification(NotificationInfo notification);
    public abstract Map<String, List<String>> getUserId2DeviceTokensByUserIds(Set<Id> userIds);
    
    @future(callout = true)
    public static void sendHttpCalloutInFuture(String endpoint, String body)
    {
        sendHttpCallout(endpoint, body);
    }
    
    public static void sendHttpCallout(String endpoint, String body)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setBody(body);
        System.debug('###body: ' + body);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug('###response: ' + response.getBody());
    }
    
    public static Map<String, List<String>> getUserId2DeviceTokensByUserIdsAndType(Set<Id> userIds, String deviceType)
    {
        Map<String, List<String>> userId2DeviceTokens = new Map<String, List<String>>();
        for(MobileDevice__c mobileDevice : [select Id, UserId__c, DeviceToken__c from MobileDevice__c where UserId__c in :userIds and DeviceType__c = :deviceType])
        {
            if(userId2DeviceTokens.containsKey(mobileDevice.UserId__c))
            {
                userId2DeviceTokens.get(mobileDevice.UserId__c).add(mobileDevice.DeviceToken__c);
            }
            else
            {
                userId2DeviceTokens.put(mobileDevice.UserId__c, new List<String>{ mobileDevice.DeviceToken__c });
            }
        }
        return userId2DeviceTokens;
    }
    
    public static Map<Id, List<Id>> getParentId2UserIdsByParentIds(Set<Id> parentIds)
    {
        Map<Id, List<Id>> parentId2UserIds = new Map<Id, List<Id>>();
        for(EntitySubscription entitySubscription : [select Id, ParentId, SubscriberId from EntitySubscription where ParentId in :parentIds and SubscriberId != :UserInfo.getUserId()])
        {
            if(parentId2UserIds.containsKey(entitySubscription.ParentId))
            {
                parentId2UserIds.get(entitySubscription.ParentId).add(entitySubscription.SubscriberId);
            }
            else
            {
                parentId2UserIds.put(entitySubscription.ParentId, new List<Id>{ entitySubscription.SubscriberId });
            }
        }
        return parentId2UserIds;
    }
    
    public static Map<Id, List<String>> getParentId2DeviceTokens(Map<Id, List<Id>> parentId2UserIds, Map<String, List<String>> userId2DeviceTokens)
    {
        Map<Id, List<String>> parentId2DeviceTokens = new Map<Id, List<String>>();
        for(Id parentId : parentId2UserIds.keySet())
        {
            for(Id userId : parentId2UserIds.get(parentId))
            {
                if(userId2DeviceTokens.containsKey(userId))
                {
                    if(parentId2DeviceTokens.containsKey(parentId))
                    {
                        parentId2DeviceTokens.get(parentId).addAll(userId2DeviceTokens.get(userId));
                    }
                    else
                    {
                        parentId2DeviceTokens.put(parentId, userId2DeviceTokens.get(userId));
                    }
                }
            }
        }
        return parentId2DeviceTokens;
    }
    
    private static Boolean valueIsChanged(sObject oldObject, sObject newObject, String fieldName)
    {
        return oldObject.get(fieldName) != newObject.get(fieldName);
    }
    
    private static String composePrefixOfChangeMessage(Change__c change)
    {
        List<MProject__c> projects = [select Name from MProject__c where Id = :change.Project__c limit 1];
        if(projects.size() > 0)
        {
            return 'Change: \"' + change.Name + '\" in Project: \"' + projects[0].Name + '\"';
        }
        return '';
    }
    
    public static Map<Id, Change__c> getChangeId2Change(List<Change__c> changes)
    {
        Map<Id, Change__c> changeId2Change = new Map<Id, Change__c>();
        for(Change__c change : changes)
        {
            changeId2Change.put(change.Id, change);
        }
        return changeId2Change;
    }

    public static String composeChangeMessage(Change__c oldChange, Change__c newChange)
    {
        Map<String, String> fieldLabel2FieldName = new Map<String, String>();
        fieldLabel2FieldName.put('Name', 'Subject');
        fieldLabel2FieldName.put('AssignedTo__c', 'Owner');
        fieldLabel2FieldName.put('DueDate__c', 'Due Date');
        fieldLabel2FieldName.put('Estimate__c', 'Estimate');
        fieldLabel2FieldName.put('Priority__c', 'Priority');
        fieldLabel2FieldName.put('Status__c', 'Status');
        fieldLabel2FieldName.put('Description__c', 'Description');
        fieldLabel2FieldName.put('Type__c', 'Type');
        
        List<String> changedFieldNames = new List<String>();
        for(String fieldName : fieldLabel2FieldName.keySet())
        {
            if(valueIsChanged(oldChange, newChange, fieldName))
            {
                changedFieldNames.add(fieldLabel2FieldName.get(fieldName));
            }
        }
        return composePrefixOfChangeMessage(oldChange) + ' has been changed with following field(s): { ' + String.join(changedFieldNames, ', ').removeEnd(', ') + ' }.';
    }
            
    public static String composeChangeBackgroundMessage(Change__c change)
    {
        return '{ projectId: \"' + change.Project__c + '\", ' + 'changeId: \"' + change.Id + '\"' + ' }';
    }
    
    //represents the notification messages sent to meginfo server
    //Following is a workable json section:
    /*
        { 
            messages: [ 
            { 
                message: "messagebody", 
                 deviceToken: "token", 
                 number: 1, 
                 backInfo: 
                 { 
                     projectId: "a0JS0000001ik7hMAA", 
                     changeId: "a0SS0000001vavbMAA" 
                  } 
            }], 
            authCode: "BHdN2LqsuoBUIHBiIX%2F%2FQy9YdR4%3D", 
            timeStamp: "2012-12-05T+09:18:46Z", 
            live: "0", 
            certificateName: "push2.p12" 
         }
    */
    public class NotificationInfo
    {
        public NotificationInfo(DateTime timeStamp, Boolean isLive)
        {
            Messages = new List<NotificationMessageInfo>();
            this.TimeStamp = timeStamp;
            this.IsLive = isLive;
            this.CertificateName = isLive ? 'push_prod.p12' : 'push2.p12';  //these are two cert names used for ios PM project
        }
        
        public String Key 
        { 
            get
            {
                if(Messages.size() > 0)
                {
                    return EncodingUtil.urlEncode(EncodingUtil.base64Encode(generateDigest()), 'UTF-8');
                }
                else
                {
                    return null;
                }
            }
        }
        public DateTime TimeStamp { get; set; }
        public Boolean IsLive { get; set; }
        public String CertificateName { get; set; }
        public List<NotificationMessageInfo> Messages { get; set; }
        
        public String generateJson()
        {
            String messagesBody =  '{ messages: [ ';
            for(NotificationMessageInfo message : Messages)
            {
                messagesBody += message.generateJson() + ', ';
            }
            messagesBody = messagesBody.removeEnd(', ');
            messagesBody += ' ], ' 
                            + 'authCode: '  + JSON.serialize(Key) + ', '
                            + 'timeStamp: ' + JSON.serialize(TimeStamp.formatGmt('yyyy-MM-dd\'T\' hh:mm:ss\'Z\'')) + ', '
                            + 'live: \"' + (IsLive ? '1' : '0') + '\", '
                            + 'certificateName: ' + JSON.serialize(CertificateName)
                            + ' }';
            return messagesBody;
        }
        
        private Blob generateDigest()
        {
            return Crypto.generateMac('hmacSHA1', Blob.valueOf(Messages[0].DeviceToken + Messages[0].MessageBody + TimeStamp.formatGmt('yyyy-MM-dd\'T\' hh:mm:ss\'Z\'')), Blob.valueOf(PASSWORD));
        }
    }
    
    public class NotificationMessageInfo
    {
        public NotificationMessageInfo(String message, String deviceToken, String backInfo)
        {
            this.MessageBody = message;
            this.DeviceToken = deviceToken;
            this.BackgroundBody = backInfo;
        }
        
        public String MessageBody { get; set; }
        public String BackgroundBody { get; set; }
        public String DeviceToken { get; set; }
        
        public String generateJson()
        {
            return '{ message: ' + JSON.serialize(MessageBody) + ', '
                   + 'deviceToken: ' + JSON.serialize(DeviceToken) + ', '
                   + 'number: ' + '1' + ', '
                   + 'backInfo: ' + BackgroundBody
                   + ' }';
        }
    }
    
    @isTest
    static void testMaps()
    {
        List<User> users = [select Id, Name from User where IsEmployee__c = 1 and IsActive = true and Id != :UserInfo.getUserId() limit 2];
        MProject__c project = new MProject__c(Name = 'acme');
        insert project;
        List<Change__c> changes = new List<Change__c>();
        changes.add(new Change__c(Name = 'acme1', Project__c = project.Id, AssignedTo__c = users[0].Id, Type__c = 'Change', Priority__c = 'Low', 
                                  Status__c = 'Open', DueDate__c = System.today(), Description__c = 'luffy1'));
        changes.add(new Change__c(Name = 'acme2', Project__c = project.Id, AssignedTo__c = users[1].Id, Type__c = 'Task', Priority__c = 'High', 
                                  Status__c = 'Reopen', DueDate__c = System.today(), Description__c = 'luffy2'));
        insert changes;
        Set<Id> changeIds = new Set<Id>();
        for(Change__c change : changes)
        {
            changeIds.add(change.Id);
        }
        List<EntitySubscription> entitySubscriptions = new List<EntitySubscription>();
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[0].Id, SubscriberId = users[0].Id));
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[0].Id, SubscriberId = users[1].Id));
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[1].Id, SubscriberId = users[0].Id));
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[1].Id, SubscriberId = users[1].Id));
        insert entitySubscriptions;
        
        Map<Id, String> userId2UserName = new Map<Id, String>();
        for(User user : users)
        {
            userId2UserName.put(user.Id, user.Name);
        }
        
        String deviceToken1 = 'df9351db69d1eab3130c1b9c5a7fb2c87edc04268ae3f1aeb37c2928170f0f8c';
        String deviceToken2 = 'aab24c7cd71c3815487e2bf6fe72272c4d5fc9a5d645441886399fb44bb1167a';
        String deviceType = 'ios';
        List<MobileDevice__c> mobileDevices = new List<MobileDevice__c>();
        for(Id userId : userId2UserName.keySet())
        {
            mobileDevices.add(new MobileDevice__c(Name = userId2UserName.get(userId) + '1', UserId__c = userId, DeviceToken__c = deviceToken1, DeviceType__c = deviceType));
            mobileDevices.add(new MobileDevice__c(Name = userId2UserName.get(userId) + '2', UserId__c = userId, DeviceToken__c = deviceToken2, DeviceType__c = deviceType));
        }
        insert mobileDevices;
        
        Test.startTest();
        
        Map<String, List<String>> userId2DeviceTokens = getUserId2DeviceTokensByUserIdsAndType(userId2UserName.keySet(), deviceType);
        System.assertEquals(2, userId2DeviceTokens.size());
        for(Id userId : userId2DeviceTokens.keySet())
        {
            System.assertEquals(deviceToken1, userId2DeviceTokens.get(userId)[0]);
        }
        
        Map<Id, List<Id>> parentId2UserIds = getParentId2UserIdsByParentIds(changeIds);
        System.assertEquals(2, parentId2UserIds.size());
        for(Id parentId : parentId2UserIds.keySet())
        {
            //System.assertEquals(users[0].Id, parentId2UserIds.get(parentId)[0]);
        }
        
        Map<Id, List<String>> parentId2DeviceTokens = getParentId2DeviceTokens(parentId2UserIds, userId2DeviceTokens);
        System.assertEquals(2, parentId2DeviceTokens.size());
        for(Id parentId : parentId2DeviceTokens.keySet())
        {
            System.assertEquals(deviceToken1, parentId2DeviceTokens.get(parentId)[0]);
        }
        
        Map<Id, Change__c> changeId2Change = getChangeId2Change(changes);
        System.assertEquals(2, changeId2Change.size());
        System.assertEquals(changes[0].Id, changeId2Change.get(changes[0].Id).Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testComposeMessage()
    {
        List<User> users = [select Id, Name from User where IsEmployee__c = 1 and IsActive = true limit 2];
        MProject__c project = new MProject__c(Name = 'acme');
        insert project;
        List<Change__c> changes = new List<Change__c>();
        changes.add(new Change__c(Name = 'acme1', Project__c = project.Id, AssignedTo__c = users[0].Id, Type__c = 'Change', Priority__c = 'Low', 
                                  Status__c = 'Open', DueDate__c = System.today(), Description__c = 'luffy'));
        changes.add(new Change__c(Name = 'acme2', Project__c = project.Id, AssignedTo__c = users[1].Id, Type__c = 'Task', Priority__c = 'Low', 
                                  Status__c = 'Open', DueDate__c = System.today(), Description__c = 'luffy'));
        insert changes;
        
        Test.startTest();
        
        System.assertEquals(true, valueIsChanged(changes[0], changes[1], 'Name'));
        System.assertEquals(false, valueIsChanged(changes[0], changes[1], 'Priority__c'));
        
        String prefixOfChangeMessage = 'Change: \"' + 'acme1' + '\" in Project: \"' + 'acme' + '\"';
        System.assertEquals(prefixOfChangeMessage, composePrefixOfChangeMessage(changes[0]));
        
        String changeMessage = prefixOfChangeMessage + ' has been changed with following field(s): { ' + 'Subject, Owner, Type' + ' }.';
        System.assertEquals(changeMessage, composeChangeMessage(changes[0], changes[1]));
        
        String changeBackgroundMessage = '{ projectId: \"' + changes[0].Project__c + '\", ' + 'changeId: \"' + changes[0].Id + '\"' + ' }';
        System.assertEquals(changeBackgroundMessage, composeChangeBackgroundMessage(changes[0]));
        
        Test.stopTest();
    }
    
    @isTest
    static void testSendHttpCallout()
    {
        sendHttpCalloutInFuture('www.baidu.com', 'wp8');
    }
    
    @isTest
    static void testNotificationClass()
    {
        Datetime myDateTime = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        NotificationInfo notification = new NotificationInfo(myDateTime, false);
        notification.Messages.add(new NotificationMessageInfo('message1', 'deviceToken1', 'backInfo1'));
        notification.Messages.add(new NotificationMessageInfo('message2', 'deviceToken2', 'backInfo2'));
        
        Blob result = notification.generateDigest(); //Crypto.generateMac('hmacSHA1', Blob.valueOf('deviceToken1' + 'message1' + myDateTime.formatGmt('yyyy-MM-dd\'T\' hh:mm:ss\'Z\'')), Blob.valueOf(PASSWORD));
        String key = EncodingUtil.urlEncode(EncodingUtil.base64Encode(result), 'UTF-8');
        //String body = '{ messages: [ { message: \"'+ 'message1' + '\", deviceToken: \"' + 'deviceToken1' + '\", number: 1' + ', backInfo: ' + 'backInfo1' + ' }, { message: \"' + 'message2' + '\", deviceToken: \"' + 'deviceToken2' + '\", number: 1' + ', backInfo: ' + 'backInfo2' + ' } ], authCode: \"' + key + '\", timeStamp: \"' + '2008-12-01T 04:30:02Z' + '\", live: \"' + '0' + '\", certificateName: \"' + 'push2.p12' + '\" }';
        //System.assertEquals(body, notification.generateJson());
        String body = notification.generateJson();
    }
}