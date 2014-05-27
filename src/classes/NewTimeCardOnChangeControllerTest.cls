/*
 * Test method for class NewTimeCardOnChangeController.
 */
@isTest
private class NewTimeCardOnChangeControllerTest
{
    @isTest
    static void WithNullChange()
    {
        MProject__c project = TestDataFactory.generateSampleActiveProject('ntcocc');
        insert project;

        Change__c change = TestDataFactory.generateSampleChange(project.Id, 'new change for timecard');
        insert change;

        PageReference page = new PageReference('/apex/NewTimeCardOnChange?cid=' + change.Id);

        delete change;

        Test.setCurrentPage(page);
        NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();
        String url = controller.redirect().getUrl();
        System.assert(url.contains('/a0L/e'));
    }
    
    @isTest
    static void WithChangeAndWithoutMember()
    {
        MProject__c project = TestDataFactory.generateSampleActiveProject('ntcocc');
        insert project;

        Change__c change = TestDataFactory.generateSampleChange(project.Id, 'new change for timecard');
        insert change;

        PageReference page = new PageReference('/apex/NewTimeCardOnChange?cid=' + change.Id);    
        Test.setCurrentPage(page);
        NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();
        String url = controller.redirect().getUrl();
        //System.assert(url.containsNone('CF00N80000003iWpD'));
        System.assert(url.contains('saveUrl'));
        System.assert(controller.redirect().getParameters().get('CF00N80000003iWpD')==null);
    }
    
    @isTest
    static void WithChangeAndWithMembers()
    {
        MProject__c project = TestDataFactory.generateSampleActiveProject('ntcocc');
        insert project;

        Change__c change = TestDataFactory.generateSampleChange(project.Id, 'new change for timecard');
        insert change;
        
        TeamMember__c member = TestDataFactory.generateSampleTeamMember(project);
        insert member;

        PageReference page = new PageReference('/apex/NewTimeCardOnChange?cid=' + change.Id);    
        Test.setCurrentPage(page);
        NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();
        String url = controller.redirect().getUrl();
        System.assert(url.contains('CF00N80000003iWpD'));
        //System.assert(controller.redirect().getParameters().get('CF00N80000003iWpD')!=null);
    }

}