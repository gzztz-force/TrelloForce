/*
 ** This class is used to get all the un-synced time entries for Touchpoint
 ** on daily basis, and import them to Touchpoint org.

 ** Created by Eric on 2014/1/3.
 */
global class TimeCardSyncScheduler implements Schedulable 
{
	global void execute(SchedulableContext sc) 
	{
		TimeCardSyncService.invokeTimeCardSync();
	}
}