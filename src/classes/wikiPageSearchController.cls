public with sharing class wikiPageSearchController 
{
	private ApexPages.StandardSetController searchPageSet;

	public String SearchKey { get; set; }
	public List<WikiPageVersion__c> SearchPages { get; set; }

	public wikiPageSearchController() 
	{
		SearchKey = ApexPages.currentPage().getParameters().get('searchkey');
		if(String.isBlank(SearchKey))
		{
			SearchPages = new List<WikiPageVersion__c>();
		}
		else
		{
			SearchWikiPage();
		}
		
	}

	public void SearchWikiPage()
	{
		if(String.isNotBlank(SearchKey))
        {
            String searchKeyTemp = '%' + SearchKey + '%';

            searchPageSet = new ApexPages.StandardSetController([SELECT Id, Title__c, WikiPage__c, CreatedById, CreatedBy.Name, CreatedBy.FullPhotoUrl, WikiPage__r.LastPublishedDate__c   
                                                               FROM WikiPageVersion__c WHERE IsLatestVersion__c = true and (Title__c like :searchKeyTemp or Tag__c like :searchKeyTemp) ORDER BY WikiPage__r.LastPublishedDate__c DESC limit 100]);
       		searchPageSet.setPageSize(10);
       		SearchPages = (List<WikiPageVersion__c>)searchPageSet.getRecords();
        }       
	}
	public void nextPageOfWikiPageVersion()
	{
		if(searchPageSet.getHasNext())
		{
			searchPageSet.next();
			SearchPages = (List<WikiPageVersion__c>)searchPageSet.getRecords();
		}
	}
	public void previousPageOfWikiPageVersion()
	{
		if(searchPageSet.getHasPrevious())
		{
			searchPageSet.previous();
			SearchPages = (List<WikiPageVersion__c>)searchPageSet.getRecords();
		}
	}
}