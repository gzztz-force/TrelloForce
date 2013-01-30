public with sharing class GanttViewHomeController 
{
    private List<ProjectEntry> projects;
    private Date minDate;
    private Date maxDate;
    private Integer rowCount = -1;
    private String pid;
    private String uid;
    
    public  GanttViewHomeController()
    {
    	pid = ApexPages.currentPage().getParameters().get('pid');
        uid = ApexPages.currentPage().getParameters().get('uid');
        includeProjects = true;
        includeChanges = true;
    }
    
    public Boolean includeProjects { get; set; }
    public Boolean includeChanges { get; set; }
    
    public string getTitle()
    {
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
            List<User> usrs = [select Name, FirstName from User where Id=:uid limit 1];
            if(usrs.size() > 0)
            {
                return usrs[0].FirstName + '\'s Projects (beta)';
            }
        }
        else
        {
            return 'My Projects (beta)';
        }
        return '';
    }
    public Date getMinDate()
    {
        if(minDate == null)
        {
            prepareDateRange();
        }
        return minDate;
    }
    public Date getMaxDate()
    {
        if(maxDate == null)
        {
            prepareDateRange();
        }
        return maxDate;
    }
    public Integer getRowCount()
    {
        if(rowCount == -1)
        {
            prepareDateRange();
        }
        return rowCount;
    }
    private void prepareDateRange()
    {
        minDate = maxDate = Date.today();
        List<ProjectEntry> prjs = getProjects();
        for(ProjectEntry prj : prjs)
        {
            rowCount++;
            if(prj.getStartDate() != null && prj.getStartDate() < minDate)
            {
                minDate = prj.getStartDate();
            }
            if(prj.getEndDate() != null && prj.getEndDate() > maxDate)
            {
                maxDate = prj.getEndDate();
            }
        }
        maxDate = maxDate.addDays(10);
    }
    public List<ProjectEntry> getProjects()
    {
        if(projects == null)
        {
            projects = new List<ProjectEntry>();
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
        }
        return projects;
    }
    
    public List<ProjectEntry> getAllProjects()
    {
        List<MProject__c> prjs = [select Id, Name, StartDate__c, EndDate__c, Progress__c, ProjectNumber__c, Status__c, 
                                (select User__c, User__r.Alias from TeamMembers__r),
                                (Select Id, Name, CreatedDate, DueDate__c, Status__c, Priority__c, OpenedBy__c, Type__c, AssignedTo__c, AssignedTo__r.Alias From Changes__r where Status__c != 'Closed' and Status__c != 'Cancelled')
                                from MProject__c where Status__c='In Progress'];
        List<ProjectEntry> result = new List<ProjectEntry>();
        Integer i = 0;
        for(MProject__c prj : prjs)
        {
        	if(includeProjects)
        	{
	            List<ResourceEntry> resources = new List<ResourceEntry>();
	            for(TeamMember__c tm : prj.TeamMembers__r)
	            {
	                resources.add(new ResourceEntry(tm.User__c, tm.User__r.Alias));
	            }
	            if(prj.StartDate__c != null && prj.EndDate__c != null)
	            {
	            	result.add(new ProjectEntry(i++, 0, prj.Id, prj.Name, prj.StartDate__c, prj.EndDate__c, prj.Status__c, prj.Progress__c, resources));
	            }
        	}
        	if(includeChanges)
        	{
        		for(Change__c chg : prj.Changes__r)
	            {
	                Date startDate = Date.newInstance(chg.CreatedDate.year(), chg.CreatedDate.month(), chg.createdDate.day());
	                if(chg.DueDate__c == null)
	                {
	                	chg.DueDate__c = Date.today();
	                }
	                result.add(new ProjectEntry(i++, 2, chg.Id, chg.Name, startDate, chg.DueDate__c, chg.Status__c, 0, new ResourceEntry[] {new ResourceEntry(chg.AssignedTo__c, chg.AssignedTo__r.Alias)}));
	            }
        	}
        }
        return result;                  
    }
    private List<ProjectEntry> getProjectsByPid(String pid)
    {
        List<MProject__c> projects = [select Id, Name, StartDate__c, EndDate__c, ProjectNumber__c, Progress__c,Status__c,
                                    (select User__c, User__r.Alias from TeamMembers__r),
                                    (Select Id, Name, CreatedDate, DueDate__c, Status__c, Priority__c, OpenedBy__c, Type__c, AssignedTo__c, AssignedTo__r.Alias From Changes__r where Status__c != 'Closed' and Status__c != 'Cancelled')
                                    from MProject__c where Id=:pid Limit 1];
        List<ProjectEntry> result = new List<ProjectEntry>();
        Integer i=0;
        if(projects.size() > 0)
        {
        	MProject__c prj = projects[0];
        	if(includeProjects)
        	{
	            List<ResourceEntry> resources = new List<ResourceEntry>();
	            for(TeamMember__c tm : prj.TeamMembers__r)
	            {
	                resources.add(new ResourceEntry(tm.User__c, tm.User__r.Alias));
	            }
	            if(prj.StartDate__c != null && prj.EndDate__c != null)
	            {
	            	result.add(new ProjectEntry(i++, 0, prj.Id, prj.Name, prj.StartDate__c, prj.EndDate__c, prj.Status__c, prj.Progress__c, resources));
	            }
        	}
        	if(includeChanges)
        	{
	            for(Change__c chg : prj.Changes__r)
	            {
	                Date startDate = Date.newInstance(chg.CreatedDate.year(), chg.CreatedDate.month(), chg.createdDate.day());
	                if(chg.DueDate__c == null)
	                {
	                	chg.DueDate__c = Date.today();
	                }
	                result.add(new ProjectEntry(i++, 2, chg.Id, chg.Name, startDate, chg.DueDate__c, chg.Status__c, 0, new ResourceEntry[] {new ResourceEntry(chg.AssignedTo__c, chg.AssignedTo__r.Alias)}));
	            }
        	}
        }
        return result;
    }
    
    private List<ProjectEntry> getProjectsByUid(String uid)
    {
        List<MProject__c> prjs = [select Id, Name, StartDate__c, EndDate__c, ProjectNumber__c, Progress__c, Status__c,
                                (select User__c, User__r.Alias from TeamMembers__r), 
                                (Select Id, Name, CreatedDate, DueDate__c, Status__c, Priority__c, OpenedBy__c, Type__c, AssignedTo__c, AssignedTo__r.Alias From Changes__r where AssignedTo__c=:uid and Status__c != 'Closed' and Status__c != 'Cancelled') 
                                from MProject__c where Status__c='In Progress'];
                                
        List<ProjectEntry> result = new List<ProjectEntry>();
        Integer i=0;
        for(MProject__c prj : prjs)
        {
        	if(includeProjects)
        	{
	            for(TeamMember__c tm : prj.TeamMembers__r)
	            {
	                if(tm.User__c == uid)
	                {
	                    List<ResourceEntry> resources = new List<ResourceEntry>();
	                    for(TeamMember__c tm2 : prj.TeamMembers__r)
	                    {
	                        resources.add(new ResourceEntry(tm2.User__c, tm2.User__r.Alias));
	                    }
	                    if(prj.StartDate__c != null && prj.EndDate__c != null)
	                    {
	                    	result.add(new ProjectEntry(i++, 0, prj.Id, prj.Name, prj.StartDate__c, prj.EndDate__c, prj.Status__c, prj.Progress__c, resources));
	                    }
	                    break;
	                }
	            }
        	}
        	if(includeChanges)
        	{
	            for(Change__c chg : prj.Changes__r)
	            {
	                Date startDate = Date.newInstance(chg.CreatedDate.year(), chg.CreatedDate.month(), chg.createdDate.day());
	                if(chg.DueDate__c == null)
	                {
	                	chg.DueDate__c = Date.today();
	                }
	                result.add(new ProjectEntry(i++, 2, chg.Id, chg.Name, startDate, chg.DueDate__c, chg.Status__c, 0, new ResourceEntry[] {new ResourceEntry(chg.AssignedTo__c, chg.AssignedTo__r.Alias)}));
	            }
        	}
        }
        return result;
    }
    
    public PageReference refresh()
    {
    	return null;
    }
    public class ProjectEntry
    {
        private Integer pno;
        private Integer pindent;
        private String pid;
        private String pname;
        private Date pstartDate;
        private Date pendDate;
        private String pstatus;
        private Decimal pprogress;
        private ResourceEntry[] presources;
        
        public ProjectEntry(Integer no, Integer indent, String id, String name, Date startDate, Date endDate, String status, Decimal progress, ResourceEntry[] resources)
        {
            this.pno = no;
            this.pindent = indent;
            this.pid = id;
            this.pname = name;
            this.pstartDate = startDate;
            this.pendDate = endDate;
            this.pstatus = status;
            this.pprogress = progress;
            this.presources = resources;
        }
        public Integer getNo()
        {
            return pno;
        }
        public Integer getIndent()
        {
            return pindent;
        }
        public String getId()
        {
            return pid;
        }
        public String getName()
        {
            return pname;
        }
        public String getStatus()
        {
            return pstatus;
        }
        public Date getStartDate()
        {
            return pstartDate;
        }
        public Date getEndDate()
        {
            return pendDate;
        }
        public Decimal getProgress()
        {
            return pprogress;
        }
        public List<ResourceEntry> getResources()
        {
            return presources;
        }
        public String getTip()
        {
            return '<b>Start</b>: ' + pstartDate.format() + '<br/>' + 
                    '<b>End</b>: ' + pendDate.format();
        }
    }
    public class ResourceEntry
    {
        private String rid;
        private String rname;
        
        public ResourceEntry(String id, String name)
        {
            this.rid = id;
            this.rname = name;
        }
        
        public String getId()
        {
            return rid;
        }
        public String getName()
        {
            return rname;
        }
    }
    @isTest
    static void testGanttViewHomeController()
    {
		//ProjectManagementHelper projectHelper = new ProjectManagementHelper();
		MProject__c project = new MProject__c();
		Customer__c customer = new Customer__c();
		customer.Name = 'Harvey';
		insert customer;
		project.Name = 'Acme';
		project.Customer__c = customer.Id;
		project.Status__c = 'In Progress'; 
		project.Priority__c = 'Low';
		project.StartDate__c = Date.valueOf('2010-9-9');
		project.EndDate__c = Date.valueOf('2010-9-30');
		insert project;    	
        GanttViewHomeController ctrl = new GanttViewHomeController();
        ctrl.getTitle();
        ctrl.getProjects();
        ctrl.getMinDate();
        ctrl.getMaxDate();
        ctrl.getRowCount();
        MProject__c prj = new MProject__c(Name='acme', StartDate__c=Date.today(), EndDate__c=Date.today(), Status__c='In Progress');
        insert prj;
        PageReference p = new PageReference('/apex/GanttViewHome?pid=' + prj.Id);
        Test.setCurrentPage(p);
        ctrl = new GanttViewHomeController();
        ctrl.getProjects();
        p = new PageReference('/apex/GanttViewHome?uid=0058000000298xY');
        Test.setCurrentPage(p);
        ctrl = new GanttViewHomeController();
        ctrl.getProjects(); 
    }
    
    @isTest
    static void testProjectEntry()
    {
        ResourceEntry res = new ResourceEntry('1', 'acme');
        System.assertEquals('1', res.getId());
        System.assertEquals('acme', res.getName());
        ProjectEntry entry = new ProjectEntry(1, 0, 'id', 'acme', Date.today(), Date.today(), 'In Progress', 0.9, new ResourceEntry[] {res});
        System.assertEquals(1, entry.getNo());
        System.assertEquals('id', entry.getId());
        System.assertEquals('acme', entry.getName());
        System.assertEquals(Date.today(), entry.getStartDate());
        System.assertEquals(Date.today(), entry.getEndDate());
        System.assertEquals('In Progress', entry.getStatus());
        System.assertEquals(0.9, entry.getProgress()); 
    }
}