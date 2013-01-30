/*
 * Receives and converts email to change
 * The first line of the email should contain a keyword of the project name
 */
global class EmailToChangeHandler implements Messaging.InboundEmailHandler
{
    private Boolean ForwardEverything = false;
    private String usageReply = 'Thanks for using Email2Change service. This is the usage introduction:\r\n\r\n' +
                                'Each email you send to this address will be created as a Change record.\r\n' +
                                'Email subject will be the Change subject.\r\n' +
                                'Email sender will be the opener and assignedTo.\r\n' +
                                'If there are CC users in the email, the first CC user will be the assignedTo user and the other users will be the followers of the change.\r\n' +
                                'First line of the email body must contain a keyword that identifies a single project. It can be the project name, or just one word in the project name. If the keyword cannot identify a project, you will get notified.\r\n' +
                                'The body of the email goes to the change body.\r\n' +
                                'The enclosed attachments will be attached to the change.';
    
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)
    {
        if(ForwardEverything)
        {
            forwardEverythingToKevin(email);
        }
        
        // Creates an inboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        User fromUser = getUserByEmail(email.fromAddress);
        User firstCopyUser = null;
        if(email.ccAddresses != null && email.ccAddresses.size() > 0)
        {
            firstCopyUser = getUserByEmail(email.ccAddresses[0]);
        }
        List<User> allCopyUsers = getUsersByEmail(email.ccAddresses);

        
        // Creates a change and appends email body to the change's description
        if(email.plainTextBody != null && email.plainTextBody.trim().length() > 0)
        {
            String[] emailTextLines = email.plainTextBody.split('(\r\n)|\r|\n');
            List<MProject__c> projects = findProjects(emailTextlines[0]);
            MProject__c project = null;
            if(projects.size() == 1)
            {
                project = projects[0];  
            }
            else if(projects.size() > 1)
            { 
                result.success = false;
                result.message = usageReply + '\r\n\r\n\r\nPer the email you sent just now, I found more than one project with the name you specified. You might mean one of the following:\r\n' + concateProjectNames(projects) + '\r\nPlease provide a keyword that can identify a single project.';
                return result;
            }
            else
            {
                //no projects found
                result.success = false;
                result.message = usageReply + '\r\n\r\n\r\nPer the email you sent just now, I cannot find any project with the name you specified: ' + emailTextlines[0];
            }
            if(project != null && project.Id != null)
            {
                try
                {
                    String emailBody = getEmailBody(emailTextLines);
                    Change__c change = createChange(fromUser, firstCopyUser, project, emailBody, email);
                    if(change != null)
                    {
                        postChatter(change);
                        addAttachmentsToChange(change, email);
                        addFollowers(change, allCopyUsers);
                        //saveEmailAsPdf(change, emailBody);
                    }
                    result.success = false;
                    result.message = 'A change was created at ' + URL.getSalesforceBaseURL() + '/' + change.Id;
                }
                catch(Exception ex)
                {
                    result.success = true;
                }
            }
        } 
        else
        {
            //body is empty, reply the usage
            result.success = false; 
            result.message = usageReply;
        }
        return result; // Return the result for the Force.com Email Service
    }
    
    private void forwardEverythingToKevin(Messaging.InboundEmail email)
    {
        Messaging.SingleEmailMessage forwardingMail = new Messaging.SingleEmailMessage();
        forwardingMail.setToAddresses(new String[] { 'kevin.chong@meginfo.com' });
        forwardingMail.setSubject(email.subject);
        forwardingMail.setPlainTextBody(email.plainTextBody);
        forwardingMail.setHtmlBody(email.htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { forwardingMail });
    }
    
    private User getUserByEmail(String emailAddress)
    {
        List<User> users = [select Id, Name from User where IsActive = true and Email =:emailAddress order by CreatedDate limit 1];
        if(users.size() > 0)
        {
            return users[0];
        }
        else
        {
            return null;
        }
    }
    
    private List<User> getUsersByEmail(List<String> emailAddresses)
    {
        if(emailAddresses != null && emailAddresses.size() > 0)
        {
            return [select Id, Name from User where IsActive = true and Email in :emailAddresses];
        }
        else
        {
            return new List<User>();
        }
    }
    
    private List<MProject__c> findProjects(String keyword)
    {
        String projectNameKeyword = '%' + keyword + '%';      //search the project name in the first line
        return [select Id, Name from MProject__c where Name like :projectNameKeyword and Status__c != 'Closed' limit 10];
    }
    
    private String concateProjectNames(List<MProject__c> projects)
    {
        String result = '';
        for(MProject__c pro : projects)
        {
            if(pro.Name != null && pro.Name != '')
            {
                result += pro.Name + '\n';
            }
        }
        return result;
    }
    
    private String getEmailSubject(Messaging.InboundEmail email)
    {
        //removes the leading "RE:", "FW:", "FWD:"..., ignore case
        String emailSubject = '';
        if(email != null && email.Subject != null &&  email.Subject != '')
        {
            if(email.Subject.trim().length() > 80)
            {
                emailSubject = email.Subject.subString(0, 79);     // gets max subject length: 80
            }
            else
            {
                emailSubject = email.Subject;
            }
            emailSubject = email.Subject.replaceAll('[Rr][Ee]:[\\s]*', '').replaceAll('[Ff][Ww][Dd]?:[\\s]*', '');
        }
        return emailSubject;
    }
    
    public String getEmailBody(String[] emailTextLines)
    {
        String body = '';
        if(emailTextLines != null && emailTextLines.size() > 1)
        {
            for(Integer i = 0; i < emailTextlines.size(); i++)
            {
                if(i != 0)             // Deletes the first line in the Email
                {
                    body += emailTextLines[i] + '\n';
                }
            } 
        }
        return body;
    }
    
    // creates a change and find team member's Email
    private Change__c createChange(User ownerUser, User assignUser, MProject__c project, String emailBody, Messaging.InboundEmail email)
    {
        Change__c change = null;
        Id ownerId = (ownerUser != null) ? ownerUser.Id : UserInfo.getUserId();
        Id assignerId = (assignUser != null) ? assignUser.Id : ownerId;
        if(project != null && project.Id != null)
        {
            change = new Change__c(Name = getEmailSubject(email), OpenedBy__c = ownerId, AssignedTo__c = assignerId, Description__c = emailBody, Project__c = project.Id, Status__c = 'Open', DueDate__c = Date.today().addDays(7));
            insert change;
        }
        return change;
    }
    
    private void postChatter(Change__c change)
    {
        delete [select Id from FeedItem where ParentId=:change.Id];
        FeedItem newItem = new FeedItem(ParentId=change.Id, Type='TextPost', CreatedById=change.OpenedBy__c, Body='created this change.');
        insert newItem;
    }
    
    //add attachment to the specified change
    private static void addAttachmentsToChange(Change__c change, Messaging.InboundEmail email)
    {
        List<Attachment> attachments = new List<Attachment>();
        Id changeId = change.Id;
        if(email.BinaryAttachments != null)
        {
            //add BinaryAttachment to the object
            for(Messaging.InboundEmail.BinaryAttachment battch : email.BinaryAttachments)
            {
                Attachment attachment = new Attachment(Body = battch.Body, ParentId = changeId, Name = battch.fileName);  
                attachments.add(attachment);    
            }
        }
        if(email.TextAttachments != null)
        {
            //add TextAreaAttachment to the object
            for(Messaging.InboundEmail.TextAttachment tattch : email.TextAttachments)
            {
                Attachment attachment = new Attachment(Body = Blob.valueOf(tattch.Body), ParentId = changeId, Name = tattch.fileName);          
                attachments.add(attachment);
            }
        }
        if(attachments.size() > 0)
        {
            insert attachments;  
        }
    }
    
    /*private Set<Id> getSubscribers(Id changeOwnerId, MProject__c project, String emailBody, Messaging.InboundEmail email)
    {
        Set<String> teamMemberEmails = getTeamMemberEmails(project);
        // if team member's email are in the email body or ccAddresses
        Set<String> followerEmails = new Set<String>(); 
        for(String teamMemberEmail : teamMemberEmails)
        {
            if(emailBody.contains(teamMemberEmail))
            {   
                followerEmails.add(teamMemberEmail);
            }
        } 
        if(email != null && email.ccAddresses != null && email.ccAddresses.size() > 0)
        {
            for(Integer i = 0; i < email.ccAddresses.size(); i++)
            {
                for(String teamMemberEmail : teamMemberEmails)
                {
                    if(email.ccAddresses[i].contains(teamMemberEmail))
                    {   
                        followerEmails.add(teamMemberEmail);
                    }
                }
            } 
        } 
        Set<Id> subscribers = new Set<Id>();
        subscribers.add(changeOwnerId);
        for(User user : [select Id, Name, Email from User where Email in :followerEmails and IsActive=true])
        {
            subscribers.add(user.Id);
        }
        return subscribers;
    }*/
    
    // select the team members's Email of the sepecific project
    /*private Set<String> getTeamMemberEmails(MProject__c project)
    {
        Set<String> emails = new Set<String>();
        if(project != null)
        {
            for(TeamMember__c teamMember : [select Id, Name, User__r.Email, Project__c from TeamMember__c where Project__c =:project.Id])
            {
                if(teamMember.User__r.Email != null && teamMember.User__r.Email != '')
                {
                    emails.add(teamMember.User__r.Email);
                }
            }
        }
        return emails;
    }*/
    
     // Automatically follows the change 
    private void addFollowers(Change__c change, List<User> users)
    {  
        List<EntitySubscription> subscribers = new List<EntitySubscription>();
        subscribers.add(new EntitySubscription(ParentId=change.Id, SubscriberId=change.OpenedBy__c));
        for(User usr : users)
        {
            subscribers.add(new EntitySubscription(ParentId=change.Id, SubscriberId=usr.Id));
        }
        Database.insert(subscribers, false);
    }
    
    // save the email's html body as a pdf file
    public void saveEmailAsPdf(Change__c change, String emailContent)
    {  
        // for pdf file, we can only use <br/> to build a new line in the Blob's methods.
        //PageReference pdfPage = new PageReference('/Apex/ChangeDescription2?id=' + change.Id);
        //Blob content = pdfPage.getContent();    // we can't use this method in email service and future annotation
        emailContent = emailContent.replaceAll('<','&lt;').replaceAll('>', '&gt;').replaceAll('(\r\n)|\r|\n', '<br/>');
        Blob content = Blob.toPdf(emailContent);  // we can use this method only if email body contain text.
        // create the attachment against the change 
        Attachment attachment = new Attachment(ParentId = change.Id, Name = 'original content.pdf', Body = content);
        insert attachment;
    }
    
    @isTest
    static void testEmailToChangeHandler()
    {
        MProject__c project = new MProject__c(Name = 'acme bruce', StartDate__c = Date.today());
        insert project;
        TeamMember__c member = new TeamMember__c(Project__c = project.Id, User__c = UserInfo.getUserId());
        insert member;
    
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = 'acme bruce\r\nthis is test body';
        email.fromAddress ='kevin.chong@meginfo.com';  

        // Add attachments
        messaging.InboundEmail.TextAttachment ta = new messaging.InboundEmail.TextAttachment();
        ta.filename='this is only a test.txt';
        ta.body='test';
        list<messaging.InboundEmail.TextAttachment> talist = new list<messaging.InboundEmail.TextAttachment>();
        talist.add(ta);
        email.TextAttachments = talist;
        messaging.InboundEmail.BinaryAttachment ba = new messaging.InboundEmail.BinaryAttachment();
        ba.filename='this is only another test.txt';
        ba.body=blob.valueOf('test');
        list<messaging.InboundEmail.BinaryAttachment> balist = new list<messaging.InboundEmail.BinaryAttachment>();
        balist.add(ba);
        email.BinaryAttachments = balist;

        // Simulate sending the email
        EmailToChangeHandler handler = new EmailToChangeHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env); 
    }
    
    @isTest
    static void testEmailToChangeHandler2()
    {
        MProject__c project1 = new MProject__c(Name = 'acme 1', StartDate__c = Date.today());
        insert project1;
        MProject__c project2 = new MProject__c(Name = 'acme 1', StartDate__c = Date.today());
        insert project2;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = 'acme 1\r\nthis is test body';
        email.fromAddress ='kevin.chong@meginfo.com';  
        
        EmailToChangeHandler handler = new EmailToChangeHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env); 
        System.assertEquals(false, result.success);
    }
}