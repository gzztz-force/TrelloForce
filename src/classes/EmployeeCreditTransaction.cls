public with sharing class EmployeeCreditTransaction {

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

        JSONParser parser = JsonUtil.parseJson(response);

        try
        {
            return (List<CreditTransaction>)parser.readValueAs(List<CreditTransaction>.class);
        }
        catch(Exception ex)
        {
            return new List<CreditTransaction>();
        }
    }

    private static String generateJson(List<CreditTransaction> creditTransactions)
    {
        /*
        List<Map<String, String>> creditTransactions = new List<Map<String,String>>();
        for(CreditTransaction c : cts)
        {
            Map<String, String> fieldToValueMap = new Map<String, String>();
            fieldToValueMap.put('Adjustment__c', String.valueOf(c.Adjustment_c));
            fieldToValueMap.put('Credit__c', c.Credit_r.Id);
            fieldToValueMap.put('Description__c', c.Description_c);
            fieldToValueMap.put('EffectiveDate__c', String.valueOf(c.EffectiveDate_c));
            fieldToValueMap.put('IsValid__c', String.valueOf(c.IsValid_c));
            fieldToValueMap.put('Reason__c', c.Reason_c); 
            creditTransactions.add(fieldToValueMap);
        }

        return JSON.serialize(creditTransactions);
        */
        String jsonSerialized = '';
        for(CreditTransaction creditTransaction : creditTransactions)
        {
            jsonSerialized += JSON.serialize(creditTransaction);
        }
        return jsonSerialized;
    }

    public static void createCreditTransactions(List<CreditTransaction> creditTransactions)
    {
        String obj = 'CreditTransaction__c';    
        String jsonBody = generateJson(creditTransactions);
        SFRestAPI.create(obj, jsonBody);
    }

    public class CreditTransaction
    {
        public CreditTransaction(Decimal adjustment, String creditId, String description, Date effectiveDate, Boolean isValid, String reason)
        {
            EmployeeCredit.Credit credit = new EmployeeCredit.Credit(creditId);
            this.Adjustment_c = adjustment;
            this.Credit_r = credit;
            this.Description_c = description;
            this.EffectiveDate_c = effectiveDate;
            this.IsValid_c = isValid;
            this.Reason_c = reason;
        }

        public String Id { get; set; }
        public Decimal Adjustment_c { get; set; }
        public EmployeeCredit.Credit Credit_r { get; set; }
        public String Description_c { get; set; }
        public Date EffectiveDate_c { get; set; }
        public Boolean IsValid_c { get; set; }
        public String Reason_c { get; set; }
    }
}