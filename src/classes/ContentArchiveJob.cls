/*
 * Batch job to archive attachments & content documents in closed projects
 * This job will upload them to S3 and then delete them.
 */
public class ContentArchiveJob implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful
{
    public enum JobType { Attachment, FeedItem, FeedComment }
    
    private Id projectId;
    private Integer fileCountToBeProcessed;
    private Integer failedFileCount;
    private Integer succeededFileCount;
    
    public ContentArchiveJob(Id projectId)
    {
        this.projectId = projectId;
        fileCountToBeProcessed = failedFileCount = succeededFileCount = 0;
    }
    
    public Iterable<sObject> start(Database.BatchableContext BC)
    {
        Set<Id> targetParentIds = new Set<Id>();
        List<MProject__c> projects = [select Id, (select Id from Changes__r where IsClosed__c=1) from MProject__c where Id=:projectId limit 1];
        if(projects.size() > 0)
        {
            targetParentIds.add(projectId);
            for(Change__c chg : projects[0].Changes__r)
            {
                targetParentIds.add(chg.Id);
            }
        }
        List<sObject> result = new List<sObject>();
        for(Attachment a : [select Id from Attachment where ParentId in :targetParentIds])
        {
            result.add(a);
        }
        for(FeedItem f : [select Id, RelatedRecordId, ParentId from FeedItem where ParentId in :targetParentIds and Type='ContentPost'])
        {
            result.add(f);
        }
        for(FeedComment c : [select Id, RelatedRecordId, ParentId from FeedComment where ParentId in :targetParentIds and CommentType='ContentComment'])
        {
            result.add(c);
        }
        fileCountToBeProcessed = result.size();
        return result;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        for(sObject obj : scope)
        {
            if(obj instanceof Attachment)
            {
                Attachment a = [select Id, ParentId, Name, Body, BodyLength, ContentType, CreatedDate from Attachment where Id=:obj.Id limit 1];
            	doArchive(a, a.ParentId, a.Name, S3API.resolveS3Key(a.ParentId, a.Name), S3API.resolveContentType(a.Name), a.BodyLength, a.Body, a.CreatedDate.date());
            }
            else if(obj instanceOf FeedItem)
            {
                FeedItem f = (FeedItem)obj;
                List<ContentVersion> vs = [select Id, Title, ContentDocumentId, PathOnClient, VersionData, ContentSize, FileType, CreatedDate from ContentVersion where Id=:f.RelatedRecordId limit 1];
                if(vs.size() > 0)
                {
                    ContentVersion v = vs[0];
                	doArchive(new ContentDocument(Id=v.ContentDocumentId), f.ParentId, v.Title, S3API.resolveS3Key(f.ParentId, v.PathOnClient), S3API.resolveContentType(v.PathOnClient), v.ContentSize, v.VersionData, v.CreatedDate.date()); 
                }
                else
                {
                    //Content version was deleted;
                    fileCountToBeProcessed--;
                }
            }
            else if(obj instanceof FeedComment)
            {
                FeedComment c = (FeedComment)obj;
                List<ContentVersion> vs = [select Id, Title, ContentDocumentId, PathOnClient, VersionData, ContentSize, FileType, CreatedDate from ContentVersion where Id=:c.RelatedRecordId limit 1];
                if(vs.size() > 0)
                {
                    ContentVersion v = vs[0];
            		doArchive(new ContentDocument(Id=v.ContentDocumentId), c.ParentId, v.Title, S3API.resolveS3Key(c.ParentId, v.PathOnClient), S3API.resolveContentType(v.PathOnClient), v.ContentSize, v.VersionData, v.CreatedDate.date()); 
                }
                else
                {
                    //Content version was deleted;
                    fileCountToBeProcessed--;
                }
            }
        }
    }
    
    private void doArchive(sObject obj, Id parentId, String filename, String key, String contentType, Integer bodyLength, Blob body, Date originalDate)
    {
        Boolean uploadSucceeded = doUpload(key, contentType, bodyLength, body);
        if(uploadSucceeded)
        {
            try
            {
            	createFileEntry(parentId, filename, key, contentType, bodyLength, originalDate);
            	delete obj;
                succeededFileCount++;
            }
            catch(Exception ex)
            {
                System.debug(ex.getMessage());
                failedFileCount++;
            }
        }
        else
        {
            failedFileCount++;
        }
    }
    
    private Boolean doUpload(String key, String contentType, Integer bodyLength, Blob body)
    {
        if(bodyLength < 3 * 1024 * 1024)
        {
        	return S3API.putFile('meginfo', key, contentType, body);
        }
        return false;
    }
    
    private S3File__c createFileEntry(Id parentId, String filename, String key, String contentType, Integer bodyLength, Date originalDate)
    {
        S3File__c file = new S3File__c(FileName__c=filename, ParentId__c=parentId, S3Key__c=key, S3Bucket__c='meginfo', SizeInBytes__c=bodyLength, ContentType__c=contentType, OriginalDate__c=originalDate);
        insert file;
        return file;
    }
    
    public void finish(Database.BatchableContext BC)
    {
        //if(fileCountToBeProcessed > 0)
        {
            List<MProject__c> prjs = [select Id, Name from MProject__c where Id=:projectId limit 1];
            for(MProject__c prj : prjs)
            {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {'kevin.chong@meginfo.com'});
                email.setSubject('DocumentArchiveJob finished');
                email.setReplyTo('noreply@meginfo.com');
                email.setSenderDisplayName('Meginfo System Administrator');
                email.setPlainTextBody('Project[Id=' + prj.Id + ', Name=' +prj.Name + '] finished.\r\nTotal Files: ' + fileCountToBeProcessed + '\r\nSucceeded files: ' + succeededFileCount + '\r\nFailed files: ' + failedFileCount);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        }
    }
}