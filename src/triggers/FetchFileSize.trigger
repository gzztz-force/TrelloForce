/*
 * Gets the size of s3 file on insert
 * Supports up to 5 files in a transaction
 */
trigger FetchFileSize on S3File__c (after insert) 
{
    Integer i = 0;
	for(S3File__c file : Trigger.new)
    {
        if(file.SizeInBytes__c == null || file.SizeInBytes__c <= 0)
        {
            if(i++ > 5)
            {
                break;
            }
            S3API.willRefreshFileSize(file.Id);
        }
    }
}