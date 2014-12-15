@isTest
public class MockTrelloHttpResponseGenerator implements HttpCalloutMock {
    //protected Integer code;
    //protected String status;
    //protected String body;
    //protected Map<String, String> responseHeaders;
    private String boardResponse = ''; 
    //'[{"id":"545735a69a0da4e4721950fd","name":"For Trello Test","memberships":[{"id":"545735a69a0da4e4721950fe","idMember":"5456e0a4463c0074fcfa6e17}]},{"id":"5466ba22a3a9a861193a1bf0","name":"TimeLoader","memberships":[{"id":"5466ba22a3a9a861193a1bf1","idMember":"5456e599eb84e75b41283de8"}]}]';

    //public MockTrelloHttpResponseGenerator(Integer code, String status, String body, Map<String, String> responseHeaders) {
    //    this.code = code;
    //    this.status = status;
    //    this.body = body;
    //    this.responseHeaders = responseHeaders;
    //}

    public HTTPResponse respond(HTTPRequest req) {
        //System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if(req.getEndpoint().contains('https://api.trello.com/1/members/my/boards/all'))
        {
            res.setBody('[{"id":"545735a69a0da4e4721950fd","name":"For Trello Test",' +
                            '"desc":"","closed":false,' + 
                                '"memberships":[{"id":"545735a69a0da4e4721950fe","idMember":"5456e0a4463c0074fcfa6e17"}]},' + 
                        '{"id":"5466ba22a3a9a861193a1bf0","name":"TimeLoader",' +
                            '"desc":"","closed":false,' +
                                '"memberships":[{"id":"5466ba22a3a9a861193a1bf1","idMember":"5456e599eb84e75b41283de8"},' +
                                    '{"id":"5466ba39a2c9a7c60c84749e","idMember":"5456e0a4463c0074fcfa6e17"}]},' +
                        '{"id":"5456dd656a8668e557b82685","name":"Trello with PM",' +
                            '"desc":"","closed":false,'+
                                '"memberships":[{"id":"5456dd656a8668e557b82686","idMember":"50ad61a65a55ffe60e00830e"},' +
                                    '{"id":"5456e0a4463c0074fcfa6e19","idMember":"5456e0a4463c0074fcfa6e17"},' +
                                        '{"id":"5456e59aeb84e75b41283e45","idMember":"5456e599eb84e75b41283de8"}]},' +
                        '{"id":"5456e0a5463c0074fcfa6e1d","name":"Welcome Board",'+
                            '"desc":"","descData":null,"closed":false,'+
                                '"memberships":[{"id":"5456e0a5463c0074fcfa6e1e","idMember":"4e6a7fad05d98b02ba00845c"},'+
                                    '{"id":"5456e0a5463c0074fcfa6e22","idMember":"5456e0a4463c0074fcfa6e17"}]}]');
        }
        else if(req.getEndpoint().contains('https://api.trello.com/1/boards/5456dd656a8668e557b82685/cards'))
        {
            res.setBody('[{"id":"54601ee7e0c701d1f7a3d25c","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf4b22bfb75b6de6a4b",'+
                                '"name":"Write Unit test","idChecklists":[],'+
                                    '"idMembers":["5456e599eb84e75b41283de8","5456e0a4463c0074fcfa6e17"]},'+
                        '{"id":"5456df3c74bf690f408a656f","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf8bd315d5ce64b41d5",'+
                                '"name":"Getting Started","idChecklists":[],'+
                                    '"idMembers":[]},'+
                        '{"id":"54601ea8c3b55e32bafa35ab","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf8bd315d5ce64b41d5",'+
                                '"name":"Write insert method","idChecklists":["546052d96f128fb6393bc81e"],'+
                                    '"idMembers":["5456e0a4463c0074fcfa6e17","5456e599eb84e75b41283de8"]},'+
                        '{"id":"546da806cb461443a7f2c29d","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf8bd315d5ce64b41d5",'+
                                '"name":"update teammember","idChecklists":[],'+
                                    '"idMembers":["5456e0a4463c0074fcfa6e17"]},'+
                        '{"id":"54728e0d29dcfac01118d91d","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf8bd315d5ce64b41d5",'+
                                '"name":"Create page to sync data form trello.","idChecklists":[],'+
                                    '"idMembers":["5456e599eb84e75b41283de8"]},'+
                        '{"id":"54601e50181f2f2dba7a2882","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf8bd315d5ce64b41d5",'+
                                '"name":"Modify ERD","idChecklists":[],'+
                                    '"idMembers":["5456e599eb84e75b41283de8"]},'+
                        '{"id":"545ae5597bc18d2c4f3abd1c","closed":false,'+
                            '"idBoard":"5456dd656a8668e557b82685","idList":"5456ddf8bd315d5ce64b41d5",'+
                                '"name":"Match Data model","idChecklists":["545ae566569a88c456889a3d"],'+
                                    '"idMembers":["5456e599eb84e75b41283de8"]}]');
        }
        else if(req.getEndpoint().contains('https://api.trello.com/1/boards/5456dd656a8668e557b82685/checklists'))
        {
            res.setBody('[{"id":"545ae566569a88c456889a3d","name":"Checklist",'+
                            '"idBoard":"5456dd656a8668e557b82685","idCard":"545ae5597bc18d2c4f3abd1c",'+
                                '"checkItems":[{"state":"complete","id":"545ae59de861da11ad8e51a2","name":"Draw a ERD in Lucidchart"},'+
                                    '{"state":"complete","id":"545ae5cbff7e74b6c56a6463","name":"Call with Trello API with token in Apex to get cards for one board@jairzheng "}]},'+
                        '{"id":"546052d96f128fb6393bc81e","name":"Insert",'+
                            '"idBoard":"5456dd656a8668e557b82685","idCard":"54601ea8c3b55e32bafa35ab",'+
                                '"checkItems":[{"state":"complete","id":"546052df1a5a88d0cf22ca11","name":"Boards"},'+
                                    '{"state":"complete","id":"546052eab9d0522b59ec29d8","name":"Cards"},'+
                                        '{"state":"complete","id":"546052f77d4689dccf50eb71","name":"CheckListItems"},'+
                                            '{"state":"incomplete","id":"546168e5c11633260ab38cac","name":"Match User"}]}]');
        }
        else if(req.getEndpoint().contains('https://api.trello.com/1/boards/5456dd656a8668e557b82685/members'))
        {
            res.setBody('[{"id":"5456e599eb84e75b41283de8","fullName":"Evan Zhong","username":"evanzhong"},'+
                        '{"id":"50ad61a65a55ffe60e00830e","fullName":"Jair Zheng","username":"jairzheng"},'+
                        '{"id":"5456e0a4463c0074fcfa6e17","fullName":"Vicky Zhang","username":"vickyzhang3"}]');
        }
        else 
        {
            res.setBody('');
        }
        
        res.setStatusCode(200);
        return res;
    }

}