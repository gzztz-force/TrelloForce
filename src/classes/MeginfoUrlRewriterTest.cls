@isTest
public class MeginfoUrlRewriterTest
{
	@isTest
    static void test()
    {
        S3File__c file = new S3File__c(FileName__c='acme', S3Bucket__c='acme', S3Key__c='acme', SizeInBytes__c=20);
        insert file;
        file = [select Id, Name from S3File__c where Id=:file.Id limit 1];
        MeginfoUrlRewriter rewriter = new MeginfoUrlRewriter();
        PageReference result = rewriter.mapRequestUrl(new PageReference('/f/' + file.Name.substring(1, file.Name.length()) + '?query#hash'));
		System.assert(result.getUrl().contains('S3FileDownload'));
        
        List<PageReference> result2 = rewriter.generateUrlFor(new PageReference[] { new PageReference('/acme')});
        System.assertEquals(1, result2.size());
    }
}