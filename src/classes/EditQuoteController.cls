/*
 * Controller of page EditQuote
 */
public with sharing class EditQuoteController 
{
    private Quote__c quoteRecord;
    private List<QuoteLine__c> removedLines;
    
    public EditQuoteController(ApexPages.StandardController controller) 
    {
        quoteRecord = (Quote__c)controller.getRecord();
        removedLines = new List<QuoteLine__c>();
        
        if(quoteRecord.Id == null)
        {
            StandardLines = new List<QuoteLine__c>();
            AdditionalLines = new List<QuoteLine__c>();
            addMoreStandardLines();
            addMoreAdditionalLines();
            quoteRecord.Date__c = Date.today();
            ShowAdditionalLInes = false;
            StandardLineUnit = 'Hours';
            quoteRecord.DisplayAmount__c = false;
        }
        else
        {
            StandardLines = [select Id, Name, Task__c, Unit__c, Amount__c, SortOrder__c, Quote__c from QuoteLine__c where Quote__c=:quoteRecord.Id and IsAdditional__c=false order by SortOrder__c];
            AdditionalLines = [select Id, Name, Task__c, Unit__c, Amount__c, SortOrder__c, Quote__c from QuoteLine__c where Quote__c=:quoteRecord.Id and IsAdditional__c=true order by SortOrder__c];
            ShowAdditionalLines = AdditionalLines.size() > 0;
            if(AdditionalLines.size() == 0)
            {
                addMoreAdditionalLines();
            }
            if(StandardLines.size() > 0)
            {
                StandardLineUnit = StandardLines[0].Unit__c;
            }
        }
        String cloned = ApexPages.currentPage().getParameters().get('clone');
        if(cloned != null && cloned != '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Quotation cloned.'));
        }
    }

    public List<QuoteLine__c> StandardLines { get; set; }
    public List<QuoteLine__c> AdditionalLines { get; set; }
    public String StandardLineUnit { get; set; }
    public String AdditionalLineUnit
    {
        get
        {
            if(quoteRecord.DisplayAmount__c == true)
            {
                return quoteRecord.Currency__c;
            }
            else
            {
                return StandardLineUnit;
            }
        }
    }
    
    public String SummaryUnit { get; set; }
    public Decimal StandardLinePrice { get; set; }
    public Boolean ShowAdditionalLInes { get; set; }
    
    public PageReference addMoreStandardLines()
    {
        StandardLines.addAll(new List<QuoteLine__c>
        { 
            new QuoteLine__c(), 
            new QuoteLine__c(), 
            new QuoteLine__c(), 
            new QuoteLine__c(), 
            new QuoteLine__c() 
        });
        reorderLines();
        return null;
    }
    
    public PageReference addMoreAdditionalLines()
    {
        AdditionalLines.addAll(new List<QuoteLine__c>
        { 
            new QuoteLine__c(), 
            new QuoteLine__c(), 
            new QuoteLine__c()
        });
        reorderLines();
        return null;
    }
    
    public PageReference refresh()
    {
        return null;
    }
    
    public PageReference removeStandardLine()
    {
        String index = ApexPages.currentPage().getParameters().get('index');
        if(index != '' & index != null)
        {
            Integer sortOrder = Decimal.valueOf(index).intValue();
            for(Integer i = StandardLines.size() - 1; i >= 0; i--)
            {
                if(StandardLines[i].SortOrder__c == sortOrder)
                {
                    if(StandardLines[i].Id != null)
                    {
                        removedLines.add(StandardLines[i]);
                    }
                    StandardLines.remove(i);
                    break;
                }
            }
            reorderLines();
        }
        return null;
    }
    
    public PageReference removeAdditionalLine()
    {
        String index = ApexPages.currentPage().getParameters().get('index');
        if(index != '' & index != null)
        {
            Integer sortOrder = Decimal.valueOf(index).intValue();
            for(Integer i = AdditionalLines.size() - 1; i >= 0; i--)
            {
                if(AdditionalLines[i].SortOrder__c == sortOrder)
                {
                    if(AdditionalLines[i].Id != null)
                    {
                        removedLines.add(AdditionalLines[i]);
                    }
                    AdditionalLines.remove(i);
                    break;
                }
            }
            reorderLines();
        }
        return null;
    }
    
    public PageReference raiseStandardLine()
    {
        String indexText = ApexPages.currentPage().getParameters().get('index');
        if(indexText != '' && indexText != null)
        {
            Integer index = Decimal.valueOf(indexText).intValue();
            index--;
            if(index >= 1 && StandardLines.size() > index)
            {
                swapLines(StandardLines, index - 1 , index);
                reorderLines();
            }
        }
        return null;
    }
    
    public PageReference lowerStandardLine()
    {
        String indexText = ApexPages.currentPage().getParameters().get('index');
        if(indexText != '' && indexText != null)
        {
            Integer index = Decimal.valueOf(indexText).intValue();
            index--;
            if(index >= 0 && StandardLines.size() > index + 1)
            {
                swapLines(StandardLines, index + 1 , index);
                reorderLines();
            }
        }
        return null;
    }
    
    private void swapLines(List<QuoteLine__c> lines, Integer a, Integer b)
    {
        QuoteLine__c tempLine = lines[a];
        lines.set(a, lines[b]);
        lines.set(b, tempLine);
    }
    
    private void reorderLines()
    {
        Integer index = 1;
        for(Integer i = 0; i < StandardLines.size(); i++)
        {
            StandardLines[i].SortOrder__c = index++;
        }
        for(Integer j = 0; j < AdditionalLines.size(); j++)
        {
            AdditionalLines[j].SortOrder__c = index++;
        }
    }
    
    public PageReference save()
    {
        SavePoint sp = Database.setSavePoint();
        try
        {
            MProject__c prj = [select Id, Customer__c from MProject__c where Id=:quoteRecord.Project__c limit 1];
            quoteRecord.Customer__c = prj.Customer__c;
            if(quoteRecord.DisplayAmount__c == false)
            {
                quoteRecord.UnitPrice__c = null;
                quoteRecord.Currency__c = null;
            }
            upsert quoteRecord;
            for(Integer i = StandardLines.size() - 1; i >= 0; i--)
            {
                if(StandardLines[i].Task__c == null || StandardLines[i].Task__c == '')
                {
                    if(StandardLines[i].Id != null)
                    {
                        removedLines.add(StandardLines[i]);
                    }
                    StandardLines.remove(i);
                }
            }
            for(QuoteLine__c line : StandardLines)
            {
                if(line.Quote__c == null)
                {
                    line.Quote__c = quoteRecord.Id;
                }
                line.Unit__c = StandardLineUnit;
                line.IsAdditional__c = false;
            }
            reorderLines();
            upsert StandardLines;
            if(ShowAdditionalLines)
            {
                for(Integer i = AdditionalLines.size() - 1; i >= 0; i--)
                {
                    if(AdditionalLines[i].Task__c == null || AdditionalLines[i].Task__c == '')
                    {
                        if(AdditionalLines[i].Id != null)
                        {
                            removedLines.add(AdditionalLines[i]);
                        }
                        AdditionalLines.remove(i);
                    }
                }
                for(QuoteLine__c line : AdditionalLines)
                {
                    if(line.Quote__c == null)
                    {
                        line.Quote__c = quoteRecord.Id;
                    }
                    line.IsAdditional__c = true;
                }
                upsert AdditionalLines;
            }
            else
            {
                for(QuoteLine__c line : AdditionalLines)
                {
                    if(line.Id != null)
                    {
                        removedLines.add(line);
                    }
                }
            }
            delete removedLines;
            return new PageReference('/' + quoteRecord.Id);
        }
        catch(Exception ex)
        {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
        }
        return null;
    }
    
    @isTest
    static void testNewQuote()
    {
        Quote__c quote = new Quote__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        EditQuoteController controller = new EditQuoteController(sc);
        controller.addMoreStandardLines();
        controller.addMoreAdditionalLines();
        PageReference testPage = new PageReference('/apex/EditQuote?index=1');
        Test.setCurrentPage(testPage);
        controller.raiseStandardLine();
        controller.lowerStandardLine();
        controller.removeStandardLine();
        controller.removeAdditionalLine();
        controller.save();
    }
    
    @isTest
    static void testEditQuote()
    {
        Quote__c quote = new Quote__c(Date__c=Date.today(), DisplayAmount__c=true, UnitPrice__c=10);
        insert quote;
        QuoteLine__c line1 = new QuoteLine__c(Quote__c=quote.Id, IsAdditional__c=false, Task__c='acme', Amount__c=1, Unit__c='Days');
        insert line1;
        QuoteLine__c line2 = new QuoteLine__c(Quote__c=quote.Id, IsAdditional__c=true, Task__c='acme', Amount__c=1);
        insert line2;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        EditQuoteController controller = new EditQuoteController(sc);
        controller.refresh();
        controller.save();
    }
}