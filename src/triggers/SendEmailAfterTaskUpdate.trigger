/*
 * Sends outbound emails on change update
 * emails will be sent to change opened_by, assigned_to and  chatter subscribers, excluding current user
 */
trigger SendEmailAfterTaskUpdate on ChangeTask__c (after update) 
{
    EmailTemplate template  = [select HtmlValue, Subject, Body from EmailTemplate where Id = '00X80000001ThXb'];
    String templateBody = template.HtmlValue;
    String templateSubject = template.Subject;
    String templateTextBody = template.Body;
    
    List<Messaging.Singleemailmessage> mails = new List<Messaging.Singleemailmessage>();
    Set<Id> tasksId = new Set<Id>();
    Set<Id> changesId = new Set<Id>();
    
    for(ChangeTask__c newTask : Trigger.new)
    {
        ChangeTask__c oldTask = Trigger.oldMap.get(newTask.Id);
        if(importantFieldsChanged(oldTask, newTask))
        {
            tasksId.add(newTask.Id);
            changesId.add(newTask.Change__c);
        }
    }
    List<Change__c> newChanges = [select Id, Name, ChangeNumber__c,  AssignedTo__c, OpenedBy__c, (select Id, SubscriberId from FeedSubscriptionsForEntity) from Change__c where Id in :changesId];
    List<ChangeTask__c> newTasks = [select Id, Name, Status__c, Change__r.Project__c, Change__r.Project__r.Name, Change__c, Change__r.Name, Change__r.ChangeNumber__c, CreatedById, CreatedBy.Name, Estimation__c, AssignedTo__c, AssignedTo__r.Name, DueDate__c, Description__c from ChangeTask__c where Id in :tasksId];
    for(ChangeTask__c tsk : newTasks)
    {
        Set<Id> receivers = new Set<Id>(); 
        Change__c change = null;
        for(Change__c chg : newChanges)
        {
            if(chg.Id == tsk.Change__c)
            {
                change = chg;
                break;
            }
        }
        if(change == null)
        {
            continue;
        }
        if(change.AssignedTo__c != null && change.AssignedTo__c != UserInfo.getUserId())
        {
            receivers.add(change.AssignedTo__c);
        }
        if(change.OpenedBy__c != null && change.OpenedBy__c != UserInfo.getUserId())
        {
            receivers.add(change.OpenedBy__c);
        }
        for(EntitySubscription subscriber : change.FeedSubscriptionsForEntity)
        {
            if(subscriber.SubscriberId != null && subscriber.SubscriberId != UserInfo.getUserId())
            {
                receivers.add(subscriber.SubscriberId);
            }
        }
        send(receivers, tsk);
    }
    if(mails.size() > 0)
    {
        Messaging.sendEmail(mails);  
    }

    private Boolean importantFieldsChanged(ChangeTask__c oldTask, ChangeTask__c newTask)
    {
        String[] importantFields = new String[] {'Name', 'Estimation__c', 'AssignedTo__c', 'DueDate__c', 'Description__c', 'Status__c'};
        for(String importantField : importantFields)
        {
            if(string.valueOf(oldTask.get(importantField)) != string.valueOf(newTask.get(importantField)))
            {
                return true;
            }
        }
        return false;
    }
    
    private void send(Set<Id> usersId, ChangeTask__c tsk)
    {
        List<User> users = [select Id, Email from User where Id in :usersId];
        ChangeTask__c oldTsk = Trigger.oldMap.get(tsk.Id);
        
        String body = templateBody;
        
        body = replaceMergeField(body, '{!ChangeTask__c.Name}', tsk.Name, oldTsk.Name != tsk.Name);
        body = replaceMergeField(body, '{!Change__c.Name}', tsk.Change__r.Name, false);
        body = replaceMergeField(body, '{!Change__c.Project__c}', tsk.Change__r.Project__r.Name, false);
        body = replaceMergeField(body, '{!ChangeTask__c.CreatedBy}', tsk.CreatedBy.Name, false);
        body = replaceMergeField(body, '{!ChangeTask__c.DueDate__c}', (tsk.DueDate__c == null)?'':tsk.DueDate__c.format(), oldTsk.DueDate__c != tsk.DueDate__c);
        body = replaceMergeField(body, '{!ChangeTask__c.Estimation__c}', (tsk.Estimation__c == null)?'':String.valueOf(tsk.Estimation__c), oldTsk.Estimation__c != tsk.Estimation__c);
        body = replaceMergeField(body, '{!ChangeTask__c.Status__c}', (tsk.Status__c == null)?'':tsk.Status__c, oldTsk.Status__c != tsk.Status__c);
        body = replaceMergeField(body, '{!ChangeTask__c.Description__c}', (tsk.Description__c == null)?'':tsk.Description__c.replaceAll('\r\n', '<br/>'), oldTsk.Description__c != tsk.Description__c);
        body = body.replace('{!ChangeTask__c.Link}', 'https://na6.salesforce.com/' + tsk.Id);
        
        String subject = templateSubject;
        subject = replaceMergeField(subject, '{!ChangeTask__c.Name}', tsk.Name, false);
        subject = replaceMergeField(subject, '{!Change__c.Name}', tsk.Change__r.Name, false);
        subject = replaceMergeField(subject, '{!Change__c.ChangeNumber__c}', tsk.Change__r.ChangeNumber__c, false);
        subject = replaceMergeField(subject, '{!Change__c.Project__c}', tsk.Change__r.Project__r.Name, false);
        subject = replaceMergeField(subject, '{!ChangeTask__c.CreatedBy}', tsk.CreatedBy.Name, false);
        subject = replaceMergeField(subject, '{!ChangeTask__c.DueDate__c}', (tsk.DueDate__c == null)?'':tsk.DueDate__c.format(), false);
        subject = replaceMergeField(subject, '{!ChangeTask__c.Estimation__c}', (tsk.Estimation__c == null)?'':String.valueOf(tsk.Estimation__c), false);
        subject = replaceMergeField(subject, '{!ChangeTask__c.Status__c}', (tsk.Status__c == null)?'':tsk.Status__c, false);

        String textBody = templateTextBody;
        textBody = replaceMergeField(textBody, '{!ChangeTask__c.Name}', tsk.Name, false);
        textBody = replaceMergeField(textBody, '{!Change__c.Name}', tsk.Change__r.Name, false);
        textBody = replaceMergeField(textBody, '{!Change__c.Project__c}', tsk.Change__r.Project__r.Name, false);
        textBody = replaceMergeField(textBody, '{!ChangeTask__c.CreatedBy}', tsk.CreatedBy.Name, false);
        textBody = replaceMergeField(textBody, '{!ChangeTask__c.DueDate__c}', (tsk.DueDate__c == null)?'':tsk.DueDate__c.format(), false);
        textBody = replaceMergeField(textBody, '{!ChangeTask__c.Estimation__c}', (tsk.Estimation__c == null)?'':String.valueOf(tsk.Estimation__c), false);
        textBody = replaceMergeField(textBody, '{!ChangeTask__c.Status__c}', (tsk.Status__c == null)?'':tsk.Status__c, false);
        textBody = replaceMergeField(textBody, '{!ChangeTask__c.Description__c}', (tsk.Description__c == null)?'':tsk.Description__c.replaceAll('\r\n', '<br/>'), false);
        textBody = textBody.replace('{!ChangeTask__c.Link}', 'https://na6.salesforce.com/' + tsk.Id);
        
        if(tsk.AssignedTo__c != null)
        {
            body = replaceMergeField(body, '{!ChangeTask__c.AssignedTo__c}' , tsk.AssignedTo__r.Name, oldTsk.AssignedTo__c != tsk.AssignedTo__c);
            textBody = replaceMergeField(textBody, '{!ChangeTask__c.AssignedTo__c}' , tsk.AssignedTo__r.Name, false);
        }
        else
        {
            body = replaceMergeField(body, '{!ChangeTask__c.AssignedTo__c}' , '', false);
            textBody = replaceMergeField(textBody, '{!ChangeTask__c.AssignedTo__c}' , '', false);
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