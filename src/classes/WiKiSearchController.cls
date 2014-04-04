public with sharing class WiKiSearchController 
{
	public WiKiSearchController() 
	{
		
	}

	public String Key { get; set; }
	public List<WiKiPageVersion__c> Versions { get; set; }

	public void search()
	{
		Versions = [Find :Key+'*' In All Fields Returning WiKiPageVersion__c(Title__c, Body__c Where IsLatestVersion__c = true)].get(0);
	}
}