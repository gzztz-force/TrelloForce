/*
 * A controller for LogTimeCardRedirect page
 */
public with sharing class LogTimeCardRedirectController
{
    public Boolean IsMobile
    {
        get
        {
            return MobileUtil.isMobileBroswer(ApexPages.currentPage());
        }
    }
}