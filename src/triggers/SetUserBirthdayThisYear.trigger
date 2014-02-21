/*
 * A trigger for set the user's birthday this year works when create or update user, or user's birthday passed.
 * The time dependent workflow will clear the BirthdayThisYear when the user brithday is today
 */
trigger SetUserBirthdayThisYear on User (before insert, before update)
{
    List<User> birthdayUsers = new List<User>();

    for(User user : trigger.new)
    {
        if(user.BirthdayThisYear__c == null && user.Birthday__c != null)
        {
            String birthdayType = String.isBlank(user.BirthdayType__c) ? 'Solar' : user.BirthdayType__c;
            Integer birthdayMonth = user.Birthday__c.month();
            Integer brithdayDay = user.Birthday__c.day();

            Date birthdayThisYear = LunarToSolarConversion.getBirthdayThisYear(birthdayMonth, brithdayDay, birthdayType);

            // When birthday this year hasn't passed, set birthday this year.
            if(birthdayThisYear >= Date.today())
            {
                user.BirthdayThisYear__c = birthdayThisYear;
            }
            // When birthday this year passed, set birthday next year.
            else
            {
                user.BirthdayThisYear__c = LunarToSolarConversion.getBirthdayNextYear(birthdayMonth, brithdayDay, birthdayType);
            }

            Date oldBirthdayThisYear = null;
            if(Trigger.isUpdate)
            {
                oldBirthdayThisYear = Trigger.oldMap.get(user.Id).BirthdayThisYear__c;
            }

            // Send email to HR
            if((oldBirthdayThisYear == Date.today()) // A user is updated by updating the BirthdayThisYear field.
                || (birthdayThisYear == Date.today())) // A new user is brithday when is created to send email.
            {
                birthdayUsers.add(user);
                user.BirthdayThisYear__c = LunarToSolarConversion.getBirthdayNextYear(birthdayMonth, brithdayDay, birthdayType);
            }
        }
    }

    if(birthdayUsers.size() > 0)
    {
        sendBirthdayAlertEmailToHR();
    }

    private static void sendBirthdayAlertEmailToHR()
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(getEmailToAddresses());
        mail.setSubject('Meginfo | Employees Birthday Alert');
        mail.setPlainTextBody(getEmailBody(birthdayUsers));
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }

    private static String getEmailBody(List<User> users)
    {
        String emailBody = 'Hi,\r\n\tToday is birthday of ';
        for(User user : users)
        {
             emailBody += user.FirstName + ', ';
        }

        return emailBody += 'Happpy birthday to him/her!';
    }

    private static List<String> getEmailToAddresses()
    {
        String birthdayGroup = 'BirthdayEmailAlert';
        List<String> emailAddresses = new List<String>();

        List<Group> birthdayEmailAlertGroups = [select Id from Group where Name = :birthdayGroup limit 1];

        if(birthdayEmailAlertGroups.size() > 0)
        {
            Set<Id> groupMemberIds = GetUserIdsFromGroup(new Set<Id>{ birthdayEmailAlertGroups[0].Id });

            for(User user : [select Email from User where Id in :groupMemberIds])
            {
                emailAddresses.add(user.Email);
            }
        }

        return emailAddresses;
    }

    public static Set<id> GetUserIdsFromGroup(Set<Id> groupIds)
    {
        // store the results in a set so we don't get duplicates
        Set<Id> result=new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix(); //005
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxys = new Set<Id>();

        // Loop through all group members in a group
        for(GroupMember m : [Select Id, UserOrGroupId From GroupMember Where GroupId in :groupIds])
        {
            // If the user or group id is a user
            if(((String)m.UserOrGroupId).startsWith(userType))
            {
                result.add(m.UserOrGroupId);
            }
            // If the user or group id is a group
            // Note: there may be a problem with governor limits if this is called too many times
            else if (((String)m.UserOrGroupId).startsWith(groupType))
            {
                // Call this function again but pass in the group found within this group
                groupIdProxys.add(m.UserOrGroupId);
            }
        }
        if(groupIdProxys.size() > 0)
        {
            result.addAll(GetUSerIdsFromGroup(groupIdProxys));
        }
        return result;
    }
}