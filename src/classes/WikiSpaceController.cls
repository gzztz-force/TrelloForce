public with sharing class WikiSpaceController
{
	private String spaceID;
	private String pageID;

	public List<WikiPage__c> WikiPages { get; set; }
	//public List<WikiPageVersion__c> wikiVersion;
	public List<WikiSpace__c> space;

	private ApexPages.StandardSetController wikiPageSet;
	public Boolean HasNext { get; set; }
	public Boolean HasPrevious { get; set; }
	public Integer CurrentPage { get; set; }
	public Integer PageSize { get; set; }
	public Integer PageNum { get; set; }

	public WikiSpaceController()
	{
		//WikiPage = new WikiPage__c();
		//pages = new LIst<WikiPage__c>();
		spaceID = ApexPages.CurrentPage().getParameters().get('Id');
		initSpaceSet();
		
	}

	public WikiPage__c WikiPage { get; set; }
	public WikiPageVersion__c WikiPageVersion { get; set; }

	public List<WikiSpace__c> getSpace()
	{
		space =	[select Id, Name, Name__c, Summary__c from WikiSpace__c 
		where  Id = :spaceID];
		return space;
	}
	public String getSpaceId()
	{
		return spaceID;
	}

	
	public void nextWikiPages()
	{
		wikiPageSet.next();
		WikiPages = (List<WikiPage__c>) wikiPageSet.getRecords();

		HasPrevious = wikiPageSet.getHasPrevious();
		HasNext = wikiPageSet.getHasNext();
		CurrentPage = wikiPageSet.getPageNumber();
	}

	
	public void priviousWikiPages()
	{
		wikiPageSet.previous();
		WikiPages = (List<WikiPage__c>) wikiPageSet.getRecords();

		HasPrevious = wikiPageSet.getHasPrevious();
		HasNext = wikiPageSet.getHasNext();
		CurrentPage = wikiPageSet.getPageNumber();
	}

	private void initSpaceSet()
	{
		PageSize = 4;
		wikiPageSet = new ApexPages.StandardSetController([select Id, Name, WikiSpace__c, TotalPageVersion__c,
		LastPublishedDate__c,FirstPublishedDate__c, (select Id, Name, Body__c, FirstPublishedDate__c, 
	    IsLatestVersion__c, Label__c, LastPublishedDate__c, PublishStatus__c,
	    Title__c, VersionNumber__c, WikiPage__c from WikiPageVersions__r order by VersionNumber__c desc limit 4) from WikiPage__c 
		where WikiSpace__c = :spaceID]);
		wikiPageSet.setPageSize(pageSize);
		WikiPages = (List<WikiPage__c>) wikiPageSet.getRecords();

		HasPrevious = wikiPageSet.getHasPrevious();
		HasNext = wikiPageSet.getHasNext();
		CurrentPage = wikiPageSet.getPageNumber();

		PageNum = (Integer)(Math.round(wikiPageSet.getResultSize()/wikiPageSet.getPageSize())+1);
	}

}