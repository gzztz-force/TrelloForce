/**
 * Controller class of the Change Editor page.
 */
public class ChangeEditorController
{
    private Map<String, String> parameters = ApexPages.currentPage().getParameters();
    private List<Follower> changeFollowers;

    public ChangeEditorController(ApexPages.StandardController controller)
    {
        Change = (Change__c)controller.getRecord();
        HasProject = true;
        System.debug(UserInfo.getUserType());
        if(Change.Id == null)
        {
            String projectId = ApexPages.currentPage().getParameters().get('CF00N80000003kHRB_lkid');
            if(projectId instanceOf Id)
            {
                //Change.Project__c = projectId;
            }
            else
            {
                HasProject = false;
            }
        }
        else
        {
            Change = [Select Type__c, Status__c, Project__c, Priority__c, OpenedBy__c, Name, Id, Estimate__c, DueDate__c, Description__c, CustomerName__c, ChangeNumber__c, Billed__c, Billable__c, AssignedTo__c, Age__c From Change__c where Id = :Change.Id];
        }
    }

    public PageReference redirect()
    {
        return null;
    }

    public Boolean IsEditable
    {
      get
      {
        if(Change.Id == null)
        {
          return true;
        }
        else
        {
          for(TeamMember__c member : [select Id, User__c from TeamMember__c where Project__c=:Change.Project__c])
              {
                if(IsAdministrator || member.User__c == UserInfo.getUserId())
                {
                  return true;
                }
              }
              return false;
        }
      }
    }

    public Change__c Change { get; set; }
    public Boolean HasProject { get; private set; }
    public List<Follower> Followers
    {
      get
      {
        if(changeFollowers == null)
        {
          changeFollowers = new List<Follower>();
          Set<Id> existedFollowers = new Set<Id>();
            if(Change.Id != null)
            {
                for(EntitySubscription subscriber : [select Id, SubscriberId from EntitySubscription where ParentId = :Change.Id])
                {
                    existedFollowers.add(subscriber.SubscriberId);
                }
            }
            for(TeamMember__c member : [select Id, Name, User__c, Role__c, isActiveUser__c from TeamMember__c where Project__c = :Change.Project__c and isActiveUser__c = true order by User__r.FirstName])
            {
                Boolean checked = existedFollowers.contains(member.User__c);
                changeFollowers.add(new Follower(member.User__c, member.Name, checked));
            }
        }
          return changeFollowers;
      }
    }
    public List<SelectOption> AssignToUsers
    {
        get
        {
                List<SelectOption> result = new List<SelectOption>();
                result.add(new SelectOption('', '-- Select a user --'));
                for(Follower f : Followers)
                {
                    result.add(new SelectOption(f.FollowerId, f.Name));
                }
                return result;
        }
    }
    private Boolean IsAdministrator
    {
      get
      {
        Profile profile = [select Id, Name from Profile where Id=:UserInfo.getProfileId() limit 1];
        if(profile.Name.toLowerCase().indexOf('admin') >= 0)
        {
          return true;
        }
        else
        {
          return false;
        }
      }
    }

    /**
     * invoked by the an action in the page to refresh the followers
     */
    public PageReference refreshFollowers()
    {
        changeFollowers = null;
        return null;
    }

    /**
     * Saves the change and adds followers to the change.
     */
    public PageReference save()
    {
        // Assigns current user as the opener of the change if the change is a new one.
        try
        {
            if(Change.Id == null)
            {
                Change.OpenedBy__c = UserInfo.getUserId();
                upsert Change;
                saveFollowers();
            }
            else
            {
                saveFollowers();
                upsert Change;
            }
            return new PageReference('/' + Change.Id);
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }
    }

    /**
     * Saves current change and followers, goes to the new page to create a change.
     */
    public PageReference saveAndNew()
    {
        save();
        PageReference newChange = Page.ChangeEditor;
        for(String param : parameters.keySet())
        {
            if(!param.equalsIgnoreCase('id'))
            {
                newChange.getParameters().put(param, parameters.get(param));
            }
        }
        newChange.setRedirect(true);
        return newChange;
    }

    private void saveFollowers()
    {
        Set<Id> subscribers = new Set<Id>();
        subscribers.add(Change.OpenedBy__c);
        subscribers.add(Change.AssignedTo__c);
        for(Follower follower : Followers)
        {
            if(follower.Selected)
            {
                subscribers.add(follower.FollowerId);
            }
        }
        addFollowers(Change.Id, subscribers);
    }

    /**
     * Automatically follows the change for the selected team members.
     */
    private void addFollowers(Id parentId, Set<Id> subscriberIds)
    {
        Map<Id, EntitySubscription> existedSubscribers = new Map<Id, EntitySubscription>();
        for(EntitySubscription subscriber : [select Id, SubscriberId from EntitySubscription where ParentId = :parentId])
        {
            existedSubscribers.put(subscriber.SubscriberId, subscriber);
        }
        List<EntitySubscription> subscribers = new List<EntitySubscription>();
        for(Id subscriberId : subscriberIds)
        {
            if(subscriberId != null && !existedSubscribers.keySet().contains(subscriberId))
            {
                EntitySubscription subscriber = new EntitySubscription(ParentId = parentId, SubscriberId = subscriberId);
                subscribers.add(subscriber);
            }
            else
            {
                existedSubscribers.remove(subscriberId);
            }
        }
        if(subscribers.size() > 0)
        {
            Database.insert(subscribers, false);
        }
        if(existedSubscribers.keySet().size() > 0)
        {
            Database.delete(existedSubscribers.values(), false);
        }
    }

