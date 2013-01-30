/*
 * Controller of page SourceCodeManagement
 */
public with sharing class SourceCodeManagementController 
{
    private MProject__c project;

    public SourceCodeManagementController(ApexPages.StandardController controller) 
    {
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'test'));
        project = (MProject__c)controller.getRecord();
        ProjectSyncing = (project.ScmName__c != null) && (project.ScmName__c != '');
        Branches = [select Id, Name, Type__c, ScmName__c, Sync__c, SyncError__c, LastSyncDate__c from LoginCredential__c where Project__c=:project.Id and RecordType.Name='Salesforce'];
    }
    
    public Boolean ProjectSyncing { get; set; }
    public List<LoginCredential__c> Branches { get; set; }
    public Boolean UserCanEdit
    {
        get
        {
            //User currentUser = [select Id, Profile.Name from User where Id=:UserInfo.getUserId() limit 1];
            //return (currentUser.Profile.Name == 'Force.com - VP');
            return false;
        }
    }
    
    public PageReference clearErrorMessage()
    {
        return null;
    }
    
    @isTest
    static void testSourceCodeManagementController()
    {
        MProject__c prj = new MProject__c(Name='acme');
        insert prj;
        LoginCredential__c login = new LoginCredential__c(Name='test', Type__c='Sandbox', Username__c='test', Password__c='test', Project__c=prj.Id);
        insert login;
        
        SourceCodeManagementController controller = new SourceCodeManagementController(new ApexPages.StandardController(prj));
        
    }
}