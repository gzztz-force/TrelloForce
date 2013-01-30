public with sharing class GanttViewController 
{   
    private Date minDate;
    private Date maxDate;
    
    public GanttViewController()
    {        
        minDate = Date.today().addDays(1); 
        maxDate = Date.today().addDays(30);
    }
    public PageReference showBeforeDays()
    {
        minDate = minDate.addDays(-10);
        return null;
    }
    public PageReference showLaterDays()
    {
        maxDate = maxDate.addDays(10);
        return null;
    }
    public Date getMinDate()
    {
        return minDate;
    }
    public Date getMaxDate()
    {
        return maxDate;
    }
    public string getTitle()
    {
        string pid = ApexPages.currentPage().getParameters().get('pid');
        string uid = ApexPages.currentPage().getParameters().get('uid');
        if(pid != null && pid != '')
        {
            List<MProject__c> prj = [select Name from MProject__c where Id=:pid limit 1];
            if(prj.size() > 0)
            {
                return prj[0].Name;
            }
        }
        else if(uid != null && uid != '')
        {
            List<User> usrs = [select Name from User where Id=:uid limit 1];
            if(usrs.size() > 0)
            {
                return usrs[0].Name + '\'s Projects (beta)';
            }
        }
        else
        {
            return 'My Projects (beta)';
        }
        return '';
    }
    public string getDataSource()
    {
        String result = '{';
        List<MProject__c> projects =new List<MProject__c>();
        string pid = ApexPages.currentPage().getParameters().get('pid');
        string uid = ApexPages.currentPage().getParameters().get('uid');
        if(pid != null && pid != '')
        {
            projects = getProjectsByPid(pid);
        }
        else if(uid !=null && uid !='')
        {
          projects = getProjectsByUid(uid);
        }
        else
        {
            projects = getAllProjects();
        }
        
        result += 'projects:[ ';
        if(projects != null)
        {
            for(MProject__c pjc : projects)
            {
                result += formatProject(pjc) + ',';
            }
         }
         result = result.substring(0, result.length() - 1);
         result +='],'; 
        
        result += 'users:[ ';
        List<User> users = getUsers(pid);
        if(users != null)
        {
            for(User user : users)
            {
               result += formatUser(user) + ',';
            }
            result = result.substring(0, result.length() -1);
        }
        result +=']}';
        return result;
    }
    
    private String formatDate(Date value)
    {
        if(value == null)
        {
            return '';
        }
        return value.month() + '/' + value.day() + '/' + value.year(); 
    }
    private String formatProject(MProject__c pjc)
    {
        String pjcRender = '{'+
                             'id:"'+ pjc.Id +'",' + 
                             'start:"'+ formatDate(pjc.StartDate__c) +'",' + 
                             'end:"'+ formatDate(pjc.EndDate__c) +'",' + 
                             'name:"'+ pjc.Name +'",' + 
                             'tip:"'+ formatProjectTip(pjc) +'",' + 
                             'link:"?pid='+ pjc.Id +'",' +
                             'bold:true,' + 
                             'progress:"'+ pjc.Progress__c +'",' + 
                             'resources:[';
       if(pjc.TeamMembers__r != null && pjc.TeamMembers__r.size() > 0)
       {
           for(TeamMember__c tm : pjc.TeamMembers__r)
           {
               pjcRender += '"' + tm.User__c + '",';
           }
           pjcRender = pjcRender.substring(0, pjcRender.length() -1);
       }
       pjcRender += ']},';
       if(pjc.Tasks != null && pjc.Tasks.size() > 0)
       {
           for(Task task : pjc.Tasks)
           {
               pjcRender += formatTask(task);
               pjcRender += ',';
           }
       }
       pjcRender = pjcRender.substring(0, pjcRender.length() -1);
       return pjcRender;
    }
    private String formatProjectTip(MProject__c prj)
    {
        return  '<b>Name</b>: ' + prj.Name +'<br/>' + 
                '<b>Start Date: </b>' + formatDate(prj.StartDate__c) + '</br>' +
                '<b>End Date: </b>' + formatDate(prj.EndDate__c) + '</br>' +
                '<b>Progress</b>: ' + prj.Progress__c + '% ';
    }
    private String formatTaskTip(Task tsk)
    {
        return '<b>Name</b>: ' + tsk.Subject +'<br/>' +
               '<b>Status</b>: ' + tsk.Status +'<br/>';
    }
    private String formatTask(Task t)
    {
        String chgRender = '{'+
                             'id:"'+ t.Id +'",' + 
                             'start:"'+ t.CreatedDate.format('MM/dd/yyyy') +'",' + 
                             'end:"'+ formatDate(t.ActivityDate) +'",' + 
                             'name:"'+ t.Subject +'",' + 
                             'tip:"'+ formatTaskTip(t) +'",' + 
                             'link:"cid='+ t.Id +'",' +
                             'bold:false,' + 
                             'progress:"0",' + 
                             'resources:["' + t.OwnerId + '"]}';
        return chgRender;       
    }
    private String formatUser(User user)
    {
        String userRender = '{' + 
                                'id:"'+ user.Id +'",' + 
                                'name:"'+ user.Name+'",' +
                                'link:"?uid='+ user.Id +'"' +
                            '}';
        return userRender;
    }
    public List<MProject__c> getAllProjects()
    {
        return [select Id, Name, StartDate__c, EndDate__c, Progress__c, ProjectNumber__c, Status__c, 
                (select User__c from TeamMembers__r),
                (Select Subject, ActivityDate, Status, Priority, OwnerId, CreatedDate From Tasks where Subject='acme')                
                from MProject__c where Status__c='In Progress'];    //we don't really want to retrieve the tasks, but required by formatProject method, so we retrieve a null collection for the tasks
    }
    private List<MProject__c> getProjectsByPid(String pid)
    {
        return [select Id, Name, StartDate__c, EndDate__c, ProjectNumber__c, Progress__c,
                    (select User__c from TeamMembers__r),
                    (Select Subject, ActivityDate, Status, Priority, OwnerId, CreatedDate From Tasks) 
                    from MProject__c where Id=:pid Limit 1];
    }
    
    private List<User> getUsers(String pid)
    {
        return [select Id, Name, LastName, FirstName from User];
    } 
    
    private List<MProject__c> getProjectsByUid(string uid)
    {
        List<MProject__c> prjs = [select Id, Name, StartDate__c, EndDate__c, ProjectNumber__c, Progress__c, 
                                (select User__c from TeamMembers__r),
                                (Select Subject, ActivityDate, Status, Priority, OwnerId, CreatedDate From Tasks where Subject='acme')
                                from MProject__c where Status__c='In Progress'];
        for(Integer i = prjs.size() - 1; i >= 0; i--)
        {
            MProject__c prj = prjs[i];
            Boolean found = false;  
            for(TeamMember__c tm : prj.TeamMembers__r)
            {
                if(tm.User__c == uid)
                {
                    found = true;
                }
            }
            if(!found)
            {
                prjs.remove(i);
            }
        }
        return prjs;
    }
    @isTest
    static void testGanttViewController()
    {
        GanttViewController ctrl = new GanttViewController();
        ctrl.getTitle();
        ctrl.getDataSource(); 
        ctrl.showBeforeDays();
        ctrl.showLaterDays();
        ctrl.getMinDate();
        ctrl.getMaxDate();
        PageReference p = new PageReference('/apex/GanttView?pid=a0J80000000xQSHEA2');
        Test.setCurrentPage(p);
        ctrl = new GanttViewController();
        ctrl.getDataSource();
        p = new PageReference('/apex/GanttView?uid=0058000000298xY');
        Test.setCurrentPage(p);
        ctrl = new GanttViewController();
        ctrl.getDataSource();  
    }
}