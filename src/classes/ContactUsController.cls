public class ContactUsController
{
    public Lead partnerLead {get; set;}
    
    public ContactUsController()
    {
        partnerLead = new Lead();
    }
    
    public PageReference submit()
    {
        try
        {
            insert partnerLead;
            partnerLead = new Lead();
            return Page.registrationconfirm;      
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }
    }
    
    @isTest
    static void testContactUsController()
    {
        ContactUsController partner = new ContactUsController();
        partner.submit();
    }
}