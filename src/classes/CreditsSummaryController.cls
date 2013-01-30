/*
 * summarize all user's credits.
 */
public class CreditsSummaryController
{
    public CreditsSummaryController()
    {
		AllCredits = [select Employee__c, Employee__r.Name, Value__c, AdjustmentValue__c from Credit__c order by Value__c Desc];
    }
    
    public Decimal MaxCreditValue
    {
    	get
        {
            Decimal max = 0;
        	for(Credit__c credit : AllCredits)
            {
                max = credit.Value__c > max ? credit.Value__c : max;
            }
            return max;
        }
    }
    public List<Credit__c> AllCredits { get; set; }    
}