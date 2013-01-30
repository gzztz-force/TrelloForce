/*
 * Controller of page QuotePrint
 */
public with sharing class QuotePrintController 
{
    private Quote__c quoteRecord;
    
    public QuotePrintController(ApexPages.StandardController controller) 
    {
        quoteRecord = (Quote__c)controller.getRecord();
    }
    
    public List<QuoteLine__c> StandardLines
    {
        get
        {
            return [select Id, Name, Task__c, SortOrder__c, Amount__c, Unit__c from QuoteLine__c where Quote__c=:quoteRecord.Id and IsAdditional__c=false order by SortOrder__c];
        }
    }
    
    public List<QuoteLine__c> AdditionalLines
    {
        get
        {
            return [select Id, Name, Task__c, SortOrder__c, Amount__c, Unit__c from QuoteLine__c where Quote__c=:quoteRecord.Id and IsAdditional__c=true order by SortOrder__c];
        }
    }
    
    public String StandardUnit
    {
        get
        {
            if(StandardLines.size() > 0)
            {
                return StandardLines[0].Unit__c;
            }
            else
            {
                return '';
            }
        }
    }
    
    public Decimal Total
    {
        get
        {
            Decimal result = 0;
            if(quoteRecord.DisplayAmount__c == true)
            {
                for(QuoteLine__c line : StandardLines)
                {
                    if(line.Unit__c == 'Hours' || line.Unit__c == 'Days')
                    {
                        Decimal unitPrice = (quoteRecord.UnitPrice__c == null) ? 0 : quoteRecord.UnitPrice__c;
                        Decimal qty = (line.Amount__c == null) ? 0 : line.Amount__c;
                        result += unitPrice * qty;
                    }
                    else
                    {
                        result += (line.Amount__c == null) ? 0 : line.Amount__c;
                    }
                }
            }
            else
            {
                for(QuoteLine__c line : StandardLines)
                {
                    result += (line.Amount__c == null) ? 0 : line.Amount__c;
                }
            }
            return result;
        }
    }
    
    @isTest
    static void testQuotePrintController()
    {
        Quote__c quote = new Quote__c(Date__c=Date.today(), DisplayAmount__c=true, UnitPrice__c=10);
        insert quote;
        QuoteLine__c line1 = new QuoteLine__c(Quote__c=quote.Id, IsAdditional__c=false, Task__c='acme', Amount__c=1, Unit__c='Days');
        insert line1;
        QuoteLine__c line2 = new QuoteLine__c(Quote__c=quote.Id, IsAdditional__c=true, Task__c='acme', Amount__c=1);
        insert line2;
        
        ApexPages.StandardController st = new ApexPages.StandardController(quote);
        QuotePrintController controller = new QuotePrintController(st);
        
        System.assertEquals(1, controller.StandardLines.size());
        System.assertEquals(1, controller.AdditionalLines.size());
        System.assertEquals('Days', controller.StandardUnit);
        System.assertEquals(10, controller.Total);
    }
}