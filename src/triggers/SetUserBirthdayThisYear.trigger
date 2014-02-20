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
        Group birthdayEmailAlertGroup = [select Id from Group where Name = 'BirthdayEmailAlert' limit 1];

        List<Id> groupMemberIds = new List<Id>();
        List<Id> roleIds = new List<Id>();
        List<String> emailToAddresses = new List<String>();

        for(GroupMember groupMember : [select UserOrGroupId from GroupMember where GroupId =:birthdayEmailAlertGroup.Id])
        {
            groupMemberIds.add(groupMember.UserOrGroupId);
        }

        for(Group roleGroup : [select RelatedId from Group where Id in:groupMemberIds])
        {
            roleIds.add(roleGroup.RelatedId);
        }

        for(UserRole userRole :  [select Id, (select Email from Users) from UserRole where Id in :roleIds])
        {
            for(User user : userRole.Users)
            {
                emailToAddresses.add(user.Email);
            }
        }

        return emailToAddresses;
    }
}