    /**
     * Inner class, presents the chatter follower. 
     */
    class Follower
    {
        public Follower(Id fid, String name, Boolean selected)
        {
            this.FollowerId = fid;
            this.Name = name;
            this.Selected = selected;
        }
        public Id FollowerId { get; set; }
        public String Name { get; set; }
        public Boolean Selected { get; set; }
    }

    /**
     * Tests create a new change from the changes tab(no project assigned).
     *
     * Test Case:
     * 1. goes to the ChangeEditor page;
     * 2. assigns the project, asserts the team member(follower) amount;
     * 3. saves the change, asserts the team member.
     */
    @isTest
    static void testCreateNewChange()
    {
        User u = [select Id, UserPreferencesDisableAutoSubForFeeds from User where Id = :UserInfo.getUserId()];
        u.UserPreferencesDisableAutoSubForFeeds = false;
        system.runAs(u)
        {
            MProject__c project = new MProject__c();
            insert project;
            TeamMember__c member = new TeamMember__c(Project__c = project.Id, User__c = UserInfo.getUserId());
            insert member;
            MProject__c projectWithoutMember = new MProject__c();
            insert projectWithoutMember;

            PageReference newChangePage = Page.ChangeEditor;
            Test.setCurrentPage(newChangePage);
            ChangeEditorController controller = new ChangeEditorController(new ApexPages.Standardcontroller(new Change__c()));

            controller.Change.Project__c = projectWithoutMember.Id;
            controller.refreshFollowers();
            system.assertEquals(0, controller.Followers.size());

            controller.Change.Project__c = project.Id;
            controller.refreshFollowers();
            system.assertEquals(1, controller.Followers.size());

            controller.Change.AssignedTo__c = UserInfo.getUserId();
            controller.Change.OpenedBy__c = UserInfo.getUserId();
            controller.Change.Description__c = 'this is a test';
            controller.saveAndNew();
            system.assert([select Id, SubscriberId from EntitySubscription where ParentId = :controller.Change.Id].size() == 1);
        }
    }

    /**
     * Tests create a new change from the project details page.
     *
     * Test Case:
     * 1. goes to the ChangeEditor page, asserts the team member(follower) amount;
     * 2. saves the change, asserts the subscrbers.
     */
    @isTest
    static void testCreateNewChangeWithProject()
    {
        User u = [select Id, UserPreferencesDisableAutoSubForFeeds from User where Id = :UserInfo.getUserId()];
        u.UserPreferencesDisableAutoSubForFeeds = false;
        system.runAs(u)
        {
            MProject__c project = new MProject__c();
            insert project;
            for(User user : [select Id from User where Id != :UserInfo.getUserId() and IsActive = true limit 3])
            {
                TeamMember__c member = new TeamMember__c(Project__c = project.Id, User__c = user.Id);
                insert member;
            }

            PageReference newChangePage = Page.ChangeEditor;
            Test.setCurrentPage(newChangePage);
            ChangeEditorController controller = new ChangeEditorController(new ApexPages.Standardcontroller(new Change__c(Project__c=project.Id)));

            system.assertEquals(3, controller.Followers.size());

            controller.Change.AssignedTo__c = UserInfo.getUserId();
            controller.Change.OpenedBy__c = UserInfo.getUserId();
            controller.Change.Description__c = 'this is a test';
            controller.Followers[0].Selected = true;
            controller.Followers[1].Selected = true;
            controller.saveAndNew();
            //system.assertEquals(3, [select count() from EntitySubscription where ParentId = :controller.Change.Id]);
        }
    }

    /**
     * Tests edit an existing change.
     *
     * Test Case:
     * 1. goes to the ChangeEditor page;
     * 2. edits the change, asserts the subscribers.
     */
    @isTest
    static void testEditChange()
    {
        User u = [select Id, UserPreferencesDisableAutoSubForFeeds from User where Id = :UserInfo.getUserId()];
        u.UserPreferencesDisableAutoSubForFeeds = false;
        system.runAs(u)
        {
            MProject__c project = new MProject__c();
            insert project;
            for(User user : [select Id from User where Id != :UserInfo.getUserId() and IsActive = true limit 2])
            {
                TeamMember__c member = new TeamMember__c(Project__c = project.Id, User__c = user.Id);
                insert member;
            }
            Change__c change = new Change__c(Project__c = project.Id, AssignedTo__c = UserInfo.getUserId(), OpenedBy__c = UserInfo.getUserId(), Description__c = 'this is a test');
            insert change;

            PageReference newChangePage = Page.ChangeEditor;
            Test.setCurrentPage(newChangePage);
            ChangeEditorController controller = new ChangeEditorController(new ApexPages.Standardcontroller(change));

            system.assertEquals(2, controller.Followers.size());
            List<SelectOption> assignsTo = controller.AssignToUsers;
            controller.Change.AssignedTo__c = UserInfo.getUserId();
            controller.Change.OpenedBy__c = UserInfo.getUserId();
            controller.Change.Description__c = 'edit test';
            controller.Followers[0].Selected = true;
            controller.saveAndNew();
            //system.assertEquals(2, [select count() from EntitySubscription where ParentId = :controller.Change.Id]);
        }
    }
}