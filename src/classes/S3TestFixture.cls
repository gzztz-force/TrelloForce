/*
 * Includes test methods for s3 integration functionalities.
 */
@isTest
public class S3TestFixture
{
	@isTest
    static void testArchiveAttachment()
    {
        PrivateKey__c key1 = new PrivateKey__c(Name='S3AccessKey', Key__c='123');
        PrivateKey__c key2 = new PrivateKey__c(Name='S3SecretKey', Key__c='123');
        insert new List<PrivateKey__c> { key1, key2 };
            
        MProject__c prj = new MProject__c(Name='acme', Status__c='In Progress');
        insert prj;
        Change__c chg = new Change__c(Name='acme', Project__c=prj.Id, Status__c='Closed', DueDate__c=Date.today());
        insert chg;
        Attachment a = new Attachment(Name='acme', Body=Blob.valueOf('acme'), ParentId=chg.Id, ContentType='text/plain');
        insert a;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new S3CalloutMock());
        prj.Status__c = 'Closed';
        update prj;
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteFile()
    {
        PrivateKey__c key1 = new PrivateKey__c(Name='S3AccessKey', Key__c='123');
        PrivateKey__c key2 = new PrivateKey__c(Name='S3SecretKey', Key__c='123');
        insert new List<PrivateKey__c> { key1, key2 };
        S3File__c file = new S3File__c(FileName__c='acme', S3Bucket__c='acme', S3Key__c='acme');
        insert file;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new S3CalloutMock());
        delete file;
        Test.stopTest();
    }
    
    @isTest
    static void testRefreshFileSize()
    {
        PrivateKey__c key1 = new PrivateKey__c(Name='S3AccessKey', Key__c='123');
        PrivateKey__c key2 = new PrivateKey__c(Name='S3SecretKey', Key__c='123');
        insert new List<PrivateKey__c> { key1, key2 };
            
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new S3CalloutMock());
        S3File__c file = new S3File__c(FileName__c='acme', S3Bucket__c='acme', S3Key__c='acme');
        insert file;
        Test.stopTest();
    }
    
    @isTest
    static void testDownloadFile()
    {
        PrivateKey__c key1 = new PrivateKey__c(Name='S3AccessKey', Key__c='123');
        PrivateKey__c key2 = new PrivateKey__c(Name='S3SecretKey', Key__c='123');
        insert new List<PrivateKey__c> { key1, key2 };
         
        System.assert(S3API.getUrlToDownload('acme', 'acme') != null);
    }
    public class S3CalloutMock implements HttpCalloutMock
    {
		public HttpResponse respond(HttpRequest req) 
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Content-Length', '20');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(200);
    		return res;
        }
    }
}