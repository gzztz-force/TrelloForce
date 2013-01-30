public with sharing class PartnerRegistrationController 
{
	public Lead partnerLead {get; set;}
	public PartnerRegistrationController()
	{
		partnerLead = new Lead();
	}
	public PageReference submit()
	{
		try
		{
			insert partnerLead;
			partnerLead = new Lead();
			return Page.PartnerRegistrationConfirm;			
		}
		catch(Exception ex)
		{
			ApexPages.addMessages(ex);
			return null;
		}
	}
	@isTest
	static void testPartnerRegistrationController()
	{
		PartnerRegistrationController partner = new PartnerRegistrationController();
		partner.submit();
	}
}