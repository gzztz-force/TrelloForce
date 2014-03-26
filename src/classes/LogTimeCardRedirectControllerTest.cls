@isTest
public class LogTimeCardRedirectControllerTest
{
    @isTest 
    static void testRedirect()
    {
        PageReference currentPage = new PageReference('/apex/LogTimeCardRedirect');
        
        currentPage.getHeaders().put('HTTP_X_SKYFIRE_PHONE','ipad');
        Test.setCurrentPage(currentPage);
        boolean isMobile = new LogTimeCardRedirectController().IsMobile;
        system.assert(isMobile);
        
        currentPage.getHeaders().put('HTTP_X_SKYFIRE_PHONE','windows');
        Test.setCurrentPage(currentPage);
        isMobile = new LogTimeCardRedirectController().IsMobile;
        system.assert(isMobile == false);
    }
}