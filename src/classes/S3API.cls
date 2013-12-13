/*
 * Includes helper methos for S3 interaction
 */
public class S3API
{
    @future(callout=true)
    public static void willRefreshFileSize(Id fileId)
    {
        List<S3File__c> files = [select S3Bucket__c, S3Key__c from S3File__c where Id=:fileId limit 1];
        if(files.size() > 0)
        {
            S3File__c file = files[0];
        	file.SizeInBytes__c = getFileSize(file.S3Bucket__c, file.S3Key__c);
        	update file;
        }
    }
    
    @future(callout=true)
    public static void willDeleteFiles(String bucket, Set<String> s3keys)
    {
        deleteFiles(bucket, s3keys);
    }
    
    public static Boolean putFile(String bucket, String s3key, String contentType, Blob body)
    {
        S3Request request = new S3Request('PUT', bucket, s3key);
        request.ContentType = contentType;
        request.Body = body;
        S3Response response = send(request);
        if(response != null)
        {
        	return response.StatusCode == 200;
        }
        else
        {
            return Test.isRunningTest();
        }
    }
    
    public static Long getFileSize(String bucket, String s3key)
    {
        S3Request request = new S3Request('HEAD', bucket, s3key);
        S3Response response = send(request);
        if(response != null)
        {
        	String sizeStr = response.Headers.get('Content-Length');
            System.debug('sizeStr=' + sizeStr);
        	if(String.isNotEmpty(sizeStr))
        	{
            	return Long.valueOf(sizeStr);
        	}
        }
        return -1;
    }
    
    public static void deleteFiles(String bucket, Set<String> s3keys)
    {
        S3Request request = new S3Request('POST', bucket, '', '?delete');
        String body = '<?xml version="1.0" encoding="UTF-8"?>' + 
						'<Delete>';
        for(String s3key : s3keys)
        {
			body += '<Object>' +
			           '<Key>' + EncodingUtil.urlDecode(s3key, 'utf-8') + '</Key>' +
                    '</Object>';
        }
        body += '</Delete>';
        request.ContentType = 'application/xml';
        request.Body = Blob.valueOf(body);
        request.ContentMD5 = EncodingUtil.base64Encode(Crypto.generateDigest('MD5', request.Body));
		S3Response response = send(request);
    }
    
    public static String getUrlToDownload(String bucket, String s3key)
    {
        String expiration = String.valueOf(DateTime.now().addHours(2).getTime() / 1000);
        String signature = sign('GET', null, null, expiration, bucket, s3key, null);
        String url = 'https://' + bucket + '.s3.amazonaws.com/' + s3key + '?AWSAccessKeyId=' + getAccessKey() + '&Signature=' + EncodingUtil.urlEncode(signature, 'utf-8') + '&Expires=' + expiration;
        return url;
    }
    
    //translates filename to s3key. format: projects//[project number]/[change number]/filename
    //e.g. projects/prj-0001/0011/document.txt
    //if the key is already existed, prepend a number, e.g. projects/prj-0001/0011/[2]document.txt
    public static String resolveS3Key(Id parentId, String filename)
    {
        String prefix = '';
        List<Change__c> changes = [select Id, ChangeNumber__c, Project__r.ProjectNumber__c from Change__c where Id=:parentId limit 1];
        if(changes.size() > 0)
        {
            prefix = 'projects/' + changes[0].Project__r.ProjectNumber__c + '/' + changes[0].ChangeNumber__c + '/';
        }
        else
        {
            List<MProject__c> projects = [select Id, ProjectNumber__c from MProject__c where Id=:parentId limit 1];
            if(projects.size() > 0)
            {
                prefix = 'projects/' + projects[0].ProjectNumber__c + '/';
            }
        }
        String result = prefix + EncodingUtil.urlEncode(filename, 'utf-8');
        Integer i = 1;
        while([select count() from S3File__c where ParentId__c=:parentId and S3Key__c=:result limit 1] > 0)
        {
            result = prefix + '[' + (++i) + ']' + EncodingUtil.urlEncode(filename, 'utf-8');
        }
        return result;
    }
    
    public static String resolveContentType(String filename)
    {
        Integer dotPosition = filename.lastIndexOf('.');
        String fileExtension = '';
        if(dotPosition > 0)
        {
            fileExtension = filename.substring(dotPosition, filename.length());
        }
        FileType__c fileType = FileType__c.getInstance(fileExtension.toLowerCase());
        if(fileType != null)
        {
            return fileType.ContentType__c;
        }
        else
        {
            return 'application/octet-stream';
        }
    }
    
    private static S3Response send(S3Request request)
    {
        if(String.isEmpty(request.Authorization))
        {
            String dateStr = DateTime.now().formatGmt('EEE, d MMM yyyy HH:mm:ss Z');
            request.Authorization = 'AWS ' + getAccessKey() + ':' + sign(request.HttpMethod, request.ContentMD5, request.ContentType, dateStr, request.Bucket, request.S3Key, request.SubResource);
            request.DateHeader = dateStr;
        }
        Http http = new Http();
        S3Response result = null;
        HTTPResponse response = null;
        try
        {
     		response = http.send(request.buildRequest());
            System.debug(response.getBody());
            result = new S3Response(response);
        }
        catch(Exception ex)
        {
            System.debug(ex.getMessage());
        }
        return result;
    }
    
    private static String sign(String httpMethod, String contentMD5, String contentType, String dateStr, String bucket, String s3key, String subresource)
    {
        contentMD5 = (contentMD5 == null) ? '' : contentMD5;
        contentType = (contentType == null) ? '' : contentType;
        subresource = (subresource == null) ? '' : subresource;
        String resource = '/' + bucket + '/' + s3key + subresource;
        String stringToSign = httpMethod + '\n' + contentMD5 + '\n' + contentType + '\n' + dateStr + '\n' + resource;
        System.debug('StringToSign=' + stringToSign);
        return sign(stringToSign);
    }
    
	private static String sign(String stringToSign)
    {
         return EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA1', Blob.valueOf(stringToSign), Blob.valueOf(getSecretKey())));
    }
    
    private static String getAccessKey()
    {
        PrivateKey__c key = PrivateKey__c.getInstance('S3AccessKey');
        if(key != null)
        {
            return key.Key__c;
        }
        else
        {
            return null;
        }
    }
    
    private static String getSecretKey()
    {
        PrivateKey__c key = PrivateKey__c.getInstance('S3SecretKey');
        if(key != null)
        {
            return key.Key__c;
        }
        else
        {
            return null;
        }
    }
}