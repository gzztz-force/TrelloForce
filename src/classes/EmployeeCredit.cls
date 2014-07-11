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
            return new List<Credit>();
        }
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

    public static Map<String, String> getCreditsInFin(Map<String, String> allUser)
    {
        List<String> creditUserEmails = allUser.values();
        String soql = 'select Id, Employee__c, Employee__r.Eamil, Balance__c from Credit__c' +
                    ' where Employee__r.Email in (';
        for(String userName : creditUserEmails)
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
            String email = c.Employee_r.Email;
            if(email != null )
            {
                allCredits.put(String.valueOf(allUser.get(email)), c.Id);
            }   
        }
        return allCredits;
    }
}