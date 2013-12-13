/*
 * Archives attachments and content files on closed projects and changes
 */
trigger ArchiveContent on MProject__c (after update) 
{
	for(MProject__c prj : Trigger.new)
    {
        MProject__c oldPrj = Trigger.oldMap.get(prj.Id);
        if(prj.Status__c == 'Closed' && oldPrj.Status__c != 'Closed')
        {
            System.scheduleBatch(new ContentArchiveJob(prj.Id), 'Batch Upload Content for ' + prj.Id, 0, 1);
        }
    }
}