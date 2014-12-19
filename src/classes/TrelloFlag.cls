global with sharing class TrelloFlag 
{
	global TrelloFlag() 
	{
		IsBatchFired = true;
	}
		
	global static Boolean IsBatchFired = true;
}