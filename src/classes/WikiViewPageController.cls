/**
 * A controller for WikiViewPage
 */
public with sharing class WikiViewPageController
{
    private String pageId;
    public PublishedPage PubPage { get; set; }
    public Boolean IsVoted { get; set; } 
    public String VoteParam { get; set; }
    Public String testStr { get; set; }

    public WikiViewPageController()
    {
        IsVoted = false;
        pageId = ApexPages.currentPage().getParameters().get('id');
        getPubishedPage();
    }    

    private void getPubishedPage()
    {
        List<WikiPage__c> publishedPages = [select Id, WikiSpace__r.Name,WikiSpace__c, CreatedById, LastModifiedById, LastPublishedDate__c,
                                            (select Id, Body__c, Label__c, Title__c, CreatedById,LikeVotes__c, UnlikeVotes__c, LastModifiedDate from WikiPageVersions__r
                                             where IsLatestVersion__c = true)
                                           from WikiPage__c where Id = :pageId];
        if(publishedPages.size() > 0)
        {
            PubPage = new PublishedPage(publishedPages[0]);  

            List<VoteForPage__c> votes = [select Id from VoteForPage__c where WikiPageVersion__c =:PubPage.WikiPageVersion.Id and CreatedById =: UserInfo.getUserId()];

            if(votes.size() > 0)
            {
                IsVoted = true;
            }       
        }        
    }

    public void vote()
    {
        try
        {
            if(!isVoted && VoteParam != null)
            {
                VoteForPage__c votePage = new VoteForPage__c();
                votePage.LikeOrNotLike__c = VoteParam.toLowerCase();
                votePage.WikiPageVersion__c = PubPage.WikiPageVersion.Id;
                insert votePage;
                IsVoted = true;

                if(VoteParam.equalsIgnoreCase('like'))
                {
                    PubPage.WikiPageVersion.LikeVotes__c = PubPage.WikiPageVersion.LikeVotes__c == null ? 1 : PubPage.WikiPageVersion.LikeVotes__c + 1;
                }
                else if(VoteParam.equalsIgnoreCase('unlike'))
                {
                    PubPage.WikiPageVersion.UnlikeVotes__c = PubPage.WikiPageVersion.UnlikeVotes__c == null ? 1 : PubPage.WikiPageVersion.UnlikeVotes__c + 1;
                }
                update PubPage.WikiPageVersion;
            }
        }
        catch(Exception e3)
        {
            
        }
        
    }

    public List<WikiPageVersion__c> getVoteData() 
    {
         return [select Id, VersionNumber__c, LikeVotes__c, UnlikeVotes__c from WikiPageVersion__c where WikiPage__c =:PubPage.WikiPage.Id order by VersionNumber__c asc limit 4];
    }
    
    public class PublishedPage
    {
        public PublishedPage(WikiPage__c wikiPage)
        {
            this.WikiPage = wikiPage;
            this.WikiPageVersion = wikiPage.WikiPageVersions__r[0];
        }

        public WikiPage__c WikiPage { get; set; }
        public WikiPageVersion__c WikiPageVersion { get; set; }
    }
}