/*
 * this Schedule used to send daily timecard report. 
 */
global class SendDailyTimeCardReportSchedule implements Database.Batchable<SObject>, Schedulable, Database.Stateful
{
    private static final String EmailTemplateName = 'DailyTimeCardReport';
    private Id EmailTemplateId;
    private OrgWideEmailAddress OrgWideEmail;
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        Integer dayofweekToday = getDayOfWeek(Date.today());
        if((isWeekend(dayofweekToday) && isWorkday(Date.today())) || (!isWeekend(dayofweekToday) && !isHoliday(Date.today())))
        {
            List<EmailTemplate> templates = [select Id from EmailTemplate where Name = :EmailTemplateName];
            List<OrgWideEmailAddress> orgWideEmails = [select Id, DisplayName from OrgWideEmailAddress where Address='pm@meginfo.com' limit 1];
            OrgWideEmail = (orgWideEmails.size() > 0) ? orgWideEmails[0] : null;
            
            if(templates.size() > 0)
            {
                EmailTemplateId = templates[0].Id;
                return Database.getQueryLocator([select Id, Name, Email from User where IsActive = true and IsEmployee__c=1]);
            }
        }
        return null;
    }
 
    global void execute(Database.BatchableContext BC, List<User> users)
    {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(User user : users)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSaveAsActivity(false); 
            mail.setReplyTo('noreply@meginfo.com');
            if(OrgWideEmail != null)
            {
                mail.setOrgWideEmailAddressId(OrgWideEmail.Id);
            }
            else
            {
                mail.setSenderDisplayName('Meginfo System Administrator');
            }
            mail.setTargetObjectId(user.Id);
            mail.setTemplateId(EmailTemplateId);
            emails.add(mail);
        }
        if(emails.size() > 0)
        {
            try
            {
                Messaging.sendEmail(emails);
            }
            catch(Exception ex)
            {
                String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
                sendErrorMsg(new String[] { 'kevin.chong@meginfo.com' }, 'Error occureed on SendDailyTimeCardReportSchedule class', error);
            }
        }
    }
    
    private void sendErrorMsg(String[] toAddresses, String subject, String body)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('Error in SendDailyTimeCardReportSchedule');
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName('System Administrator');
        mail.setPlaintextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    global void execute(SchedulableContext SC)
    {
        SendDailyTimeCardReportSchedule batch = new SendDailyTimeCardReportSchedule();
        Database.executeBatch(batch, 10);
    }
    
    //recurring holiday is not supported
    public static Boolean isWorkday(Date d)
    {
        List<Holiday> holidays = [select Id, Name from Holiday where ActivityDate=:d order by LastModifiedDate desc limit 1];
        if(holidays.size() > 0)
        {
            return holidays[0].Name.toLowerCase() == 'workday';
        }
        else
        {
            return false;
        }
    }
    
    //recurring holiday is not supported
    public static Boolean isHoliday(Date d)
    {
        List<Holiday> holidays = [select Id, Name from Holiday where ActivityDate=:d order by LastModifiedDate desc limit 1];
        if(holidays.size() > 0)
        {
            return holidays[0].Name.toLowerCase() != 'workday';
        }
        else
        {
            return false;
        }
    }
    
    public static Boolean isWeekend(Integer dayOfWeek)
    {
        return dayOfWeek == 6 || dayOfWeek == 0;
    }
    
    public static Integer getDayOfWeek(Date d)
    {
        Date previousDate = Date.newInstance(2012, 1, 1); //it is sunday
        return Math.mod(previousDate.daysBetween(d), 7);
    }
    
    @isTest
    static void testGetDayOfWeek()
    {
        System.assertEquals(0, getDayOfWeek(Date.newInstance(2013, 6, 9)));
        System.assertEquals(3, getDayOfWeek(Date.newInstance(2013, 2, 13)));
        System.assertEquals(1, getDayOfWeek(Date.newInstance(2012, 10, 29)));
    }
    
    @isTest
    static void testSendDailyTimeCardReportSchedule()
    {
        Holiday workday = new Holiday(Name='Workday', ActivityDate=Date.today());
        insert workday;
        Test.startTest();
        SendDailyTimeCardReportSchedule batch = new SendDailyTimeCardReportSchedule();
        batch.sendErrorMsg(new String[] { 'bruce.yue@meginfo.com'}, 'Error occurred on SendDailyTimeCardReportSchedule class', 'nothing');
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testExecute()
    {
        Holiday workday = new Holiday(Name='Workday', ActivityDate=Date.today());
        insert workday;
        Test.startTest();
        SendDailyTimeCardReportSchedule schedule = new SendDailyTimeCardReportSchedule();
        SchedulableContext sc = null;
        //schedule.execute(sc);
        Test.stopTest();
    }
}