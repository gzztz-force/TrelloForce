public class WiKiSearchController
{
    private List<WiKiPageVersion__c> wikiPages;
    private ApexPages.StandardSetController standardSetController;

    public WiKiSearchController()
    {
        Key = ApexPages.currentPage().getParameters().get('key');
        if(Key != null && Key.length() > 1)
        {
            getFirstWiKiPages();
        }
        else
        {
            PageNumber = 0;
            Results = 0;
            wikiPages = new List<WiKiPageVersion__c>();
            MyWiKiPages = new List<MyWiKiPage>();
        }
        initPopularPage();
    }

    public String Key { get; set; }
    public List<MyWiKiPage> MyWiKiPages { get; set; }
    public List<PopularPage> PopularPages { get; set; }
    public List<Integer> Links { get; set; }
    public Integer PageNumber { get; set; }
    public Integer Results { get; set; }

    public void initPopularPage()
    {
        List<AggregateResult> results = [select ParentId, count(Id) FeedItems, sum(commentcount) Comments, sum(likecount) Likes
            from WiKiPage__Feed group by ParentId order by count(Id) desc, sum(commentcount) desc, sum(likecount) desc limit 10];
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
        Key = Key.trim();
        String keyword  = getQueryKeyword();
        standardSetController = new ApexPages.StandardSetController(
                [Find :keyword In All Fields Returning WiKiPageVersion__c
                    (WikiPage__c, wikiPage__r.Wikispace__r.Name__c, wikiPage__r.WikiSpace__c, WikiPage__r.LastPublishedDate__c, Title__c, Body__c, CreatedDate Where IsLatestVersion__c = true order by CreatedDate desc)].get(0));
        PageNumber = 1;
        Results = standardSetController.getResultSize();
        standardSetController.setPageSize(10);
        standardSetController.first();
        wikiPages = standardSetController.getRecords();
        createMyWiKiPage();
        setLinks();
    }

    public void setLinks()
    {
        Links = new List<Integer>();
        for(Integer i = 1; i <= Math.ceil((Decimal)Results / 10); i++)
        {
            Links.add(i);
            if(i == 10)
            {
                break;
            }
        }
    }

    public void resetLinks()
    {
        if(Results > 100)
        {
            Links = new List<Integer>();
            if(PageNumber <= 5)
            {
                setLinks();
            }
            else if((PageNumber * 10 + 30) >= Results)
            {
                Integer diffValue = Results - PageNumber * 10;
                if(diffValue > 0 && diffValue <= 10)
                {
                    for(Integer i = PageNumber - 9; i < PageNumber + 1; i++)
                    {
                        Links.add(i);
                    }
                }
                else if(diffValue > 10 && diffValue <= 20)
                {
                    for(Integer i = PageNumber - 8; i < PageNumber + 2; i++)
                    {
                        Links.add(i);
                    }
                }
                else
                {
                    for(Integer i = PageNumber - 7; i < PageNumber + 3; i++)
                    {
                        Links.add(i);
                    }
                }
            }
            else
            {
                for(Integer i = PageNumber - 5; i < PageNumber + 4; i++)
                {
                    Links.add(i);
                }
            }
        }
    }

    public String getQueryKeyword()
    {
        String queryKey = Key;
        if(queryKey.contains('*'))
        {
            queryKey = queryKey.replaceAll('[*]', '\\\\*');
        }
        if(queryKey.contains('?'))
        {
            queryKey = queryKey.replaceAll('[?]', '\\\\?');
        }
        if(queryKey.containsWhitespace())
        {
            String[] keys = queryKey.split(' ');
            String keyword = '\'' + keys[0] + '*';
            for(Integer i = 1; i < keys.size(); i++)
            {
                keyword += ' and ' + keys[i] + '*';
            }
            keyword += '\'';
            return keyword;
        }
        else
        {
            return queryKey + '*';
        }
    }

    public void createMyWiKiPage()
    {
        MyWiKiPages = new List<MyWiKiPage>();
        String word = Key;
        if(Key.containsWhitespace())
        {
            word = Key.split(' ').get(0);
        }
        for(WiKiPageVersion__c page : wikiPages)
        {
            MyWiKiPage mypage = new MyWiKiPage();
            mypage.Id = page.WikiPage__c;
            mypage.Title = page.Title__c;

            mypage.SpaceName = page.WikiPage__r.WikiSpace__r.Name__c;
            mypage.SpaceId = page.WikiPage__r.Wikispace__c;
            mypage.lastPublishedDate = page.WikiPage__r.lastPublishedDate__c;
            String content = page.Body__c;
            if(content != null)
            {
                if(content.contains(word))
                {
                    Integer index = content.indexOf(word);
                    String before = content.substringBefore(word);
                    Integer offset = before.length() > 100 ? before.length() - 100 : 0;
                    mypage.Body = content.abbreviate(200, offset);
                }
                else
                {
                    mypage.Body = content.abbreviate(200);
                }
            }
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

    public void paging()
    {
        standardSetController.setPageNumber(PageNumber);
        wikiPages = standardSetController.getRecords();
        createMyWiKiPage();
        resetLinks();
    }

    public void previous()
    {
        if(standardSetController.getHasPrevious())
        {
            PageNumber--;
            standardSetController.previous();
            wikiPages = standardSetController.getRecords();
            createMyWiKiPage();
            resetLinks();
        }
    }

    public void next()
    {
        if(standardSetController.getHasNext())
        {
            PageNumber++;
            standardSetController.next();
            wikiPages = standardSetController.getRecords();
            createMyWiKiPage();
            resetLinks();
        }
    }

    private class MyWiKiPage
    {
        public String Id { get; set; }
        public String Title { get; set; }
        public String Body { get; set; }
        public String SpaceName { get; set; }
        public Id SpaceId { get; set; }
        public Datetime LastPublishedDate { get; set; }
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