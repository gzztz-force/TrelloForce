public with sharing class WikiSpaceController
{
	private String spaceID;
	private String pageID;

	public List<WikiPage__c> wikiPages;
	//public List<WikiPageVersion__c> wikiVersion;
	public List<WikiSpace__c> space;

	public WikiSpaceController()
	{
		//WikiPage = new WikiPage__c();
		//pages = new LIst<WikiPage__c>();
		spaceID = ApexPages.CurrentPage().getParameters().get('Id');
	}

	public WikiPage__c WikiPage { get; set; }
	public WikiPageVersion__c WikiPageVersion { get; set; }

	public List<WikiSpace__c> getSpace()
	{
		space =	[select Id, Name, Name__c, Summary__c from WikiSpace__c 
		where  Id = :spaceID];
		return space;
	}

	public List<WikiPage__c> getWikiPages()
	{
		/*List<WikiPage__c> pages = [select Id, Name, WikiSpace__c, TotalPageVersion__c,
		LastPublishedDate__c,FirstPublishedDate__c, (select Id, Name, Body__c, FirstPublishedDate__c, 
	    IsLatestVersion__c, Label__c, LastPublishedDate__c, PublishStatus__c,
	    Title__c, VersionNumber__c, WikiPage__c from WikiPageVersions__r where IsLatestVersion__c = true ) from WikiPage__c 
		where WikiSpace__c = :spaceID];*/

		List<WikiPage__c> pages = [select Id, Name, WikiSpace__c, TotalPageVersion__c,
		LastPublishedDate__c,FirstPublishedDate__c, (select Id, Name, Body__c, FirstPublishedDate__c, 
	    IsLatestVersion__c, Label__c, LastPublishedDate__c, PublishStatus__c,
	    Title__c, VersionNumber__c, WikiPage__c from WikiPageVersions__r order by VersionNumber__c desc) from WikiPage__c 
		where WikiSpace__c = :spaceID];

		return pages != null ? pages : new List<WikiPage__c>();
	}

}