@isTest
private class TestTimeCardSyncAutomation 
{
	@isTest 
	static void testTimeCardSyncService()
	{
		TestDataUtil.createTimeCardSyncSettings();
		String customerId = TestDataUtil.createCustomer('Touchpoint Solutions');
		String projectId = TestDataUtil.createProject(customerId, 'Touchpoint project');
		String teamMemberId = TestDataUtil.createTeamMember(projectId);
		List<Change__c> changes = TestDataUtil.createChanges(projectId);

		// Three TimeCard records are created.
		// The first TimeCard is created with Change field populated, but the specified Change has no External ID.
		// The second TimeCard is also created with Change field populated, and the specified Change does have External ID.
		// The third TimeCard is created without specifying any Change.		
		List<TimeCard__c> timeCards = TestDataUtil.createTimeCards(projectId, teamMemberId, changes);
        
		Test.startTest();		
		TimeCardSyncService.invokeTimeCardSync();
		Test.stopTest();
	}

	@isTest 
	static void testTimeCardSyncScheduler() 
	{
		Test.startTest();

		Date tomorrow = Date.today().addDays(1);
		String scheduleRunTime = '0 0 0 ' + tomorrow.day() + ' ' + tomorrow.month() + ' ? ' + tomorrow.year();
		system.schedule('Test Card Sync Automation', scheduleRunTime, new TimeCardSyncScheduler());

		Test.stopTest();
	}
}