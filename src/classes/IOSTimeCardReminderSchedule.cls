/*
 * Scheduled job for time card reminder notification to iOS devices
 */
global class IOSTimeCardReminderSchedule implements Schedulable
{
    global void execute(SchedulableContext SC) 
    {
        MobileNotificationService.NotificationInfo notification = new MobileNotificationService.NotificationInfo(System.now(), true);
        String messageBody = 'Reminder: You don\'t have any time card logged today.';
        String backgroundMessage = '{}';
        Map<String, List<String>> userId2DeviceTokens = MobileNotificationService.getUserId2DeviceTokensByUserIdsAndType(userIdsHaveNoTimeCardToday(), 'ios');
        for(String userId : userId2DeviceTokens.keySet())
        {
            for(String deviceToken : userId2DeviceTokens.get(userId))
            {
                notification.Messages.add(new MobileNotificationService.NotificationMessageInfo(messageBody, deviceToken, backgroundMessage));
            }
        }
        IOSChangeNotificationService iOSChangeNotification = new IOSChangeNotificationService();
        iOSChangeNotification.pushNotification(notification);
    }
    
    private static Set<Id> userIdsHaveNoTimeCardToday()
    {
        Set<Id> userIdsHaveTimeCardToday = new Set<Id>();
        for(TimeCard__c timecard : [select TeamMember__r.User__c from TimeCard__c where Date__c = :System.today() and TeamMember__r.User__r.IsEmployee__c = 1])
        {
            userIdsHaveTimeCardToday.add(timecard.TeamMember__r.User__c);
        }
        Set<Id> userIdsHaveNoTimeCardToday = new Set<Id>();
        for(User user :[select Id from User where Id not in :userIdsHaveTimeCardToday and IsEmployee__c = 1])
        {
            userIdsHaveNoTimeCardToday.add(user.Id);
        }
        return userIdsHaveNoTimeCardToday;
    }

    @isTest
    static void testIOSTimeCardReminderSchedule()
    {
        Set<Id> userIds = new Set<Id>();
        List<User> users = [select Id, Name from User where IsEmployee__c = 1 limit 2];
        for(User user : users)
        {
            userIds.add(user.Id);
        }
        
        MProject__c project = new MProject__c(Name = 'acme');
        insert project;
        TeamMember__c teamMember = new TeamMember__c(Project__c = project.Id, User__c = users[0].Id, Name = 'acme1');
        insert teamMember;
        TimeCard__c timeCard = new TimeCard__c(TeamMember__c = teamMember.Id, Project__c = project.Id, Hours__c = 8, Description__c = 'acme1', Date__c=Date.today());
        insert timeCard;
        
        String deviceToken1 = 'df9351db69d1eab3130c1b9c5a7fb2c87edc04268ae3f1aeb37c2928170f0f8c';
        String deviceToken2 = 'aab24c7cd71c3815487e2bf6fe72272c4d5fc9a5d645441886399fb44bb1167a';
        String deviceType = 'ios';
        List<MobileDevice__c> mobileDevices = new List<MobileDevice__c>();
        for(User user : users)
        {
            mobileDevices.add(new MobileDevice__c(Name = user.Name + '1', UserId__c = user.Id, DeviceToken__c = deviceToken1, DeviceType__c = deviceType));
            mobileDevices.add(new MobileDevice__c(Name = user.Name + '2', UserId__c = user.Id, DeviceToken__c = deviceToken2, DeviceType__c = deviceType));
        }
        insert mobileDevices;
        
        Test.startTest();
        
        Set<Id> userIdsHaveNoTimeCardToday = userIdsHaveNoTimeCardToday();
        for(Id userId : userIdsHaveNoTimeCardToday)
        {
            System.assertNotEquals(users[0].Id, userId);
        }
        
        String jobId = System.schedule('testIOSTimeCardReminderSchedule', '0 0 22 * * ?', new IOSTimeCardReminderSchedule());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where Id = :jobId];
        System.assertEquals('0 0 22 * * ?', ct.CronExpression);
        
        Test.stopTest();
    }
}