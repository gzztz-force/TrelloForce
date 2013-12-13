public class S3Response
{
    public S3Response(HttpResponse response)
    {
        Headers = new Map<String, String>();
        Body = response.getBody();
        StatusCode = response.getStatusCode();
        for(String headerKey : response.getHeaderKeys())
        {
            if(String.isNotEmpty(headerKey))
            {
            	Headers.put(headerKey, response.getHeader(headerKey));
            }
        }
    }
    
    public Map<String, String> Headers { get; set; }
    public Integer StatusCode { get; set; }
    public String Body { get; set; }
}