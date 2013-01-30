/*
 * Controller of component HistoryList
 */
public with sharing class HistoryListController
{
    private Id sObjectId;
    private String sObjectName;
    private static Map<String, Schema.DescribeFieldResult> fieldDescribeMap;
    private static Map<String, Decimal> timeZoneSidMap;
    
    public HistoryListController()
    {
    }
    
    public Id ParentId
    {
        get { return sObjectId; }
        set
        {
            sObjectId = value;
            describeObject(); 
        }
    }
    public String ErrorMessage { get; set; }
    
    private void describeObject()
    {
        String recordId = sObjectId;
        if(recordId != null || recordId.length() < 15)
        {
            fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();
            Map<String, Schema.sObjectType> gd = Schema.getGlobalDescribe();
            for(String objectName : gd.keySet())
            {
                Schema.DescribeSObjectResult objectDescription = gd.get(objectName).getDescribe();
                if(objectDescription.getKeyPrefix() == recordId.substring(0, 3))
                {
                    sObjectName = objectName;
                    Map<String, Schema.SObjectField> fieldMap = objectDescription.fields.getMap();
                    for(String fieldName : fieldMap.keySet())
                    {
                        Schema.sObjectField field = fieldMap.get(fieldName);
                        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                        fieldDescribeMap.put(fieldName, fieldDescribe);
                    }
                    break;
                }
            }
        }
    }
    
    public List<HistoryInfo> Histories
    {
        get
        {
            List<HistoryInfo> result = new List<HistoryInfo>();
            try
            {
                List<sObject> obj = Database.query('select Id, (select CreatedById, CreatedBy.Name, CreatedDate, Field, OldValue, NewValue from Histories order by CreatedDate desc, CreatedById limit 10) from ' + sObjectName +' where Id=:ParentId limit 1');
                if(obj.size() == 1)
                {
                    List<sObject> historyEntries = obj[0].getSObjects('Histories');
                    DateTime lastDate = null;
                    Id lastUserId = null;
                    if(historyEntries != null)
                    {
                        for(sObject historyObj : historyEntries)
                        {
                            DateTime currentDate = (DateTime)historyObj.get('CreatedDate');
                            Id createdBy = (Id)historyObj.get('CreatedById');
                            HistoryInfo history = new HistoryInfo(historyObj);
                            //if the user changes more than 1 field at one time, do not show up the user name on the second line (and on more lines).
                            history.OmitUser = (currentDate == lastDate && lastUserId == createdBy);
                            result.add(history);
                            lastDate = currentDate;
                            lastUserId = createdBy;
                        }
                    }
                }
            }
            catch(Exception ex)
            {
                ErrorMessage = ex.getMessage();
            }
            return result;
        }
    }
    
    public static Decimal getTimeZoneDiffer(Id userId)
    {
        String timeZoneSid = [select TimeZoneSidKey from User where Id=:userId limit 1].TimeZoneSidKey;
        if(timeZoneSidMap == null)
        {
            timeZoneSidMap = new Map<String, Decimal>();
            Schema.DescribeFieldResult timeZoneSidDescription = Schema.sObjectType.User.fields.TimeZoneSidKey;
            List<Schema.PicklistEntry> sids = timeZoneSidDescription.getPicklistValues();
            for(Schema.PicklistEntry sid : sids)
            {
                String sidLabel = sid.getLabel(); // e.g.: (GMT+08:00) China Standard Time
                timeZoneSidMap.put(sid.getValue(), parseTimeZoneLabel(sidLabel));
            }
        }
        return timeZoneSidMap.get(timeZoneSid);
    }
    
    private static Decimal parseTimeZoneLabel(String label)
    {
        Pattern timeZonePattern = Pattern.compile('\\(GMT(\\+|\\-)(\\d+):(\\d+)\\).+');
        Matcher timeZoneMatcher = timeZonePattern.matcher(label);
        if(timeZoneMatcher.matches())
        {
            Integer sign = (timeZoneMatcher.group(1) == '+') ? -1 : 1;
            Integer hour = Integer.valueOf(timeZoneMatcher.group(2));
            Integer minute = Integer.valueOf(timeZoneMatcher.group(3));
            return sign * hour + (minute / 60);
        }
        else
        {
            return 0;
        }
    }
    
    public class HistoryInfo
    {
        public HistoryInfo(sObject obj)
        {
            CreatedDate = (DateTime)obj.get('CreatedDate');
            if(CreatedDate != null)
            {
                Decimal differ = HistoryListController.getTimeZoneDiffer(UserInfo.getUserId());
                CreatedDate = CreatedDate.addHours(differ.intValue());
                CreatedDate = CreatedDate.addMinutes((Integer)(differ.doubleValue() * 60));
            }
            Id userId = (Id)obj.get('CreatedById');
            String userName = (String)obj.getSObject('CreatedBy').get('Name');
            CreatedBy = new User(Id=userId, LastName=userName);
            string fieldName = (String)obj.get('Field');
            if(fieldName != null && fieldDescribeMap != null)
            {
                if(fieldDescribeMap.containsKey(fieldName.toLowerCase()))
                {
                    Field = fieldDescribeMap.get(fieldName.toLowerCase()).getLabel();
                    OldValue = formatString(obj.get('OldValue'), fieldDescribeMap.get(fieldName.toLowerCase()).getType());
                    NewValue = formatString(obj.get('NewValue'), fieldDescribeMap.get(fieldName.toLowerCase()).getType());
                }
                else
                {
                    Field = fieldName;
                }
            }
        }
        
        public DateTime CreatedDate { get; set; }
        public User CreatedBy { get; set; }
        public String Field { get; set; }
        public String OldValue { get; set; }
        public String NewValue { get; set; }
        public Boolean OmitUser { get; set; }
        
        private String formatString(Object value, Schema.DisplayType fieldType)
        {
            try
            {
                if(value == null)
                {
                    return null;
                }
                if(fieldType == Schema.DisplayType.Date)
                {
                    return ((Date)value).format();
                }
                else if(fieldType == Schema.DisplayType.DateTime)
                {
                    DateTime dtValue = ((DateTime)value);
                    Decimal differ = HistoryListController.getTimeZoneDiffer(UserInfo.getUserId());
                    dtValue.addHours(differ.intValue());
                    dtValue.addMinutes((Integer)(differ.doubleValue() * 60));
                    return dtValue.format('MM/dd/yyyy hh:mm:ss a');
                }
            }
            catch(Exception ex)
            {
            }
            return String.valueOf(value);
        }
    }
    
    @isTest
    static void testHistoryListController()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        prj.EstimatedHours__c = 100;
        prj.StartDate__c = Date.today();
        update prj;
        
        HistoryListController controller = new HistoryListController();
        controller.ParentId = prj.Id;
        
        List<HistoryInfo> hs = controller.Histories;
    }
    
    @isTest
    static void testHistoryInfo()
    {
        List<MProject__History> historyObjs = [select Id, OldValue, NewValue, Field, CreatedDate, CreatedById, CreatedBy.Name From MProject__History limit 10];
        for(MProject__History historyObj : historyObjs)
        {
            HistoryInfo history = new HistoryInfo(historyObj);
        }
    }
}