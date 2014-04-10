/*
 * controller for WikiHome Page
 * display spaces, pages data; add new page; add new space.
 */
public with sharing class WikiHomeController
{
     

    public WikiSpace__c NewSpace { get; set; }
    public Boolean HasError { get; set; }
    public Id FavorSpaceId { get; set; }

    //added by ray 
    public List<PopularWikiPage> MyPopularPages { get; set; }
    private ApexPages.StandardSetController popularPagesSet;
    public Boolean HasMorePageMark { get; set; }
    

    public List<WikiPageVersion__c> PagesForSearch { get; set;}
    public String SearchKey { get; set; }
    public String testStr { get; set; }

    public List<WikiPage__Feed> FeedItems { get; set;}
    private Integer feedItemCount;
    private Integer feedPageSize;
    private Integer feedPageNum;
    public Boolean HasMoreFeedMark { get; set; }
    public Map<Id,User> IdUserMap { get; set; }
    
    public WikiHomeController()
    {
        NewSpace = new WikiSpace__c();
        initPopularPages();
        HasError = false;
        feedItemCount = [select Id from WikiPage__Feed where Type in ('TrackedChange','TextPost')].size();       
        getUpdateInfo();
        PagesForSearch = [SELECT Id, Title__c, WikiPage__c FROM WikiPageVersion__c WHERE IsLatestVersion__c = true order by WikiPage__r.LastPublishedDate__c DESC];
    }

    public List<WikiSpace__c> getMySpaces()
    {
        return [select Name, Summary__c, (select Id from WikiPages__r), (select id from BookMarks__r where CreatedById = :UserInfo.getUserId()) from WikiSpace__c order by CreatedDate desc];
    }

    public List<WikiPageVersion__c> getMyPages()
    {
        return [select Title__c, WikiPage__c from WikiPageVersion__c WHERE IsLatestVersion__c = true AND CreatedById = :UserInfo.getUserId()];
    }

    private void initPopularPages()
    {           
        popularPagesSet = new ApexPages.StandardSetController([select id ,(SELECT Id, Title__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, wikipage__r.LastPublishedDate__c FROM WikiPageVersions__r WHERE IsLatestVersion__c = true),
                                    (select Id,CommentCount from feeds) from WikiPage__c order by LastPublishedDate__c desc]);
        popularPagesSet.setPageSize(10);
        List<WikiPage__c> pages = (List<WikiPage__c>)popularPagesSet.getRecords();
        MyPopularPages = new List<PopularWikiPage>();
        for(WikiPage__c page : pages)
        {
            Integer i = 0;
            for(WikiPage__Feed wikiPageFeed : page.feeds)
            {
                i += wikiPageFeed.CommentCount + 1;
            }
            MyPopularPages.add(new PopularWikiPage(page.WikiPageVersions__r[0],i));
        }
        HasMorePageMark = popularPagesSet.getHasNext();
    }
    public void getUpdateInfo()
    {        
        feedPageSize = 8;
        feedPageNum = 1;
        FeedItems = new List<WikiPage__Feed>();
        IdUserMap = new Map<Id,User>();
        loadMoreFeedItemsAction();
        /*
        
        List<Topic> topics = [select Id from Topic where name = 'Wiki' limit 1];
        if(topics.size() > 0)
        {
           Set<Id> feedItemIds = new Set<Id>();
           List<TopicAssignment> topicAssignments = [select EntityId from TopicAssignment where TopicId =:topics[0].Id Limit 100];
           for(TopicAssignment topicAssignment : topicAssignments)
           {
               feedItemIds.add(topicAssignment.EntityId);
           }
           feedItemSet = new ApexPages.StandardSetController([select Id, Body, Type, CreatedDate, CreatedByid, CreatedBy.Name, Parent.Name, ParentId, Parent.Title__c, 
                     (select FieldName, Oldvalue, Newvalue from FeedTrackedChanges) from WikiPage__Feed where Id in :feedItemIds order by CreatedDate desc]);
           feedItemSet.setPageSize(5);

           FeedItems = (List<WikiPage__Feed>)feedItemSet.getRecords();
           HasMoreFeedMark = feedItemSet.getHasNext();

           Set<Id> userIds = new Set<Id>();
           
           for(WikiPage__Feed feedItem : FeedItems)
           {
               userIds.add(feedItem.CreatedByid);
           }
           
           IdUserMap = new Map<Id,User>([select Id,FullPhotoUrl from User where Id in :userIds]);
        }
       else
       {
           Topic topic = new Topic();
           topic.Name = 'wiki';
           insert topic;
       }*/       
    } 

    
    public void loadMorePopularPagesAction()
    {
        
        if(HasMorePageMark)
        {
            popularPagesSet.next();
            HasMorePageMark = popularPagesSet.getHasNext();
            List<WikiPage__c> pages = (List<WikiPage__c>)popularPagesSet.getRecords();
            for(WikiPage__c page : pages)
            {
                Integer i = 0;
                for(WikiPage__Feed wikiPageFeed : page.feeds)
                {
                    i += wikiPageFeed.CommentCount + 1;
                }
                MyPopularPages.add(new PopularWikiPage(page.WikiPageVersions__r[0],i));
            }
        }
    }
    public void loadMoreFeedItemsAction()
    {
        Integer offset = feedPageSize * (feedPageNum -1); 
        HasMoreFeedMark = feedPageNum < ((feedItemCount-1)/feedPageSize + 1);
        if(HasMoreFeedMark)
        {
            List<WikiPage__Feed> feeds = [select Id, Body, Type, CreatedDate, CreatedByid, CreatedBy.Name, Parent.Name, ParentId, Parent.Title__c, 
                     (select FieldName, Oldvalue, Newvalue from FeedTrackedChanges) from WikiPage__Feed where Type in ('TrackedChange','TextPost') order by CreatedDate desc  limit :feedPageSize offset :offset];
            FeedItems.addAll(feeds);

            Set<Id> userIds = new Set<Id>();           
            for(WikiPage__Feed feed : feeds)
            {
                userIds.add(feed.CreatedByid);
            }           
            IdUserMap.putAll(new Map<Id,User>([select Id,FullPhotoUrl from User where Id in :userIds])); 
            feedPageNum += 1; 
        }
    }
    public void favorSpace()
    {
        for(WikiSpace__c space : getMySpaces())
        {
            if(FavorSpaceId == space.Id)
            {
                if(space.BookMarks__r.size() == 0)
                {
                    insert new BookMark__c(Space__c = space.Id,WhatId__c = 'whatid',ParentSobjectType__c='ParentSobjectType_');
                }
                break;
            }
        }
    }

    public void unFavorSpace()
    {
        for(WikiSpace__c space : getMySpaces())
        {
            if(FavorSpaceId == space.Id)
            {
                if(space.BookMarks__r.size() > 0)
                {
                    delete space.BookMarks__r[0];
                }
                break;
            }
        }
    }
    public void createNewSpace()
    {
        HasError = false;
        try
        {
            insert NewSpace;
            NewSpace = new WikiSpace__c();
        }
        catch(Exception ex)
        {
            HasError = true;
            ApexPages.addMessages(ex);
        }
    }
    public List<BookMark__c> getFavoriteSpaces()
    {
        return [select id,Space__c, space__r.Name,space__r.Summary__c from BookMark__c where CreatedBy.Id = :UserInfo.getUserId() order by CreatedDate desc];
    }

    //added by ray: search wikipage
    public void searchWikiPageAction()
    {
        if(String.isNotBlank(SearchKey))
        {
            String searchKeyTemp = '%' + SearchKey + '%';

            PagesForSearch = [SELECT Id, Title__c, WikiPage__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, WikiPage__r.LastPublishedDate__c   
                                                               FROM WikiPageVersion__c WHERE IsLatestVersion__c = true and (Title__c like :searchKeyTemp or Tag__c like :searchKeyTemp) ORDER BY WikiPage__r.LastPublishedDate__c DESC limit 100];
        }
        else
        {
            PagesForSearch = new List<WikiPageVersion__c>();
        }
    }

    public void testStrMethod()
    {
        testStr = 'testStr init';
    }

    public class PopularWikiPage
    {
        public WikiPageVersion__c WikiPageVersion { get; set; }
        public Integer FeedComment { get; set; }

        public PopularWikiPage(WikiPageVersion__c WikiPageVer,Integer feedComment)
        {
            this.WikiPageVersion = WikiPageVer;
            this.FeedComment = feedComment;
        }
    }
}