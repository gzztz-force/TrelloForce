/*
 * Controller of page ProjectDetail
 */
public with sharing class ProjectDetailController
{
    private MProject__c prj;
    private List<Change__c> displayingChanges;
    private List<TeamMember__c> displayingMembers;

    public ProjectDetailController(ApexPages.StandardController ctrl)
    {
        prj = (MProject__c)ctrl.getRecord();
        List<TimeCard__c> lastTimeCards = [select Id, Date__c from TimeCard__c where Project__c=:prj.Id order by Date__c desc limit 1];
        ChartType = ''; //default to hide the time card charts
        if(lastTimeCards.size() > 0)
        {
            //if there are any time cards, show the pie chart
            ChartType = 'Percent';
            TimeCard__c lastTC = lastTimeCards[0];
            //if the last time card is in 10 months, show the monthly chart
            if(lastTC.Date__c >= Date.today().addDays(-310))
            {
                ChartType += ', Month';
            }
            //if the last time card is in 8 weeks, show the weekly chart
            if(lastTC.Date__c > Date.today().addDays(-56))
            {
                ChartType += ', Week';
            }
            if(lastTC.Date__c >= Date.today().addDays(-10))
            {
                ChartType += ', Day';
            }
        }

        //default to show all members.
        if(prj.Status__c == 'Closed')
        {
            ShowAllMembers = true;
        }
        else
        {
            ShowAllMembers = true;
        }
        ShowClosedChanges = false;
        ChangeSortingField = 'Status__c';
        ChangeSortingOrder = 'asc';
        OpenAllChanges = false;
    }

    public String SelectMemberId { get; set; }
    public String ChangeSortingField { get; set; }
    public String ChangeSortingOrder { get; set; }
    public Boolean OpenAllChanges { get; set; }

    public String Role
    {
        get
        {
            String result = '';
            String profileName = [select Name from Profile where Id=:UserInfo.getProfileId() limit 1].Name;
            if(profileName.toLowerCase().contains('admin'))
            {
                result = 'Administrator;';
            }
            if(prj.OwnerId == UserInfo.getUserId())
            {
                result += 'Owner;';
            }
            for(TeamMember__c member : [select Id, Role__c from TeamMember__c where Project__c=:prj.Id and User__c=:UserInfo.getUserId()])
            {
                result += member.Role__c;
            }
            return result;
        }
    }

    public Boolean HasPowerPrivilege { get { return Role.contains('Administrator') || Role.contains('Owner') || Role.contains('Manager'); } }

    public List<Change__c> Changes
    {
        get
        {
            if(displayingChanges == null)
            {
                Id prjId = prj.Id;
                String keyword = ChangeKeyword;
                String likeKeyword = '%' + ChangeKeyword + '%';
                String soql = 'select Id, Name, Priority__c, ChangeNumber__c, AssignedTo__c, AssignedTo__r.Name, Type__c, Status__c, DueDate__c, (select Name, Change__c, Estimation__c, Status__c, AssignedTo__c, AssignedTo__r.Name, DueDate__c from ChangeTasks__r where Name like :likeKeyword or Change__r.ChangeNumber__c like :likeKeyword or Status__c like :likeKeyword or AssignedTo__r.Name like :likeKeyword) from Change__c where Project__c=:prjId';                
                if(ChangeKeyword == null || ChangeKeyword.length() < 2)
                {
                   soql = 'select Id, Name, Priority__c, ChangeNumber__c, AssignedTo__c, AssignedTo__r.Name, Type__c, Status__c, DueDate__c, (select Name, Change__c, Estimation__c, Status__c, AssignedTo__c, AssignedTo__r.Name, DueDate__c from ChangeTasks__r) from Change__c where Project__c=:prjId';                
                }

                if(selectMemberId != null && selectMemberId != 'All' && selectMemberId != '')
                {
                    Set<Id> changeIds = new Set<Id>();
                    for(ChangeTask__c c : [select Change__c from ChangeTask__c where AssignedTo__c=:selectMemberId])
                    {
                        changeIds.add(c.Change__c);
                    }
                    soql = 'select Id, Name, Priority__c, ChangeNumber__c, AssignedTo__c, AssignedTo__r.Name, Type__c, Status__c, DueDate__c, (select Name, Change__c, Estimation__c, Status__c, AssignedTo__c, AssignedTo__r.Name, DueDate__c from ChangeTasks__r where AssignedTo__c=:selectMemberId) from Change__c where Project__c=:prjId and (AssignedTo__c=:selectMemberId or Id in:changeIds)';                
                }

                if(ChangeKeyword != null && ChangeKeyword.length() >= 2)
                {
                    Set<Id> changeIds2 = new Set<Id>();
                    for(ChangeTask__c c : [select Change__c, AssignedTo__r.Name from ChangeTask__c where Name like :likeKeyword or Change__r.ChangeNumber__c like :likeKeyword or Status__c like :likeKeyword or AssignedTo__r.Name like :likeKeyword])
                    {
                        changeIds2.add(c.Change__c);
                    }
                    //always includes the closed changes when there are keywords
                    soql += ' and ((Name like :likeKeyword or ChangeNumber__c like :keyword or Priority__c like :keyword or Type__c like :keyword or Status__c like :keyword or AssignedTo__r.Name like :likeKeyword) or Id in :changeIds2)';
                }

                if(!ShowClosedChanges)
                {
                    soql += ' and IsClosed__c=0';
                }
                soql += ' order by ' + ChangeSortingField + ' ' + ChangeSortingOrder;
                displayingChanges = Database.query(soql);
            }
            return displayingChanges;
        }
    }

    public Integer TotalChangeCount
    {
        get
        {
            return [select count() from Change__c where Project__c=:prj.Id];
        }
    }

    public Integer ClosedChangeCount
    {
        get
        {   Id prjId = prj.Id;
            String sql = 'select count() from Change__c where Project__c=:prjId and IsClosed__c=1';
            if(selectMemberId != null && selectMemberId != 'All' && selectMemberId != '')
            {
                 sql += ' and AssignedTo__c=:selectMemberId';
            }
            if(ChangeKeyword != null && ChangeKeyword.length() >= 2)
            {
                sql += ' and AssignedTo__r.Name like :ChangeKeyword';
            }
            return Database.countQuery(sql);
        }
    }

    public List<LoginCredential__c> LoginCredentials
    {
        get
        {
            return [select Id, Name, LoginUrl__c, SalesforceLoginURL__c, Type__c, RecordTypeId, RecordType.Name, Username__c, Password__c from LoginCredential__c where Project__c=:prj.Id];
        }
    }

    public List<TeamMember__c> TeamMembers
    {
        get
        {
            //sorting order: self, active members by role
            if(displayingMembers == null)
            {
                displayingMembers = new List<TeamMember__c>();
                for(TeamMember__c myself : [select Id, Name, Role__c, TotalHours__c, LastActivityDate__c, User__r.IsActive from TeamMember__c where Project__c=:prj.Id and User__c=:UserInfo.getUserId()])
                {
                    displayingMembers.add(myself);
                }
                List<TeamMember__c> members = [select Id, Name, Role__c, TotalHours__c, LastActivityDate__c, User__r.IsActive from TeamMember__c where Project__c=:prj.Id and User__c!=:UserInfo.getUserId() and User__r.IsActive=true order by Name desc];
                for(Schema.PicklistEntry roleEntry : TeamMember__c.Role__c.getDescribe().getPicklistValues())
                {
                    for(Integer i = members.size() - 1; i >= 0; i--)
                    {
                        if(members[i].Role__c != null && members[i].Role__c != '' && members[i].Role__c.indexOf(roleEntry.getValue()) >= 0)
                        {
                            displayingMembers.add(members[i]);
                            members.remove(i);
                        }
                    }
                }
                for(Integer i = members.size() - 1; i >= 0; i--)
                {
                    TeamMember__c memberWithNoRole = members[i];
                     displayingMembers.add(memberWithNoRole);
                }
            }
            return displayingMembers;
        }
    }

    public List<S3File__c> S3Files
    {
        get
        {
            return [select Id, Name, DownloadLink__c, FileName__c, Size__c, OriginalDate__c from S3File__c where ParentId__c=:prj.Id];
        }
    }

    public Integer AllMemberCount { get { return [select count() from TeamMember__c where Project__c=:prj.Id]; } }
    public Boolean ShowAllMembers { get; set; }
    public Boolean ShowClosedChanges { get; set; }
    public String ChangeKeyword { get; set; }
    public String ChartType { get; set; }

    public PageReference searchChanges()
    {
        displayingChanges = null;
        OpenAllChanges = true;
        return null;
    }

    public PageReference refresh()
    {
        displayingChanges = null;
        displayingMembers = null;
        OpenAllChanges = false;
        return null;
    }

    public PageReference refreshByMember()
    {
        displayingChanges = null;
        OpenAllChanges = true;
        return null;
    }

    @isTest
    static void testProjectdDtailController()
    {
        MProject__c p = new MProject__c(Name='acme');
        insert p;
        TeamMember__c member = new TeamMember__c(Project__c=p.Id, User__c=UserInfo.getUserId(), Role__c='Project Manager');
        insert member;
        Change__c chg = new Change__c(Project__c=p.Id, Status__c='Closed', DueDate__c=Date.today(), AssignedTo__c=UserInfo.getUserId());
        insert chg;

        ApexPages.StandardController ctrl = new ApexPages.StandardController(p);
        ProjectDetailController controller = new ProjectDetailController(ctrl);

        List<Change__c> changes = controller.Changes;
        System.assertEquals(0, changes.size());

        controller.ShowClosedChanges = true;
        controller.refresh();
        changes = controller.Changes;
        System.assertEquals(1, changes.size());
        Integer i = controller.TotalChangeCount;
        Integer j = controller.ClosedChangeCount;

        String role = controller.Role;
        System.assert(controller.HasPowerPrivilege);

        List<LoginCredential__c> ls = controller.LoginCredentials;

        List<TeamMember__c> members = controller.TeamMembers;
        System.assertEquals(1, members.size());
        System.assertEquals(1, controller.AllMemberCount);
    }
}