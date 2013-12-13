/* 
 * Sets the default Opener to current user
 */
trigger SetDefaultOpener on Change__c (before insert) 
{
    for(Change__c chg : Trigger.new)
    {
        if(chg.OpenedBy__c == null)
        {
            chg.OpenedBy__c = UserInfo.getUserId();
        }
    }
}