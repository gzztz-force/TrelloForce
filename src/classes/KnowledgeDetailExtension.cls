/*
 * Controller of pages: KnowledgeDetail, KnowledgeEdit
 */
public with sharing class KnowledgeDetailExtension
{
    private KnowledgeEntry__c record;
  
    public KnowledgeDetailExtension(ApexPages.StandardController controller)
    {
        String entryId = controller.getId();
        record = (KnowledgeEntry__c)controller.getRecord();
    }
  
    //converts the tag__c field from string into a comma-separated list
    public List<String> Tags
    {
        get
        {
            List<String> result = new List<String>();
            if(record != null && record.Tags__c != null)
            {
                for(String tag : record.Tags__c.split(','))
                {
                    result.add(tag.trim());
                }
            }
            return result;
        }
    }

    //automatically increments the ReadCount__c field by 1
    public PageReference increment() 
    {
        for(KnowledgeEntry__c lg : [select Id, ReadCount__c from KnowledgeEntry__c where Id =:record.Id limit 1])
        {
            if(lg.ReadCount__c == null)
            {
                lg.ReadCount__c = 0; 
            }
            lg.ReadCount__c += 1;
            try
            {
                update lg;
            }
            catch(Exception ex)
            {
            } 
        }            
        return null;
    }
    
    //deletes the KnowledgeEntry
    public PageReference remove()
    {
        try
        {
            delete record;
            return Page.KnowledgeBaseHome;
        }
        catch(Exception ex)
        {
            Apexpages.addmessages(ex);
             return null;
        }
    }
    
    //updates the KnowledgeEntry
    public PageReference save()
    {
        if(record.Name == null || record.Name.trim() == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Subject cannot be empty.'));
            return null;
        }
        if(record.Content__c == null || record.Content__c.trim() == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Body cannot be empty.'));
            return null;
        }
        try
        {
            upsert record;
            return new PageReference('/' + record.Id);
        }
        catch(Exception ex)
        {
             Apexpages.addmessages(ex);
             return null;
        }
    }
    
    //cancels the edit of KnowledgeEntry, returnes to the detail page or to the home page (deppends on inserting or updating)
    public PageReference cancel()
    {
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        if(retURL != null && retURL != '')
        {
            return new PageReference(retURL);
        }
        if(record.Id != null)
        {
            return new PageReference('/' + record.Id);
        }
        else
        {
            return Page.KnowledgeBaseHome;
        }
    }
    
    @isTest
    static void test()
    {
        KnowledgeEntry__c ke = new KnowledgeEntry__c(Name = 'acme', Content__c = 'acme,acme', Tags__c = 'acc,sad');
        insert ke;
        PageReference pageRef = new PageReference('/apex/KnowledgeDetail?id=' + ke.Id);
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController controller = new ApexPages.StandardController(ke);
        KnowledgeDetailExtension extension = new KnowledgeDetailExtension(controller);
        
        System.assertEquals(2, extension.Tags.size());
        
        extension.increment();
        
        extension.save();
        
        extension.remove();
    }
}