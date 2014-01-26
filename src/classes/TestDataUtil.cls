@isTest
public class TestDataUtil 
{
	public static void createTimeCardSyncSettings()
	{
		TimeCardSyncSetting__c setting = new TimeCardSyncSetting__c();
		setting.Name = 'Eric He';
		setting.Email__c = 'eric.he@meginfo.com';
		setting.Endpoint__c = 'https://inlab-developer-edition.ap1.force.com/services/apexrest/TimeCardManagment/';
		insert setting;
	}
	public static String createCustomer(String customerName)
	{
		Customer__c newCustomer = new Customer__c(Name = customerName);
		insert newCustomer;
		return newCustomer.Id;
	}	

	public static String createProject(String customerId, String projectName)
	{
		MProject__c newProject = new MProject__c(Name = projectName, Customer__c = customerId);
		newProject.StartDate__c = Date.today();
		newProject.EndDate__c = Date.today().addYears(1);
		insert newProject;
		return newProject.Id;
	}
	public static String createTeamMember(String projectId)
	{
		TeamMember__c newTeamMember = new TeamMember__c(Project__c = projectId, User__c = UserInfo.getUserId());
		insert newTeamMember;
		return newTeamMember.Id;
	}
	public static List<Change__c> createChanges(String projectId)
	{		
		List<Change__c> changes = new List<Change__c>();
		for(Integer i = 0; i < 2; i++)
		{
			changes.add(new Change__c(Project__c = projectId,
							Name = 'Test Change' + i,
							Description__c = 'Test Change Details',
							DueDate__c = Date.today().addMonths(1),
							Status__c = 'Open',
							OpenedBy__c = UserInfo.getUserId(),
							AssignedTo__c = UserInfo.getUserId()));		
		}
		// The first chage is created without specifying the External ID.
		changes[1].ExternalID__c = 'external id';
		insert changes;
		return changes;
	}
	public static List<TimeCard__c> createTimeCards(String projectId, String temMemberId, List<Change__c> changes)
	{
		List<TimeCard__c> timeCards = new List<TimeCard__c>();
		for(Integer i = 0; i < 3; i ++)
		{
			timeCards.add(new TimeCard__c(Project__c = projectId,
								Date__c = Date.today(),
								TeamMember__c = temMemberId,
								Hours__c = 8,
								Description__c = 'Test Time Card' + i));			
		}
		// The first TimeCard is created with Change field populated, but the specified Change has no External ID.
		// The second TimeCard is also created with Change field populated, and the specified Change does have External ID.
		// The third TimeCard is created without specifying any Change.
		timeCards[0].Change__c = changes[0].Id;
		timeCards[1].Change__c = changes[1].Id;			
		insert timeCards;
		return timeCards;
	}	
}