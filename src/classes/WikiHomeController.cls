/*
 * controller for WikiHome Page
 * display spaces, pages data; add new page; add new space.
 */
public with sharing class WikiHomeController
{
    private ApexPages.StandardSetController popularPagesSet;
    private Integer feedItemCount;    
    private Integer feedPageSize;
    private Integer feedPageNum;

    public WikiSpace__c NewSpace { get; set; }
    public Boolean HasError { get; set; }
    public Id FavorSpaceId { get; set; }
    private List<PopularWikiPage> MyPopularPages; 
    public Boolean HasMorePageMark { get; set; }
    public List<WikiPageVersion__c> PagesForSearch { get; set;}
    public String SearchKey { get; set; }
    public String testStr { get; set; }
    public List<WikiPage__Feed> FeedItems { get; set;}    
    public Boolean HasMoreFeedMark { get; set; }
    public Map<Id,User> IdUserMap { get; set; }
    
    public WikiHomeController()
    {
        NewSpace = new WikiSpace__c();
        initPopularPages();
        HasError = false;
        feedItemCount = [select Id from WikiPage__Feed where Type in ('TrackedChange','TextPost')].size();       
        getUpdateInfo();
        PagesForSearch = [select Id, Title__c, WikiPage__c from WikiPageVersion__c where IsLatestVersion__c = true order by WikiPage__r.LastPublishedDate__c desc];
    }

    public List<WikiSpace__c> getMySpaces()
    {
        return [select Name, Summary__c, (select Id from WikiPages__r) from WikiSpace__c order by CreatedDate desc];
    }

    public List<WikiPageVersion__c> getMyPages()
    {
        return [select Title__c, WikiPage__c from WikiPageVersion__c WHERE IsLatestVersion__c = true AND CreatedById = :UserInfo.getUserId()];
    }

    private void initPopularPages()
    {           
        popularPagesSet = new ApexPages.StandardSetController([select id ,(SELECT Id, Title__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, wikipage__r.LastPublishedDate__c FROM WikiPageVersions__r WHERE IsLatestVersion__c = true),
                                    (select Id,CommentCount, LikeCount from feeds) from WikiPage__c order by LastPublishedDate__c desc]);
        popularPagesSet.setPageSize(10);
        List<WikiPage__c> pages = (List<WikiPage__c>)popularPagesSet.getRecords();
        MyPopularPages = new List<PopularWikiPage>();
        for(WikiPage__c page : pages)
        {
            Integer i = 0;
            for(WikiPage__Feed wikiPageFeed : page.feeds)
            {
                i += wikiPageFeed.CommentCount + wikiPageFeed.LikeCount + 1;
            }
            MyPopularPages.add(new PopularWikiPage(page.WikiPageVersions__r[0],i));
        }
        HasMorePageMark = popularPagesSet.getHasNext();
    }

    public void getUpdateInfo()
    {        
        feedPageSize = 10;
        feedPageNum = 1;
        FeedItems = new List<WikiPage__Feed>();
        IdUserMap = new Map<Id,User>();
        loadMoreFeedItemsAction();
    } 

    public List<PopularWikiPage> getMyPopularPages()
    {
        Integer count = MyPopularPages.size();
        for(Integer i = 0; i < count - 1; i++)
        {
            for(Integer j = 0; j < count-i-1; j++)
            {
                if(MyPopularPages[j].FeedComment < MyPopularPages[j+1].FeedComment)
                {
                    PopularWikiPage temp = MyPopularPages[j];
                    MyPopularPages[j] = MyPopularPages[j+1];
                    MyPopularPages[j+1] = temp;
                }
            }
        }
        return MyPopularPages;
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
                    i += wikiPageFeed.CommentCount + wikiPageFeed.LikeCount + 1;
                }
                MyPopularPages.add(new PopularWikiPage(page.WikiPageVersions__r[0],i));
            }
        }
    }

    public void loadMoreFeedItemsAction()
    {
        Integer offset = feedPageSize * (feedPageNum -1); 
        if(FeedItems.size() < feedItemCount)
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
            HasMoreFeedMark = FeedItems.size() < feedItemCount;
            feedPageNum += 1; 
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