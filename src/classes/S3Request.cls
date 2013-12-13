/*
 * S3Request is a base class of concret s3 requests
 */
public class S3Request
{
    public S3Request(String method, String bucket, String s3key)
    {
        this.HttpMethod = method;
        this.Bucket = bucket;
        this.S3Key = s3key;
        this.URL = 'http://' + bucket + '.s3.amazonaws.com/' + s3key;
    }
    
    public S3Request(String method, String bucket, String s3key, String subresource)
    {
        this(method, bucket, s3key);
        this.SubResource = subresource;
        this.URL += subresource;
    }
    
    public String HttpMethod { get; set; }
    public String Bucket { get; set; }
    public String S3Key { get; set; }
    public String URL { get; set; }
    public String ContentMD5 { get; set; }
    public String ContentType { get; set; }
    public String Authorization { get; set; }
    public String DateHeader { get; set; }
    public String SubResource { get; set; }
    public Blob Body { get; set; }
    
    public HttpRequest buildRequest()
    {
        HttpRequest result = new HttpRequest();
        result.setEndpoint(URL);
        result.setMethod(HttpMethod);
        result.setHeader('Authorization', Authorization);
        result.setHeader('Date', DateHeader);
        if(String.isNotEmpty(ContentType))
        {
            result.setHeader('Content-Type', ContentType);
        }
        if(String.isNotEmpty(ContentMD5))
        {
            result.setHeader('Content-MD5', ContentMD5);
        }
        if(Body != null)
        {
            result.setBodyAsBlob(Body);
        }
        result.setTimeout(60 * 1000);
        return result;
    }
}