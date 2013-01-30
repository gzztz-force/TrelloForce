/*
 * Controller for page KnowledgeBaseHome
 */
public with sharing class KnowledgeBaseController
{
    private final Integer PageSize = 50;
    private ApexPages.StandardSetController setController;

    public KnowledgeBaseController()
    {
        PageNum = 1;
        SortBy = 'create'; 
        KnowledgeEntries = new KnowledgeEntry__c[] {};
        Tags = new List<TagInfo>();
        setupSetController();
        setTags();
    }
    
    public transient KnowledgeEntry__c [] KnowledgeEntries { get; set; }
    public String SortBy { get; set; }
    public Integer PageNum { get; set; }
    public List<TagInfo> Tags { get; set; }

    public Boolean HasNextPage 
    {
        get
        {
            return this.setController.getHasNext();
        }
    }

    public Boolean HasPrevPage
    {
        get 
        {
            return this.setController.getHasPrevious();
        }
    }

    public String TotalPages 
    { 
        get 
        {
            if(this.setController != null)
            {
                Double doublePageNum = (Double)this.setController.getResultSize()/this.setController.getPageSize();
                Decimal numOfPages = Decimal.valueOf(doublePageNum).round(RoundingMode.CEILING);
                return numOfPages == 0 ? '1' : String.valueOf(numOfPages);
            }
            else
            {
                return '1';
            }
        } 
    }

    public PageReference nextPage() 
    {
        setupSetController();
        PageNum++;
        setController.next();
        KnowledgeEntries = this.setController.getRecords();
        return null;
    }

    public PageReference prevPage() 
    {
        setupSetController();
        PageNum--;
        setController.previous();
        KnowledgeEntries = this.setController.getRecords();
        return null;
    }

    public PageReference refresh()
    {
        setupSetController();
        KnowledgeEntries = this.setController.getRecords();
        return null;
    }

    //gets the total count of knowledges in base
    public Integer TotalKnowledge
    {
        get
        {
            return [select count() from KnowledgeEntry__c];
        }
    }
    
    private void setTags()
    {
        AggregateResult[] groupedResults = [select Count(Id) c, Name from KnowledgeTag__c group by Name having count(Id) > 1 order by count(Id) desc limit 10];
        for(AggregateResult result : groupedResults)  
        {   
            String tagName = (String)result.get('Name');
            Integer tagCount = (Integer)result.get('c');
            Tags.add(new TagInfo(tagName, tagCount));
        }
    }
    
    private void setupSetController() 
    {      
        String kwd = ApexPages.currentPage().getParameters().get('keyword');
        String tag = ApexPages.currentPage().getParameters().get('tag');
        String author = ApexPages.currentPage().getParameters().get('author');
        Id currentUserId = UserInfo.getUserId();
        
        List<sObject> contentFilteredKnowledge = null;
        if(kwd != null && kwd != '')
        {
            if(kwd.length() > 1)   // System.SearchException: search term must be longer than one character
            {
                List<List<sObject>> fullIndexResult = [find :kwd in all fields returning KnowledgeEntry__c(Id)];
                contentFilteredKnowledge = fullIndexResult[0];
            }   
        }
        String fieldClause = 'select Id, Name, CreatedBy.Name, CreatedBy.LastName, Tags__c, CreatedDate, IsPublished__c, ReadCount__c, LastModifiedDate, CreatedById, LastCommentDate__c, CommentsCount__c from KnowledgeEntry__c';
        String whereClause = '';
        if(kwd != null && kwd != '')
        {
            if(kwd.length() > 1) 
            {
                whereClause = 'where Id in :contentFilteredKnowledge and (IsPublished__c=true or CreatedById=:currentUserId)';
            }   
        }
        else if(author != null && author != '')
        {
            whereClause = 'where CreatedBy.Name=:author and (IsPublished__c=true or CreatedById=:currentUserId)';
        }
        else if(tag != null && tag != '')
        {
            whereClause = 'where Tags__c LIKE \'%'+ tag +'%\' and (IsPublished__c=true or CreatedById=:currentUserId)';
        }
        else
        {
            whereClause = 'where IsPublished__c=true or CreatedById=:currentUserId';
        }
        String orderClause = 'order by IsPublished__c, ';
        if(SortBy == 'count')
        {
            orderClause += 'CommentsCount__c desc';   
        }
        else if(SortBy == 'date')
        {
            orderClause += 'LastCommentDate__c desc';
        }
        else
        {
            orderClause += 'CreatedDate desc';
        }
        String queryString = fieldClause + ' ' + whereClause + ' ' + orderClause;
        this.setController = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
        this.setController.setPageSize(pageSize);
        this.setController.setPageNumber(PageNum);
        KnowledgeEntries = this.setController.getRecords();
    }
    
    public class TagInfo
    {
        public TagInfo() {}
  
        public TagInfo(String name, Integer count)
        {
            this.TagName = name;
            this.TagCount = count;
        }
 
        public Integer TagCount {get; set; }
        public String TagName { get; set; }
        
        //result ranges from green to red
        public String TagColor 
        { 
            get
            {
                Integer index = Math.min(TagCount, 12);
                Integer r = Math.round(255 * index / 12);
                Integer g = 255 - r;
                Integer b = 100;
                return 'rgb(' + r + ',' + g + ',' + b + ')';
            }
        }
        
        // result ranges from 16 to 40
        public Integer TagSize
        {
            get
            {
                Integer index = Math.min(TagCount, 12);
                return Math.round((40 - 16) / 12 * index + 16);
            }
        }
    }
    
    @isTest
    static void testKnowledgeBaseController()
    {
        KnowledgeEntry__c ke = new KnowledgeEntry__c(Name = 'acme', Content__c = 'acme,acme', Tags__c = 'acc,sad');
        insert ke;
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.setCurrentPage(new PageReference('/apex/KnowledgeBaseHome?keyword=acme'));
        controller.setupSetController();
        controller.nextPage();
        controller.prevPage();
        system.assert(controller.TotalKnowledge != null);
        system.assert(controller.TotalPages != null);
        system.assertEquals(controller.HasNextPage, false);
        system.assertEquals(controller.HasPrevPage, false);
    }
}