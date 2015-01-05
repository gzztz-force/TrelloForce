/*
 * This class is created to handle operation about FIN's CreditTransaction.
 * Get CreditTransaction's data in FIN
 * Insert a new CreditTransaction record into FIN
 */
public with sharing class EmployeeCreditTransaction 
{
    public static List<CreditTransaction> getCreditTransaction(String q)
    {
        HttpResponse response;
        try
        {
            response = SFRestAPI.query(q);
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }

        try
        {
            JSONParser parser = JsonUtil.parseJson(response);
            return (List<CreditTransaction>)parser.readValueAs(List<CreditTransaction>.class);
        }
        catch(Exception ex)
        {
            return new List<CreditTransaction>();
        }
    }

    public static void createCreditTransactions(List<CreditTransaction> creditTransactions)
    {
        try
        {
            String obj = 'CreditTransaction__c';    
            String jsonBody = generateJson(creditTransactions);
            SFRestAPI.create(obj, jsonBody);
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

    private static String generateJson(List<CreditTransaction> creditTransactions)
    {
        String jsonSerialized = '';
        for(CreditTransaction creditTransaction : creditTransactions)
        {
            jsonSerialized += JSON.serialize(creditTransaction);
        }
        jsonSerialized = jsonSerialized.replaceAll('_c', '__c');
        return jsonSerialized;
    }

    public class CreditTransaction
    {
        public CreditTransaction(Decimal adjustment, String creditId, String description, Date effectiveDate, Boolean isValid, String reason)
        {
            this.Adjustment_c = adjustment;
            this.Credit_c = creditId;
            this.Description_c = description;
            this.EffectiveDate_c = effectiveDate;
            this.IsValid_c = isValid;
            this.Reason_c = reason;
        }

        public String Id { get; set; }
        public Decimal Adjustment_c { get; set; }
        public String Credit_c { get; set; }
        public String Description_c { get; set; }
        public Date EffectiveDate_c { get; set; }
        public Boolean IsValid_c { get; set; }
        public String Reason_c { get; set; }
    }
}