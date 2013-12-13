/* 
 * Test methods of S3FileDownloadController
 */
@isTest
public class S3FileDownloadControllerTest
{
	@isTest
    static void test()
    {
        PrivateKey__c key1 = new PrivateKey__c(Name='S3AccessKey', Key__c='123');
        PrivateKey__c key2 = new PrivateKey__c(Name='S3SecretKey', Key__c='123');
        insert new List<PrivateKey__c> { key1, key2 };
        S3File__c file = new S3File__c(FileName__c='acme', S3Bucket__c='acme', S3Key__c='acme', SizeInBytes__c=20, IsPublic__c=false);
        insert file;
        
        S3FileDownloadController controller = new S3FileDownloadController(new ApexPages.StandardController(file));
        controller.redirect();
        file = [select Id, NumberOfDownloads__c from S3File__c where Id=:file.Id limit 1];
        System.assertEquals(1, file.NumberOfDownloads__c);
    }
}