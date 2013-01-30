/*
 * Pushs notification to user's iOS devices when changes were updated
 */
public class IOSChangeNotificationService extends MobileNotificationService
{
    public override void push(List<Change__c> oldChanges, List<Change__c> newChanges)
    {
        Map<Id, Change__c> oldMap = getChangeId2Change(oldChanges);
        Map<Id, List<Id>> changeId2UserIds = getParentId2UserIdsByParentIds(oldMap.keySet());
        Set<Id> userIds = new Set<Id>();
        for(Id changeId : changeId2UserIds.keySet())
        {
            userIds.addAll(changeId2UserIds.get(changeId));
        }
        Map<String, List<String>> userId2DeviceTokens = getUserId2DeviceTokensByUserIds(userIds);
        Map<Id, List<String>> changeId2DeviceTokens = getParentId2DeviceTokens(changeId2UserIds, userId2DeviceTokens);
        
        NotificationInfo notification = new NotificationInfo(System.now(), true);
        for(Change__c change : newChanges)
        {
            String messageBody = composeChangeMessage(oldMap.get(change.Id), change);
            String backgroundMessage = composeChangeBackgroundMessage(change);
            if(changeId2DeviceTokens.containsKey(change.Id))
            {
                for(String deviceToken : changeId2DeviceTokens.get(change.Id))
                {
                    notification.Messages.add(new NotificationMessageInfo(messageBody, deviceToken, backgroundMessage));
                }
            }
        }
        pushNotification(notification);
    }
    
    public override Map<String, List<String>> getUserId2DeviceTokensByUserIds(Set<Id> userIds)
    {
        //android devices should be DeviceType__c = 'android'
        return getUserId2DeviceTokensByUserIdsAndType(userIds, 'ios');
    }
    
    public override void pushNotification(NotificationInfo notification)
    {
        sendHttpCalloutInFuture('http://184.72.226.199:8080/PushNotification/PushNotification', notification.generateJson());
    }
    
    @isTest
    static void testIOSChangeNotificationService()
    {
        String deviceToken = 'df9351db 69d1eab3 130c1b9c 5a7fb2c8 7edc0426 8ae3f1ae b37c2928 170f0f8c';
        List<User> users = [select Id, Name from User where IsEmployee__c = 1 and IsActive = true limit 2];
        MobileDevice__c mobileDevice = new MobileDevice__c(Name = users[0].Name, UserId__c = users[0].Id, DeviceToken__c = deviceToken, DeviceType__c = 'ios');
        insert mobileDevice;
        
        MProject__c project = new MProject__c(Name = 'acme');
        insert project;
        List<Change__c> changes = new List<Change__c>();
        changes.add(new Change__c(Name = 'acme1', Project__c = project.Id, AssignedTo__c = users[0].Id, Type__c = 'Change', Priority__c = 'Low', 
                                  Status__c = 'Open', DueDate__c = System.today(), Description__c = 'luffy'));
        changes.add(new Change__c(Name = 'acme2', Project__c = project.Id, AssignedTo__c = users[1].Id, Type__c = 'Task', Priority__c = 'Low', 
                                  Status__c = 'Open', DueDate__c = System.today(), Description__c = 'luffy'));
        insert changes;
        
        List<EntitySubscription> entitySubscriptions = new List<EntitySubscription>();
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[0].Id, SubscriberId = users[0].Id));
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[0].Id, SubscriberId = users[1].Id));
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[1].Id, SubscriberId = users[0].Id));
        entitySubscriptions.add(new EntitySubscription(ParentId = changes[1].Id, SubscriberId = users[1].Id));
        insert entitySubscriptions;
        
        Test.startTest();
        Change__c change1 = changes[0];
        Change__c change2 = changes[1];
        change1.Name = 'test1';
        change2.Name = 'test2';
        changes.clear();
        changes.add(change1);
        changes.add(change2);
        update changes;
        Test.stopTest();
    }
}