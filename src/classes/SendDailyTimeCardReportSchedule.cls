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
        List<EmailTemplate> templates = [select Id from EmailTemplate where Name = :EmailTemplateName];
        List<OrgWideEmailAddress> orgWideEmails = [select Id, DisplayName from OrgWideEmailAddress where Address='pm@meginfo.com' limit 1];
        OrgWideEmail = (orgWideEmails.size() > 0) ? orgWideEmails[0] : null;
        
        if(templates.size() > 0)
        {
            EmailTemplateId = templates[0].Id;
            return Database.getQueryLocator([select Id, Name, Email from User where IsActive = true and IsEmployee__c=1]);
        }
        else
        {
            return null;
        }
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
    
    @isTest
    static void testSendDailyTimeCardReportSchedule()
    {
        Test.startTest();
        SendDailyTimeCardReportSchedule batch = new SendDailyTimeCardReportSchedule();
        batch.sendErrorMsg(new String[] { 'bruce.yue@meginfo.com'}, 'Error occureed on SendDailyTimeCardReportSchedule class', 'nothing');
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testExecute()
    {
        SendDailyTimeCardReportSchedule schedule = new SendDailyTimeCardReportSchedule();
        SchedulableContext sc = null;
        schedule.execute(sc);
    }
}