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
    private List<PopularWikiPage> popularPages;

    public WikiHomeController()
    {
        NewSpace = new WikiSpace__c();
        HasError = false;
        popularPages = getPopularPagesResult();
        feedItemCount = [select count() from WikiPage__Feed where Type in ('TrackedChange','TextPost')];
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

    public Boolean HasNextPopularPages
    {
        get
        {
            return popularPagesSet.getHasNext();
        }
        private set;
    }

    public List<WikiSpace__c> getMySpaces()
    {
        return [select Name, Summary__c, (select Id from WikiPages__r) from WikiSpace__c order by CreatedDate desc];
    }

    public List<WikiPageVersion__c> getMyPages()
    {
        return [select Title__c, WikiPage__c from WikiPageVersion__c where IsLatestVersion__c = true and CreatedById = :UserInfo.getUserId() order by CreatedDate desc];
    }

    public void getUpdateInfo()
    {
        feedPageSize = 10;
        feedPageNum = 1;
        FeedItems = new List<WikiPage__Feed>();
        IdUserMap = new Map<Id,User>();
        loadMoreFeedItemsAction();
    }

    public void loadMorePopularPagesAction()
    {
        if(HasNextPopularPages)
        {
            popularPagesSet.next();
            popularPages.addAll(getPopularPagesResult());
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
            IdUserMap.putAll(new Map<Id,User>([select Id, FullPhotoUrl from User where Id in :userIds]));
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
            NewSpaceId = NewSpace.Id;
            NewSpace = new WikiSpace__c();
        }
        catch(Exception ex)
        {
            HasError = true;
            ApexPages.addMessages(ex);
        }
    }

    public List<PopularWikiPage> getPopularPages()
    {
        PopularPages.sort();
        return PopularPages;
    }

    private List<PopularWikiPage> getPopularPagesResult()
    {
        List<PopularWikiPage> popularWikiPages = new List<PopularWikiPage>();

        if(popularPagesSet == null)
        {
            popularPagesSet = new ApexPages.StandardSetController([select Id,
                            (select Id, Title__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, wikipage__r.LastPublishedDate__c
                                 from WikiPageVersions__r where IsLatestVersion__c = true),
                            (select Id, CommentCount, LikeCount from Feeds) from WikiPage__c order by LastPublishedDate__c desc]);
            popularPagesSet.setPageSize(12);
        }

        List<WikiPage__c> pages = (List<WikiPage__c>)popularPagesSet.getRecords();

        for(WikiPage__c page : pages)
        {
            Integer i = 0;
            for(WikiPage__Feed wikiPageFeed : page.feeds)
            {
                i += wikiPageFeed.CommentCount + wikiPageFeed.LikeCount + 1;
            }
            popularWikiPages.add(new PopularWikiPage(page.WikiPageVersions__r[0],i));
        }
        return popularWikiPages;
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

    public class PopularWikiPage implements Comparable
    {
        public WikiPageVersion__c WikiPageVersion { get; set; }
        public Integer FeedComment { get; set; }

        public PopularWikiPage(WikiPageVersion__c WikiPageVer, Integer feedComment)
        {
            this.WikiPageVersion = WikiPageVer;
            this.FeedComment = feedComment;
        }

        public Integer compareTo(Object compareTo)
        {
            PopularWikiPage compareToEmp = (PopularWikiPage)compareTo;

            if(FeedComment == compareToEmp.FeedComment) return 0;
            if(FeedComment < compareToEmp.FeedComment) return 1;
            return -1;
        }
    }
}