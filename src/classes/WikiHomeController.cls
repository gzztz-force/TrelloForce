/*
 * A controller for WikiHome Page
 * Display spaces, pages data; add new page; add new space.
 */
public with sharing class WikiHomeController
{
    private ApexPages.StandardSetController popularPagesSet;
    private Integer feedItemCount;
    private Integer feedPageSize;
    private Integer feedPageNum;

    public WikiHomeController()
    {
        NewSpace = new WikiSpace__c();
        HasError = false;
        PopularPages = sortPopularPagesResults();
        feedItemCount = [select count() from WikiPage__Feed where Type in ('TrackedChange', 'TextPost')];
        getUpdateInfo();
        PagesForSearch = [select Id, Title__c, WikiPage__c from WikiPageVersion__c where IsLatestVersion__c = true order by WikiPage__r.LastPublishedDate__c desc limit 50];
    }

    public WikiSpace__c NewSpace { get; set; }
    public Boolean HasError { get; set; }
    public List<WikiPageVersion__c> PagesForSearch { get; set;}
    public List<WikiPage__Feed> FeedItems { get; set;}
    public Boolean HasMoreFeedMark { get; set; }
    public Map<Id,User> IdUserMap { get; set; }
    public Map<String, String> WikiPageField2Type { get; private set;}
    public Id NewSpaceId { get; private set; }
    public List<WikiPageVersion__c> PopularPages { get; set; }

    public Boolean HasNextPopularPages
    {
        get
        {
            return popularPagesSet.getHasNext();
        }
        private set;
    }

    public List<WikiSpace__c> MySpaces
    {
        get
        {   
            if(MySpaces == null)
            {
                MySpaces = [select Name, Summary__c, (select Id from WikiPages__r) from WikiSpace__c order by CreatedDate desc];
            }
            return MySpaces;
        }
        private set;
    }

    public List<WikiPageVersion__c> MyPages
    {
        get
        {
            if(MyPages == null )
            {
                MyPages = [select Title__c, WikiPage__c from WikiPageVersion__c where IsLatestVersion__c = true and CreatedById = :UserInfo.getUserId() order by CreatedDate desc];
            }
            return MyPages;
        }
        private set;
    }

    public Map<String,String> getWikiPageFieldLabelMap()
    {
        if(WikiPageField2Type == null)
        {
            WikiPageField2Type = new Map<String, String>();
        }
        Map<String, String> tempMap= new Map<String, String>();
        List<FieldSetMember> members = SObjectType.WikiPage__c.fieldSets.WikiPageTrack.getFields();
        for(FieldSetmember member : members)
        {
            tempMap.put('WikiPage__c.'+member.getfieldPath(), member.getLabel());
            WikiPageField2Type.put('WikiPage__c.'+member.getfieldPath(), String.valueOf(member.getType()));
        }
        return tempMap;
    }

    public void getUpdateInfo()
    {
        feedPageSize = 10;
        feedPageNum = 1;
        FeedItems = new List<WikiPage__Feed>();
        IdUserMap = new Map<Id,User>();
        loadMoreFeedItems();
    }

    public void loadMorePopularPages()
    {
        if(HasNextPopularPages)
        {
            popularPagesSet.next();
            PopularPages.addAll(sortPopularPagesResults());
        }
    }

    //load more feedItems for "All Update" tab.
    public void loadMoreFeedItems()
    {
        Integer offset = feedPageSize * (feedPageNum -1);
        if(FeedItems.size() < feedItemCount)
        {
            List<WikiPage__Feed> feeds = [select Id, Body, Type, CreatedDate, CreatedById, CreatedBy.Name, Parent.Name, ParentId, Parent.Title__c,
                     (select FieldName, Oldvalue, Newvalue from FeedTrackedChanges) from WikiPage__Feed where Type in ('TrackedChange','TextPost') order by CreatedDate desc  limit :feedPageSize offset :offset];
            FeedItems.addAll(feeds);

            Set<Id> userIds = new Set<Id>();
            for(WikiPage__Feed feed : feeds)
            {
                userIds.add(feed.CreatedByid);
            }
            IdUserMap.putAll(new Map<Id,User>([select Id, FullPhotoUrl from User where Id in :userIds]));
            HasMoreFeedMark = FeedItems.size() < feedItemCount;
            feedPageNum += 1;
        }
    }

    public void createNewSpace()
    {
        try
        {
            insert NewSpace;
            NewSpaceId = NewSpace.Id;
            NewSpace = new WikiSpace__c();
        }
        catch(Exception ex)
        {
            HasError = true;
            ApexPages.addMessages(ex);
        }
    }

    //select wikipages, make them sorted and paged.
    public List<WikiPageVersion__c> sortPopularPagesResults()
    {
        List<WikiPageVersion__c> popularWikiPages = new List<WikiPageVersion__c>();
        if(popularPagesSet == null)
        {
            popularPagesSet = new ApexPages.StandardSetController([select Id, Title__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, WikiPage__r.LastPublishedDate__c, WikiPage__c, WikiPage__r.Post_Count__c
                                                                  from WikiPageVersion__c 
                                                                  where IsLatestVersion__c = true and WikiPage__r.Post_Count__c != null  
                                                                  order by WikiPage__r.Post_Count__c desc, CreatedDate desc]);
            popularPagesSet.setPageSize(12);
        }
        popularWikiPages.addAll((List<WikiPageVersion__c>)popularPagesSet.getRecords());
        return popularWikiPages;
    }

}