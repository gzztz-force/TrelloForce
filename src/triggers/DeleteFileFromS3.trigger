/*
 * Submits a request to s3 to remove file
 */
trigger DeleteFileFromS3 on S3File__c (after delete) 
{
    Set<String> s3keys = new Set<String>();
    String bucket = '';
	for(S3File__c file : Trigger.old)
    {
        bucket = file.S3Bucket__c;
        s3keys.add(file.S3Key__c);
    }
    S3API.willDeleteFiles(bucket, s3keys);
}