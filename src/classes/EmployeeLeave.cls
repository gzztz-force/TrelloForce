public with sharing class EmployeeLeave
{
    public static List<Leave> getAllLeaves()
    {
        String q = 'select Id, StartDate__c, EndDate__c, HalfDay__c, Employee__c, Employee__r.Name, Employee__r.Email from Leave__c';

        HttpResponse response = SFRestAPI.query(q);
        JSONParser parser = JsonParserAndGenerator.parseJson(response);

        return (List<Leave>)parser.readValueAs(List<Leave>.class);
    }

    public static void createLeave(Date startDate, Date endDate, String halfDay, String employeeId)
    {
        Employee employee = new Employee(employeeId);
        Leave leave = new Leave(startDate, endDate, halfDay, employee);

        String obj = 'Leave__c';
        String jsonBody = generateJson(leave);

        SFRestAPI.create(obj, jsonBody);
    }

    public static void deleteLeave(String leaveId)
    {
        String obj = 'Leave__c';

        SFRestAPI.del(obj, leaveId);
    }

    private static String generateJson(Leave leave)
    {
        Map<String, String> fieldToValueMap = new Map<String, String>();

        fieldToValueMap.put('StartDate__c', String.valueOf(leave.StartDate_c));
        fieldToValueMap.put('EndDate__c', String.valueOf(leave.EndDate_c));
        fieldToValueMap.put('HalfDay__c', leave.HalfDay_c);
        fieldToValueMap.put('Employee__c', leave.Employee_r.Id);

        return JSON.serialize(fieldToValueMap);
    }

    public class Leave
    {
        public Leave(Date startDate, Date endDate, String halfDay, Employee employee)
        {
            this.StartDate_c = startDate;
            this.EndDate_c = endDate;
            this.HalfDay_c = halfDay;
            this.Employee_r = employee;
        }

        public String Id { get; set; }
        public Date StartDate_c { get; set; }
        public Date EndDate_c { get; set; }
        public String HalfDay_c { get; set; }
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
    }


    public enum LeaveType { NONE, MORNING, AFTERNOON, WHOLEDAY }
}