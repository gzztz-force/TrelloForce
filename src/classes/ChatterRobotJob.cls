/*
 * scheduled job to post chatter feed according to the custom setting
 */
global class ChatterRobotJob implements Schedulable
{
    global void execute(SchedulableContext ctx) 
    {
        String content = '';
        String userId = '';
        String parentId = '';
        
        List<ChatterRobotFeed__c> feeds = [select Id, Name, Content__c, ParentId__c, UserId__c from ChatterRobotFeed__c];
        if(feeds.size() > 0)
        {
            Integer index = Math.floor(Math.random() * feeds.size()).intValue();
            content = feeds[index].Content__c;
            userId = feeds[index].UserId__c;
            parentId = feeds[index].ParentId__c;
        }
        
        if(content != '' && userId != '' && parentId != '')
        {
            postFeed(parentId, userId, content);
        }
    }
    
    private void postFeed(String parentId, String userId, String content)
    {
        FeedItem feed = new FeedItem(ParentId=parentId, Type='TextPost', Body=content, CreatedById=userId);
        Database.Insert(feed, false);
    }
    
    @isTest
    static void testChatterRobotJob()
    {
        ChatterRobotJob job = new ChatterRobotJob();
        job.execute(null);
    }
}