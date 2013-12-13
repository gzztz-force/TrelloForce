/*
 * Rewrites the path to meginfo resources
 * Includes the s3 file redirection only
 */
global class MeginfoUrlRewriter implements Site.UrlRewriter
{
    private String fileNumber = null;
    
	global PageReference mapRequestUrl(PageReference friendlyUrl)
    {
        PageReference result = friendlyUrl;
        if(isDownloadLink(friendlyUrl.getUrl().toLowerCase()))
        {
            List<S3File__c> files = [select Id from S3File__c where Name=:fileNumber limit 1];
            if(files.size() == 1)
            {
                result = new PageReference('/apex/S3FileDownload?id=' + files[0].Id);
            }
        }
        return result;
    }
    
    global PageReference[] generateUrlFor(PageReference[] salesforceUrls)
    {
        return salesforceUrls;
    }
    
    private Boolean isDownloadLink(String url)
    {
        if(url.indexOf('#') > 0)
        {
            url = url.substring(0, url.indexOf('#'));
        }
        if(url.indexOf('?') > 0)
        {
            url = url.substring(0, url.indexOf('?'));
        }
        if(url.startsWith('/'))
        {
            url = url.substring(1, url.length());
        }
        String[] urlComponents = url.split('[/]');
        Boolean result = false;
        if(urlComponents.size() == 2 && urlComponents[0] == 'f')
        {
            result = urlComponents[1].isNumeric();
            fileNumber = 'F' + urlComponents[1];
        }
        return result;
    }
}