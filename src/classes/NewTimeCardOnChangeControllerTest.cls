/*
 * Test method for class NewTimeCardOnChangeController.
 */
@isTest
private class NewTimeCardOnChangeControllerTest
{
    @isTest
    static void withNullChange()
    {
        PageReference pageReference = Page.NewTimeCardOnChange;
        pageReference.getParameters().put('cid', '');
        Test.setCurrentPage(pageReference);
        NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();
        String url = controller.redirect().getUrl();

        System.assert(url.contains('/a0L/e'));
    }
    
    @isTest
    static void withChangeAndWithoutMember()
    {
        MProject__c project = TestDataFactory.generateSampleActiveProject('ntcocc');
        insert project;

        Change__c change = TestDataFactory.generateSampleChange(project.Id, 'new change for timecard');
        insert change;

        PageReference pageReference = Page.NewTimeCardOnChange;
        Test.setCurrentPage(pageReference);
        ApexPages.currentPage().getParameters().put('cid', change.Id); 
        NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();        
        String url = controller.redirect().getUrl();

        System.assert(url.indexOf('saveUrl') > 0);
        System.assert(url.indexOf(EncodingUtil.urlEncode(UserInfo.getName(), 'UTF-8')) < 0);
    }
    
    @isTest
    static void withChangeAndWithMembers()
    {
        MProject__c project = TestDataFactory.generateSampleActiveProject('ntcocc');
        insert project;

        Change__c change = TestDataFactory.generateSampleChange(project.Id, 'new change for timecard');
        insert change;
        
        TeamMember__c member = TestDataFactory.generateSampleTeamMember(project);
        insert member;

        PageReference pageReference = Page.NewTimeCardOnChange;
        pageReference.getParameters().put('cid', change.Id);    
        Test.setCurrentPage(pageReference);
        NewTimeCardOnChangeController controller = new NewTimeCardOnChangeController();
        String url = controller.redirect().getUrl();

        System.assert(url.indexOf(EncodingUtil.urlEncode(UserInfo.getName(), 'UTF-8')) > 0);
        System.assert(url.indexOf('saveUrl') > 0);
    }
}