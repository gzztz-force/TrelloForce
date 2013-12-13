/*
 * Controller of page ChangeDetail
 */
public with sharing class ChangeDetailController 
{
    private Change__c change;
    
    public ChangeDetailController(ApexPages.StandardController controller) 
    {
        change = (Change__c)controller.getRecord();
    }
    
    public List<S3File__c> S3Files
    {
        get
        {
            return [select Id, Name, DownloadLink__c, FileName__c, Size__c, OriginalDate__c from S3File__c where ParentId__c=:change.Id];
        }
    }
    
    public PageReference redirect()
    { 
        return null;
    }

}