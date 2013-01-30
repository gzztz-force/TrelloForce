/*
 * Sends outbound emails on change update
 * emails will be sent to change opened_by, assigned_to and  chatter subscribers, excluding current user
 */
trigger SendEmailAfterChangeUpdate on Change__c (after update) 
{
    //push notification for iOS, disabled temporarily
    //IOSChangeNotificationService changeNotification = new IOSChangeNotificationService();
    //changeNotification.push(Trigger.old, Trigger.new);

    EmailTemplate template  = [select HtmlValue, Subject, Body from EmailTemplate where Id = '00X80000001T7q4'];
    String templateBody = template.HtmlValue;
    String templateSubject = template.Subject;
    String templateTextBody = template.Body;
    
    List<Messaging.Singleemailmessage> mails = new List<Messaging.Singleemailmessage>();
    List<Id> changesId = new List<Id>();
    
    for(Change__c newChange : Trigger.new)
    {
        Change__c oldChange = Trigger.oldMap.get(newChange.Id);
        if(importantFieldsChanged(oldChange, newChange))
        {
            changesId.add(newChange.Id);
        }
    }
    List<Change__c> newChanges = [select Id, Name, AssignedTo__c, AssignedTo__r.Name, OpenedBy__c, Project__c, Project__r.Name, ChangeNumber__c, Priority__c, Status__c, Type__c, Description__c, DueDate__c, Estimate__c,
                                (select Id, SubscriberId from FeedSubscriptionsForEntity) 
                                from Change__c where Id in :changesId];
    for(Change__c ch : newChanges)
    {
        Set<Id> receivers = new Set<Id>();
        if(ch.AssignedTo__c != null && ch.AssignedTo__c != UserInfo.getUserId())
        {
            receivers.add(ch.AssignedTo__c);
        }
        if(ch.OpenedBy__c != null && ch.OpenedBy__c != UserInfo.getUserId())
        {
            receivers.add(ch.OpenedBy__c);
        }
        for(EntitySubscription subscriber : ch.FeedSubscriptionsForEntity)
        {
            if(subscriber.SubscriberId != null && subscriber.SubscriberId != UserInfo.getUserId())
            {
                receivers.add(subscriber.SubscriberId);
            }
        }
        send(receivers, ch);
    }
    if(mails.size() > 0)
    {
        Messaging.sendEmail(mails);  
    }

    private Boolean importantFieldsChanged(Change__c oldChange, Change__c newChange)
    {
        String[] importantFields = new String[] {'Name', 'AssignedTo__c', 'Description__c', 'DueDate__c', 'Estimate__c', 'Priority__c', 'Status__c'};
        for(String importantField : importantFields)
        {
            if(string.valueOf(oldChange.get(importantField)) != string.valueOf(newChange.get(importantField)))
            {
                return true;
            }
        }
        return false;
    }
    
    private void send(Set<Id> usersId, Change__c ch)
    {
        List<User> users = [select Id, Email from User where Id in :usersId];
        Change__c old = trigger.oldMap.get(ch.Id);
        
        String body = templateBody;
        body = body.replace('New Task Assigned To You', 'Task Update');
        body = replaceMergeField(body, '{!Change__c.ChangeNumber__c}', ch.ChangeNumber__c, old.ChangeNumber__c != ch.ChangeNumber__c);
        body = replaceMergeField(body, '{!Change__c.Name}', ch.Name, old.Name != ch.Name);
        body = replaceMergeField(body, '{!Change__c.Priority__c}', ch.Priority__c, old.Priority__c != ch.Priority__c);
        body = replaceMergeField(body, '{!Change__c.Status__c}', ch.Status__c, old.Status__c != ch.Status__c);
        body = replaceMergeField(body, '{!Change__c.DueDate__c}', (ch.DueDate__c == null)?'':ch.DueDate__c.format(), old.DueDate__c != ch.DueDate__c);
        body = replaceMergeField(body, '{!Change__c.Estimate__c}', (ch.Estimate__c == null)?'':String.valueOf(ch.Estimate__c), old.Estimate__c != ch.Estimate__c);
        body = replaceMergeField(body, '{!Change__c.Type__c}', ch.Type__c, old.Type__c != ch.Type__c);
        body = replaceMergeField(body, '{!Change__c.Description__c}', (ch.Description__c == null)?'':ch.Description__c.replaceAll('\r\n', '<br/>'), old.Description__c != ch.Description__c);
        body = body.replace('{!Change__c.Link}', 'https://na6.salesforce.com/' + ch.Id);
        
        String subject = templateSubject;
        subject = replaceMergeField(subject, '{!Change__c.ChangeNumber__c}', ch.ChangeNumber__c, false);
        subject = replaceMergeField(subject, '{!Change__c.Name}', ch.Name, false);
        subject = replaceMergeField(subject, '{!Change__c.Priority__c}', ch.Priority__c, false);
        subject = replaceMergeField(subject, '{!Change__c.Status__c}', ch.Status__c, false);
        subject = replaceMergeField(subject, '{!Change__c.Type__c}', ch.Type__c, false);
        
        String textBody = templateTextBody;
        textBody = replaceMergeField(textBody, '{!Change__c.ChangeNumber__c}', ch.ChangeNumber__c, false);
        textBody = replaceMergeField(textBody, '{!Change__c.Name}', ch.Name, false);
        textBody = replaceMergeField(textBody, '{!Change__c.Priority__c}', ch.Priority__c, false);
        textBody = replaceMergeField(textBody, '{!Change__c.Status__c}', ch.Status__c, false);
        textBody = replaceMergeField(textBody, '{!Change__c.DueDate__c}', (ch.DueDate__c == null)?'':ch.DueDate__c.format(), false);
        textBody = replaceMergeField(textBody, '{!Change__c.Estimate__c}', (ch.Estimate__c == null)?'':String.valueOf(ch.Estimate__c), false);
        textBody = replaceMergeField(textBody, '{!Change__c.Type__c}', ch.Type__c, false);
        textBody = replaceMergeField(textBody, '{!Change__c.Description__c}', (ch.Description__c == null)?'':ch.Description__c.replaceAll('\r\n', '<br/>'), false);
        textBody = textBody.replace('{!Change__c.Link}', 'https://na6.salesforce.com/' + ch.Id);
        
        if(ch.AssignedTo__c != null)
        {
            body = replaceMergeField(body, '{!Change__c.AssignedTo__c}' , ch.AssignedTo__r.Name, old.AssignedTo__c != ch.AssignedTo__c);
            textBody = replaceMergeField(textBody, '{!Change__c.AssignedTo__c}' , ch.AssignedTo__r.Name, false);
        }
        else
        {
            body = replaceMergeField(body, '{!Change__c.AssignedTo__c}' , '', false);
            textBody = replaceMergeField(textBody, '{!Change__c.AssignedTo__c}' , '', false);
        }

        if(ch.Project__c != null)
        {
            body = replaceMergeField(body, '{!Change__c.Project__c}' , ch.Project__r.Name, old.Project__c != ch.Project__c);
            textBody = replaceMergeField(textBody, '{!Change__c.Project__c}' , ch.Project__r.Name, false);
        }
        else
        {
            body = replaceMergeField(body, '{!Change__c.Project__c}', '', false);
            textBody = replaceMergeField(textBody, '{!Change__c.Project__c}', '', false);
        }
        
        for(User receiver: users)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { receiver.Email });
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setPlainTextBody(textBody);
            mail.setSaveAsActivity(false);
            mails.add(mail); 
        }
    }
    private String replaceMergeField(String source, String field, String value, Boolean bold)
    {
        if(value == null)
        {
            value = '';
        }
        if(bold)
        {
            value = '<span style="color:#FF6A00">' + value + '</span>';
        }
        return source.replace(field, value);
    }
}