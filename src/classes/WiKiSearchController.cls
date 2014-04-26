public with sharing class WiKiSearchController 
{

    public WiKiSearchController() 
    {
        Key = ApexPages.currentPage().getParameters().get('key');
        if(Key != null && Key.length() > 1)
        {
            getFirstWiKiPages();
        }
        else
        {
            WikiPages = new List<WiKiPageVersion__c>();
            MyWiKiPages = new List<MyWiKiPage>();
        }
        initPopularPage();
    } 

    public String Key { get; set; }
    public List<WiKiPageVersion__c> WikiPages { get; set; }
    public List<MyWiKiPage> MyWiKiPages { get; set; }
    public List<PopularPage> PopularPages { get; set; }
    public Datetime FirstCursor { get; set; }
    public Datetime PreviousCursor { get; set; }
    public Datetime NextCursor { get; set; }

    public void initPopularPage()
    {
        List<AggregateResult> results = [select ParentId, count(Id) FeedItems, sum(commentcount) Comments, sum(likecount) Likes from WiKiPage__Feed group by ParentId order by count(Id) desc, sum(commentcount) desc, sum(likecount) desc limit 10];
        Set<Id> pageIds = new Set<Id>();
        PopularPages = new List<PopularPage>();
        for(AggregateResult result : results)
        {
            pageIds.add((Id)result.get('ParentId'));

            PopularPage popular = new PopularPage();
            popular.Id = (String)result.get('ParentId');
            popular.FeedItems = Integer.valueOf(result.get('FeedItems'));
            popular.Comments = Integer.valueOf(result.get('Comments'));
            popular.Likes = Integer.valueOf(result.get('Likes'));
            PopularPages.add(popular);
        }
        List<WiKiPage__c> Pages = [select Id, Title__c from WiKiPage__c where Id in :pageIds];
        for(PopularPage popular : PopularPages)
        {
            for(WiKiPage__c page : Pages)
            {
                if(popular.Id == page.Id)
                {
                    popular.Title = page.Title__c;
                    break;
                }
            }
        }

    }

    public void getFirstWiKiPages()
    {
        WikiPages = [Find :Key+'*' In All Fields Returning WiKiPageVersion__c(WikiPage__c, Title__c, Body__c, CreatedDate Where IsLatestVersion__c = true order by CreatedDate desc) limit 11].get(0);
        PreviousCursor = null;
        if(WiKiPages.size() == 11)
        {
            FirstCursor = WikiPages[0].CreatedDate;
            NextCursor = WiKiPages[10].CreatedDate;
            WiKiPages.remove(10);
        }
        else
        {
            NextCursor = null;
        }
        createMyWiKiPage(WikiPages);
    }

    public void createMyWiKiPage(List<WiKiPageVersion__c> wikiPages)
    {
        MyWiKiPages = new List<MyWiKiPage>();
        for(WiKiPageVersion__c page : wikiPages)
        {
            MyWiKiPage mypage = new MyWiKiPage();
            mypage.Id = page.WikiPage__c;
            mypage.Title = page.Title__c;
            String content = page.Body__c;
            Integer index = content.indexOf(Key);
            String before = content.substringBefore(Key);
            Integer offset = before.length() > 100 ? before.length() - 100 : 0;
            mypage.Body = content.abbreviate(200, offset);
            MyWiKiPages.add(mypage);
        }
    }

    public void search()
    {
        if(Key != null && Key.length() > 1)
        {
            getFirstWiKiPages();
        }
    }

    public void previous()
    {
        WikiPages = [Find :Key+'*' In All Fields Returning WiKiPageVersion__c(WikiPage__c, Title__c, Body__c, CreatedDate Where IsLatestVersion__c = true and CreatedDate > :PreviousCursor order by CreatedDate asc) limit 10].get(0);
        NextCursor = PreviousCursor;
        PreviousCursor = (FirstCursor == WikiPages[9].CreatedDate) ? null : WiKiPages[9].CreatedDate;
        for(Integer i = 0; i < 5; i++)
        {
            WiKiPageVersion__c tempWiki = WikiPages[i];
            WikiPages[i] =  WikiPages[9 - i];
            WikiPages[9 - i] = tempWiki;
        }
        createMyWiKiPage(WikiPages);
    }

    public void next()
    {
        WikiPages = [Find :Key+'*' In All Fields Returning WiKiPageVersion__c(WikiPage__c, Title__c, Body__c, CreatedDate Where IsLatestVersion__c = true and CreatedDate <= :NextCursor order by CreatedDate desc) limit 11].get(0);
        PreviousCursor = NextCursor;
        if(WikiPages.size() == 11)
        {
            NextCursor = WikiPages[10].CreatedDate;
            WikiPages.remove(10);
        }
        else
        {
            NextCursor = null;
        }
        createMyWiKiPage(WikiPages);
    }

    private class MyWiKiPage
    {
        public String Id { get; set; }
        public String Title { get; set; }
        public String Body { get; set; }
    }

    private class PopularPage
    {
        public String Id { get; set; }
        public String Title { get; set; }
        public Integer FeedItems { get; set; }
        public Integer Comments { get; set; }
        public Integer Likes { get; set; }
    }
}