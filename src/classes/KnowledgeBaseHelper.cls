/*
 * Helper class for KnowledgeBase
 * Main purpose is to search knowledge records.
 */
public class KnowledgeBaseHelper 
{
    public static List<KnowledgeEntry__c> getTop10()
    {
        return [select Id, Name, CommentsCount__c, CreatedById, CreatedBy.Name, CreatedBy.LastName, CreatedDate, LastModifiedDate, ReadCount__c from KnowledgeEntry__c where IsPublished__c = true order by CommentsCount__c DESC, ReadCount__c DESC, CreatedDate DESC limit 100]; 
    }
  
    public static List<KnowledgeEntry__c> getLast10()
    {
        return [select Id, Name, CommentsCount__c, CreatedById, CreatedBy.Name, CreatedBy.LastName, CreatedDate, LastModifiedDate, ReadCount__c from KnowledgeEntry__c where IsPublished__c = true order by LastCommentDate__c DESC limit 100]; 
    }
    
    public static List<KnowledgeEntry__c> getMyDrafts()
    {
        return [select Id, Name, CommentsCount__c, CreatedById, CreatedBy.Name, CreatedBy.LastName, CreatedDate, LastModifiedDate, ReadCount__c, Tags__c from KnowledgeEntry__c where IsPublished__c = false and CreatedById=:UserInfo.getUserId() order by LastModifiedDate DESC]; 
    }

    public static List<KnowledgeEntry__c> searchByKeyword(String kwd)
    {
        kwd = kwd + '*';
        List<List<SObject>> myLogics = [FIND :kwd IN ALL FIELDS RETURNING KnowledgeEntry__c(Id, Name, ReadCount__c, CommentsCount__c, CreatedBy.Name, CreatedDate, LastModifiedDate, IsPublished__c, Tags__c where IsPublished__c=true or CreatedById=:UserInfo.getUserId())];
        if(myLogics != null && myLogics.size() > 0)
        {
            return ((List<KnowledgeEntry__c>)myLogics[0]);
        }
        return new List<KnowledgeEntry__c>();
    }
  
    public static List<KnowledgeEntry__c> searchByTag(String tag)
    {
        return [select Id, Name, ReadCount__c, CommentsCount__c, CreatedBy.Name, CreatedDate, LastModifiedDate, IsPublished__c from KnowledgeEntry__c where Tags__c like :('%' + tag + '%') and (IsPublished__c=true or CreatedById=:UserInfo.getUserId()) order by LastCommentDate__c desc];
    }
  
    public static List<KnowledgeEntry__c> searchByAuthor(Id authorId)
    {
    	List<KnowledgeEntry__c> result;
    	if(UserInfo.getUserId() == authorId)
    	{
    		result = [select Id, Name, ReadCount__c, CommentsCount__c, CreatedBy.Name, CreatedDate, LastModifiedDate, IsPublished__c from KnowledgeEntry__c where CreatedBy.Id=:authorId order by LastCommentDate__c desc];
    	}
    	else
    	{
    		result = [select Id, Name, ReadCount__c, CommentsCount__c, CreatedBy.Name, CreatedDate, LastModifiedDate, IsPublished__c from KnowledgeEntry__c where IsPublished__c=true order by LastCommentDate__c desc];
    	}
        return result;
    } 
    
    @isTest
    static void testList()
    {
        List<KnowledgeEntry__c> entries = getTop10();
        entries = getLast10();
        entries = getMyDrafts();
    }
    
    @isTest
    static void testSearch()
    {
        KnowledgeEntry__c ke = new KnowledgeEntry__c(Name = 'a', Content__c = 'b', Tags__c = 'c,d', IsPublished__c = true);
        insert ke;
        List<KnowledgeEntry__c> result = KnowledgeBaseHelper.searchByKeyword('a');
        //System.assert(result.size() > 0);

        result = KnowledgeBaseHelper.searchByTag('c');
        System.assert(result.size() > 0);
        
        String author = UserInfo.getUserId();
        result = KnowledgeBaseHelper.searchByAuthor(author);
        System.assert(result.size() > 0); 
    }
}