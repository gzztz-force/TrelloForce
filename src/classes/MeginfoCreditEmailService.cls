/*
 * receive XML data from fini Email Service, resolve xml data and post data to PM chatter.
 */
/*
XML Data Example:
<credits>
  <adjustments>
    <credit employee="David" date="2012-01-01" adjustment="1" reason="Team Discussion" description="xxxxxx" />
    <credit employee="Allen" date="2012-01-01" adjustment="-1" reason="Time Card Punishment" description="xxxxxx" />
  </adjustments>
  <summary date="2013-01-01">
    <credit employee="Kevin" value="10" />
    <credit employee="David" value="10" />
    <credit employee="Allen" value="10" />
  </summary>
</credits>
*/
global class MeginfoCreditEmailService implements Messaging.InboundEmailHandler 
{    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {      
        Boolean isSuccess = true;
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult(); 
        Dom.Document creditsDoc = new Dom.Document();
        creditsDoc.load(email.plainTextBody);
        Dom.XmlNode creditsNode = creditsDoc.getRootElement();
        List<Dom.XmlNode> allAdjustmentCredits = creditsNode.getChildElement('adjustments', null).getChildElements();
        List<Dom.XmlNode> allSummaryCredits = creditsNode.getChildElement('summary', null).getChildElements();


        if (allAdjustmentCredits.size() > 0 && allSummaryCredits.size() > 0)
        {
            Map<String, User> firstNameToUserMap = constructFirstNameToUserMap(allSummaryCredits);
            List<CreditAdjustmentInfo> allCreditAdjustmentInfos = transformToCreditAdjustmentObjects(allAdjustmentCredits, firstNameToUserMap);
            List<CreditInfo> allCreditInfos = transformToCreditObjects(allSummaryCredits, firstNameToUserMap);
            isSuccess = postChatter(allCreditAdjustmentInfos, allCreditInfos);
        }
        else
        {
            isSuccess = false;
        }

        if(!isSuccess)
        {
            result.success = false;
            result.message = 'Wrong XML formate.';
        }
        else
        {
            result.success = true;
            result.message = 'Credit increment information have been posted on chatter.';
        }
        return result;
    }
    
    private Map<String, User> constructFirstNameToUserMap(List<Dom.XmlNode> summaryCredits)
    {
        Map<String, User> firstNameToUserMap = new Map<String, User>();        
        Set<String> allEmployeeNames = new Set<String>();        
        for(Dom.XmlNode summaryCredit : summaryCredits)
        {
            allEmployeeNames.add(summaryCredit.getAttribute('employee', null));
        }                
        for(User currentUser : [select id, Name, FirstName from User where FirstName in : allEmployeeNames])
        {
            firstNameToUserMap.put(currentUser.FirstName, currentUser);
        }    
        return firstNameToUserMap;
    }
    
    private List<CreditAdjustmentInfo> transformToCreditAdjustmentObjects(List<Dom.XmlNode> adjustmentCredits, Map<String, User> nameToUserMap)
    {        
        String firstName, reason, description;
        Integer value;
        Date createDate;
        User employeeUser;
        List<CreditAdjustmentInfo> allCreditAdjustmentInfos = new List<CreditAdjustmentInfo>();
        for(Dom.XmlNode adjustmentCredit : adjustmentCredits)
        {
            firstName = adjustmentCredit.getAttribute('employee', null);
            value = Integer.valueOf(adjustmentCredit.getAttribute('adjustment', null));
            reason = adjustmentCredit.getAttribute('reason', null);
            description = adjustmentCredit.getAttribute('description', null);
            createDate = Date.valueOf(adjustmentCredit.getAttribute('date', null));
            employeeUser = nameToUserMap.get(firstName);
            if(employeeUser != null)
            {
                allCreditAdjustmentInfos.add(new CreditAdjustmentInfo(employeeUser.Id, employeeUser.Name, value, reason, description, createDate));
            }           
        }      
        return allCreditAdjustmentInfos;          
    }
    
    private List<CreditInfo> transformToCreditObjects( List<Dom.XmlNode> summaryCredits, Map<String, User> nameToUserMap)
    {
        String firstName;
        Integer value;
        User employeeUser;
        List<CreditInfo> allCreditInfos = new List<CreditInfo>();
        for(Dom.XmlNode summaryCredit : summaryCredits)
        {
            firstName = summaryCredit.getAttribute('employee', null);
            value = Integer.valueOf(summaryCredit.getAttribute('value', null));
            employeeUser = nameToUserMap.get(firstName);
            if(employeeUser != null)
            {
                allCreditInfos.add(new CreditInfo(employeeUser.Id, employeeUser.Name, value));
            }            
        } 
        return allCreditInfos;   
    }

    private Boolean postChatter(List<CreditAdjustmentInfo> adjustmentInfos, List<CreditInfo> creditInfos)
    {         
        Boolean status = true;
        FeedItem item = new FeedItem();
        item.ParentId = UserInfo.getUserId();
        item.Body = composeFeedBody(adjustmentInfos);
        updateCreditsRecord(adjustmentInfos, creditInfos);
        item.LinkUrl = '/apex/CreditsSummary';
        try
        {
            insert item;
        }
        catch(DmlException ex)
        {
            status = false;
        }
        return status;
    }
    
    private String composeFeedBody(List<CreditAdjustmentInfo> adjustmentInfos)
    {
        String body = '';
        for(CreditAdjustmentInfo adjustmentInfo : adjustmentInfos)
        {        
            body += 'Name: ' + adjustmentInfo.EmployeeName + '\r\n';
            body += 'Credit Increment: ' + (adjustmentInfo.Value >= 0 ? '+' : '')  + String.valueOf(adjustmentInfo.Value) + '\r\n';
            body += 'Reason: ' + adjustmentInfo.Reason + '\r\n';
            body += '*************\r\n';
        }
        return body;
    }
    
    private void updateCreditsRecord(List<CreditAdjustmentInfo> adjustmentInfos, List<CreditInfo> creditInfos)
    {
       	List<Credit__c> insertCredits = new List<Credit__c>();
        for (CreditInfo info : creditInfos)
        {
            Credit__c newCredit = null;
            for (CreditAdjustmentInfo adjustment : adjustmentInfos)
            {
                if (info.EmployeeName.toLowerCase() == adjustment.EmployeeName.toLowerCase()) 
                {                    
                    newCredit = new Credit__c(Employee__c = info.EmployeeId, Value__c = info.Value, AdjustmentValue__c = adjustment.Value);
                }
            }
            if (newCredit == null) 
            {
                newCredit = new Credit__c(Employee__c = info.EmployeeId, Value__c = info.Value);
            }            
			insertCredits.add(newCredit);
        }           
        try
        {	
            delete [select id from Credit__c];
        	insert insertCredits;
        }
        catch(DmlException ex)
        {
        }       	
    }

    public class CreditAdjustmentInfo
    {
        public CreditAdjustmentInfo(String employeeId, String name, Integer value, String reason, String description, Date createDate)
        {
            this.EmployeeId = employeeId;
            this.EmployeeName = name;
            this.Value = value;
            this.Reason = reason;
            this.Description = description;
            this.CreateDate = createDate;
        }
        
        String EmployeeId { get; set; }
        String EmployeeName { get; set; }        
        Integer Value { get; set; }
        String Reason { get; set; }
        String Description { get; set; }
        Date CreateDate { get; set; }                               
    }
    
    public class CreditInfo
    {
        public CreditInfo(String employeeId, String employeeName, Integer value)
        {
            this.EmployeeId = employeeId;            
            this.EmployeeName = employeeName;
            this.Value = value;
        }
        
        String EmployeeId { get; set; }        
        String EmployeeName { get; set; }
        Integer Value { get; set; }
    }
    
    @isTest
    static void testMeginfoCreditEmailService()
    {
 		Messaging.InboundEmail inboundEmail = new Messaging.InboundEmail();
        inboundEmail.plainTextBody = '<credits><adjustments><credit employee="David" date="2012-01-01" adjustment="1" reason="Team Discussion" description="xxxxxx" /><credit employee="Allen" date="2012-01-01" adjustment="-1" reason="Time Card Punishment" description="xxxxxx" /></adjustments><summary date="2013-01-01"><credit employee="David" value="8" /><credit employee="Allen" value="6" /></summary></credits>';
        MeginfoCreditEmailService service = new MeginfoCreditEmailService();
        service.handleInboundEmail(inboundEmail, null);
    }
    
}