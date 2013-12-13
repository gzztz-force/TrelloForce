/*
 * Controller of page S3FileDownload
 */
public class S3FileDownloadController
{
    private S3File__c file;
    
    public S3FileDownloadController(ApexPages.StandardController controller)
    {
        file = (S3File__c)controller.getRecord();
    }
    
    public PageReference redirect()
    {
        if(isGuestUser() && !file.IsPublic__c)
        {
            return new PageReference('https://na6.salesforce.com/apex/S3FileDownload?id=' + file.Id);
        }
        else
        {
            List<S3File__c> files = [select Id, S3Key__c, S3Bucket__c, NumberOfDownloads__c from S3File__c where Id=:file.Id limit 1 for update];
            if(files.size() == 1)
            {
                S3File__c file = files[0];
                file.NumberOfDownloads__c = (file.NumberOfDownloads__c == null) ? 1 : file.NumberOfDownloads__c + 1;
                Database.update(file, false);
                return new PageReference(S3API.getUrlToDownload(file.S3Bucket__c, file.S3Key__c));
            }
            return null;
        }
    }
    
    private Boolean isGuestUser()
    {
        return UserInfo.getUserType().toLowerCase() == 'guest';
    }
}