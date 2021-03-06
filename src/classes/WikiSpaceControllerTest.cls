@isTest
public class WikiSpaceControllerTest
{
    private static Integer spaceNumber = 5;
    private static Integer pageNumber = 10;

    static testmethod void test()
    {
        createData();
        WikiSpace__c space = [select Id, Name from WikiSpace__c ].get(1);

        //test spaceId is not blank
        PageReference pageRef = new ApexPages.PageReference('/apex/WikiSpace');
        pageRef.getParameters().put('id', space.Id);
        Test.setCurrentPage(pageRef);
        WikiSpaceController controller = new WikiSpaceController();
        System.assertEquals('space1', controller.SpaceName);
        System.assertEquals(5, controller.Spaces.size());
        System.assertEquals(10, controller.WikiPages.size());

        //test spaceId is blank
        PageReference pageRef2 = new ApexPages.PageReference('/apex/WikiSpace');
        pageRef2.getParameters().put('id', NULL);
        Test.setCurrentPage(pageRef2);
        WikiSpaceController controller2 = new WikiSpaceController();
        System.assertEquals(controller2.SpaceId,[select Id from WikiSpace__c].get(0).Id);
    }

    private static void createData()
    {
        List<WikiSpace__c> spaces = new List<WikiSpace__c>();
        List<WikiPage__c> pages = new List<WikiPage__c>();
        List<WikiPageVersion__c> versions = new List<WikiPageVersion__c>();
        for(Integer i=0; i<spaceNumber; i++)
        {
            spaces.add(new WikiSpace__c(Name = 'space' + i));
        }
        insert spaces;

        for(WikiSpace__c space : spaces)
        {
            for(Integer i=0; i<pageNumber; i++)
            {
                pages.add(new WikiPage__c(WikiSpace__c = space.Id));
            }
        }
        insert pages;

        for(WikiPage__c page : pages)
        {
            versions.add(new WikiPageVersion__c(Title__c = 'title', Body__c = 'body', WikiPage__c = page.Id, IsLatestVersion__c = true));
        }
        insert versions;
    }
}