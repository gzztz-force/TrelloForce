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
    
    public PageReference redirect()
    { 
        return null;
    }

}