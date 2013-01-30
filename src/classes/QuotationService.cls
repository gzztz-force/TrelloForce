/*
 * Includes service methods for Quote object
 */
global class QuotationService 
{
    webservice static String cloneQuote(String quoteId)
    {
    	List<Quote__c> quotes = [select Id, DisplayAmount__c, Currency__c, UnitPrice__c, Project__c, Description__c,
    							(select Amount__c, IsAdditional__c, SortOrder__c, Task__c, Unit__c from QuoteLines__r)  
    							from Quote__c where Id=:quoteId limit 1];
    	if(quotes.size() > 0)
    	{
    		Quote__c newQuote = quotes[0].clone(false, false, false, false);
    		insert newQuote;
    		List<QuoteLine__c> newLines = new List<QuoteLine__c>();
    		for(QuoteLine__c line : quotes[0].QuoteLines__r)
    		{
    			newLines.add(new QuoteLine__c(Quote__c=newQuote.Id, Amount__c=line.Amount__c, IsAdditional__c=line.IsAdditional__c, SortOrder__c=line.SortOrder__c, Task__c=line.Task__c, Unit__c=line.Unit__c));
    		}
    		if(newLines.size() > 0)
    		{
    			insert newLines;
    		}
    		return newQuote.Id; 
    	}
    	return null;
    }
    
    @isTest
    static void testCloneQuote()
    {
    	Quote__c quote = new Quote__c();
    	insert quote;
    	cloneQuote(quote.Id);
    }
}