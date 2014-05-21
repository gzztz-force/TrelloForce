/*
 * Controller of page NewTimeCardOnChange
 * Navigates the user to the standard New TimeCard page with additional parameters
 * The page is used on the button "New Time Card" on the time card list of Change detail page.
 */
public with sharing class NewTimeCardOnChangeController
{
	private Change__c change;

	public NewTimeCardOnChangeController()
	{
		String changeId = ApexPages.currentPage().getParameters().get('cid');
		List<Change__c> changes = [select Id, Name, Project__c, Project__r.Name from Change__c where Id=:changeId limit 1];
		if(changes.size() > 0)
		{
			change = changes[0];
		}
	}

	public PageReference redirect()
	{
		if(change == null)
		{
			return new PageReference('/a0L/e');
		}
		else
		{
			PageReference result = new PageReference('/a0L/e');
			List<TeamMember__c> members = [select Id, Name from TeamMember__c where Project__c=:change.Project__c and User__c=:UserInfo.getUserId() limit 1];
			if(members.size() > 0)
			{
				result.getParameters().put('CF00N80000003iWpD', UserInfo.getName());
				result.getParameters().put('CF00N80000003iWpD_lkid', members[0].Id);
			}
			result.getParameters().put('saveUrl', '/' + change.Id);
			result.getParameters().put('retURL', '/' + change.Id);
			result.getParameters().put('CF00N80000003iWoa', change.Project__r.Name);
			result.getParameters().put('CF00N80000003iWoa_lkid', change.project__c);
			result.getParameters().put('CF00N80000004LLoX', change.Name);
			result.getParameters().put('CF00N80000004LLoX_lkid', change.Id);
			result.getParameters().put('00N80000003iXok', change.Name + ': ');
			return result;
		}
	}

	@isTest
	static void testNewTimeCardOnChangeController()
	{
		MProject__c project = TestDataFactory.generateSampleActiveProject('acme');
        insert project;

	    Change__c change = TestDataFactory.generateSampleChange(project.Id, 'new change');
        insert change;

		PageReference page = new PageReference('/apex/NewTimeCardOnChange?cid=' + change.Id);
		Test.setCurrentPage(page);
		NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();
		System.assert(controller.redirect() != null);
	}
}