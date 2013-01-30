/*
 * Controller of page KnowledgeSearch
 */
public with sharing class KnowledgeSearchController 
{
    //returns the search result by page parameters: keyword, tag, author
    public List<KnowledgeEntry__c> searchResults
    {
        get
        {
            String kwd = Apexpages.currentPage().getParameters().get('keyword');
            String tag = Apexpages.currentPage().getParameters().get('tag');
            String author = Apexpages.currentPage().getParameters().get('author');
            if(kwd != null && kwd != '')
            {
              return KnowledgeBaseHelper.searchByKeyword(kwd);
            }
            if(tag != null && tag != '')
            {
              return KnowledgeBaseHelper.searchByTag(tag);
            }
            if(author instanceOf Id)
            {
              return KnowledgeBaseHelper.searchByAuthor(author);
            }
            return new List<KnowledgeEntry__c>();
        }
    }

    @isTest
    static void test()
    {
        KnowledgeEntry__c ke = new KnowledgeEntry__c(Name = 'acme', Content__c = 'acme,acme', Tags__c = 'acc,sad');
        insert ke;
        KnowledgeSearchController controller = new KnowledgeSearchController();
        
        Test.setCurrentPage(new PageReference('/apex/KnowledgeSearch?keyword=acme'));
        List<KnowledgeEntry__c> result = controller.searchResults;
        
        Test.setCurrentPage(new PageReference('/apex/KnowledgeSearch?tag=acc'));
        result = controller.searchResults;
        System.assert(result.size() > 0);
        
        Test.setCurrentPage(new PageReference('/apex/KnowledgeSearch?author=' + UserInfo.getUserId()));
        result = controller.searchResults;
        System.assert(result.size() > 0);
    }
}