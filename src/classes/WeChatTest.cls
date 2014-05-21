@isTest
private class WeChatTest {

    @isTest static void testGet()
    {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'http://dev-free-1221690e881.cs1.force.com/wechat';
        req.httpMethod = 'GET';
        req.addParameter('signature', 'a2fa8ff400b96b8099bc9c6aa1e8b18649a53cdb');
        req.addParameter('timestamp', '1234556789');
        req.addParameter('nonce', 'justyoulike123');
        req.addParameter('echostr', 'othernumber');
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.verifyAccount();
    }

    @isTest static void testPost()
    {

        List<MProject__c> projects = TestDataFactory.createProjects();

        TeamMember__c teamMember = new TeamMember__c();
        teamMember.Project__c = projects[0].Id;
        User user = [select Id from User where Name = 'Stefan Xu'];
        teamMember.User__c = user.Id;
        insert teamMember;

        Change__c change = new Change__c();
        change.Name = 'Change test one';
        change.Project__c = projects[0].Id;
        insert change;

        WeChat__c weChat = new WeChat__c();
        weChat.Name = 'oCisGj7Vi_CODzn9H_WiyicnZ7_g';
        weChat.UserId__c = user.Id;
        weChat.UserEmail__c = 'Stefan.Xu@meginfo.com';
        weChat.UserName__c = 'Stefan Xu';
        weChat.IsVerified__c = true;
        insert weChat;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = 'http://dev-free-1221690e881.cs1.force.com/wechat';
        req.httpMethod = 'POST';
        req.addParameter('signature', 'a2fa8ff400b96b8099bc9c6aa1e8b18649a53cdb');
        req.addParameter('timestamp', '1234556789');
        req.addParameter('nonce', 'justyoulike123');
        req.addParameter('echostr', 'randomnumber');
        req.addHeader('Content-Type', 'application/xml');
        String reply = 'First is the incorrect content';
        String body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @ !3 % This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = 'nothing.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @ !3 %' + Date.today().addDays(-1).day() + ' This is the yesterday\' timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        String changeNumber = [select ChangeNumber__c from Change__c limit 1].ChangeNumber__c;
        reply = '#tc @C' + changeNumber + ' !3 %4 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @ !3 %error This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc !3 %20 This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc !3 %22 This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc ! %22 This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc !2 %32 This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @c8732 !2 %32 This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @error !error % This is the second timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        String projectNumber = [select ProjectNumber__c from MProject__c limit 1].ProjectNumber__c;
        reply = '#tc @P' + projectNumber.subString(4) + ' !3 ^29 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @P88888 !3 %28 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA['+reply+']]></Content><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

                reply = '#tc @P88888 !3 %21 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[event]]></MsgType><Event><![CDATA[subscribe]]></Event><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();


        reply = '#tc @P88888 !3 %32 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[event]]></MsgType><Event><![CDATA[click]]></Event><EventKey><![CDATA[LogTCToPro]]></EventKey><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @P88888 !3 %28 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[event]]></MsgType><Event><![CDATA[click]]></Event><EventKey><![CDATA[LogTCToChange]]></EventKey><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

        reply = '#tc @P88888 !3 %28 This is the first timecard.';
        body = '<xml><ToUserName><![CDATA[meginfo]]></ToUserName><FromUserName><![CDATA[oCisGj7Vi_CODzn9H_WiyicnZ7_g]]></FromUserName><CreateTime>13232443434</CreateTime><MsgType><![CDATA[event]]></MsgType><Event><![CDATA[click]]></Event><EventKey><![CDATA[123456789]]></EventKey><MsgId>999999999</MsgId></xml>';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
        WeChatService.receiveMsg();

    }
}