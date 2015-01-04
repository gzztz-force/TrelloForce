/*
 * This class is created to handle operation about FIN's Credit.
 * Get Credit's data in FIN
 */
public with sharing class EmployeeCredit
{
    public static List<Credit> getCredit(String q)
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
            return (List<Credit>)parser.readValueAs(List<Credit>.class);
        }
        catch(Exception ex)
        {
            System.debug(ex);
            return new List<Credit>();
        }
    }

    public static Map<String, String> getCreditsInFin(Map<String, String> allUser)
    {
        Set<String> creditUserNames = allUser.keySet();
        String soql = 'select Id, Employee__c, Employee__r.UserName, Balance__c from Credit__c' +
                    ' where Employee__r.UserName in (';
        for(String userName : creditUserNames)
        {
            if(String.isNotBlank(userName))
            {
                soql += '\'' + userName + '\',';
            }
        }
        soql = soql.removeEnd(',');
        soql += ')';
        List<EmployeeCredit.Credit> credits = EmployeeCredit.getCredit(soql);
        Map<String, String> allCredits = new Map<String, String>();
        for(EmployeeCredit.Credit c : credits)
        {
            String userName = c.Employee_r.UserName;
            if(userName != null)
            {
                allCredits.put(allUser.get(userName), c.Id);
            }   
        }
        return allCredits;
    }

    public class Employee
    {
        public Employee(String id)
        {
            this.Id = id;
        }

        public String Id { get; set; }
        public String Name { get; set; }
        public String Email { get; set; }
        public String UserName { get; set; }
    }  

    public class Credit
    {
        public Credit(String id)
        {
            this.Id = id;
        }

        public String Id { get; set; }
        public String UserId { get; set; }
        public Decimal Balance { get; set; }
        public Employee Employee_r { get; set; }
    }
}