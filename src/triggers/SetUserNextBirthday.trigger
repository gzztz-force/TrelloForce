trigger SetUserNextBirthday on User (before insert, before update)
{
    List<User> birthdayUsers = new List<User>();

    for(User user : trigger.new)
    {
        if(user.Birthday__c != null && ((user.NextBirthday__c == null) ||
            (Trigger.isUpdate && (user.Birthday__c != Trigger.oldMap.get(user.Id).Birthday__c))))
        {
            String birthdayType = String.isBlank(user.BirthdayType__c) ? 'Solar' : user.BirthdayType__c;

            Date birthdayThisYear = getBirthday(Date.today().year(), user.Birthday__c, birthdayType);

            Date chineseToday = getChineseDateByGMTDate();
            // When birthday this year hasn't passed, set birthday this year.
            if(birthdayThisYear > chineseToday)
            {
                user.NextBirthday__c = birthdayThisYear;
            }
            else // When birthday this year passed, set birthday next year.
            {
                user.NextBirthday__c = getBirthday((Date.today().year() + 1), user.Birthday__c, birthdayType);
            }

            Date oldBirthdayThisYear;
            if(Trigger.isUpdate)
            {
                oldBirthdayThisYear = Trigger.oldMap.get(user.Id).NextBirthday__c;
            }

            // Send email to HR
            if((oldBirthdayThisYear == chineseToday) // A user is updated by updating the BirthdayThisYear field.
                || (birthdayThisYear == chineseToday)) // A new user is brithday when is created to send email.
            {
                birthdayUsers.add(user);
            }
        }
    }

    if(birthdayUsers.size() > 0)
    {
        sendBirthdayAlertEmailToHR();
    }

    // Get birthday this year solar date
    public static Date getBirthday(Integer year, Date userBirthday, String type)
    {
        Integer month = userBirthday.month();
        Integer day = userBirthday.day();

        Date solarBirthday = Date.valueOf(year + '-' + month + '-' + day);

        if(type == 'Lunar')
        {
            solarBirthday = ChineseCalendar.convertLunarToSolar(String.valueOf(solarBirthday));
        }

        return solarBirthday;
    }

    private static void sendBirthdayAlertEmailToHR()
    {
        List<String> emailAddresses = getEmailToAddresses();

        if(emailAddresses.size() > 0)
        {
            List<OrgWideEmailAddress> orgWideEmails = [select Id, DisplayName from OrgWideEmailAddress where Address='pm@meginfo.com' limit 1];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if(orgWideEmails.size() > 0)
            {
                mail.setOrgWideEmailAddressId(orgWideEmails[0].Id);
            }
            else
            {
                mail.setSenderDisplayName('Meginfo System Administrator');
            }

            mail.setToAddresses(getEmailToAddresses());
            mail.setSubject('Meginfo | Employees Birthday Alert');
            mail.setPlainTextBody(getEmailBody(birthdayUsers));
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        }
    }

    private static String getEmailBody(List<User> users)
    {
        String emailBody = 'Hi,\r\n \r\nToday is birthday of ';
        for(User user : users)
        {
             emailBody += user.FirstName + '( Birthday: ' + String.valueOf(user.Birthday__c) + ', Type: ' + user.BirthdayType__c + ')' + ', ';
        }

        return emailBody += '\r\n happpy birthday to him/her! \r\n \r\n Thanks';
    }

    private static List<String> getEmailToAddresses()
    {
        String birthdayGroup = 'BirthdayEmailAlert';
        List<String> emailAddresses = new List<String>();

        List<Group> birthdayEmailAlertGroups = [select Id from Group where DeveloperName = :birthdayGroup limit 1];

        if(birthdayEmailAlertGroups.size() > 0)
        {
            Set<Id> groupMemberIds = getUserIdsFromGroup(new Set<Id>{ birthdayEmailAlertGroups[0].Id });

            for(User user : [select Email from User where Id in :groupMemberIds])
            {
                emailAddresses.add(user.Email);
            }
        }

        return emailAddresses;
    }

    public static Set<id> getUserIdsFromGroup(Set<Id> groupIds)
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
            result.addAll(getUSerIdsFromGroup(groupIdProxys));
        }
        return result;
    }

    private static Date getChineseDateByGMTDate()
    {
        Datetime chineseTime = System.now().addHours(8);
        //yyyy-MM-dd HH:mm:ss
        List<String> dateStr = String.valueOf(chineseTime).substring(0, 10).split('-');
        Integer year = Integer.valueOf(dateStr[0]);
        Integer month = Integer.valueOf(dateStr[1]);
        Integer day = Integer.valueOf(dateStr[2]);

        return Date.newInstance(year, month, day);
    }
}