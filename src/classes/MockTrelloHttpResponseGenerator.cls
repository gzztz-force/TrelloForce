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
                                '"memberships":[{"id":"545735a69a0da4e4721950fe","idMember":"5456e0a4463c0074fcfa6e17",}]},' + 
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
            res.setBody('[{"id":"545ae566569a88c456889a3d","name":"Checklist","idBoard":"5456dd656a8668e557b82685","idCard":"545ae5597bc18d2c4f3abd1c","pos":16384,"checkItems":[{"state":"complete","id":"545ae59de861da11ad8e51a2","name":"Draw a ERD in Lucidchart","nameData":null,"pos":16737},{"state":"complete","id":"545ae5cbff7e74b6c56a6463","name":"Call with Trello API with token in Apex to get cards for one board@jairzheng ","nameData":{"emoji":{}},"pos":33451}]},{"id":"5456dec0d4cdae25e6f899bd","name":"Tasks","idBoard":"5456dd656a8668e557b82685","idCard":"5456de544dd69d13e61d3eb2","pos":16384,"checkItems":[{"state":"complete","id":"5456deedc834ad98e6592c9d","name":"How to access API with user token","nameData":null,"pos":17385}]},{"id":"545b9941a08a1fc76f4ff21c","name":"Code apex to call API","idBoard":"5456dd656a8668e557b82685","idCard":"545b991c45a1ecb44ea0978a","pos":16384,"checkItems":[{"state":"complete","id":"545b996f900754fac25a6283","name":"Create method and class to analysis JSON","nameData":null,"pos":17273},{"state":"complete","id":"545b99c1ca6eda41590d62b0","name":"Call APIs which match PM Objects","nameData":null,"pos":34465}]},{"id":"546052d96f128fb6393bc81e","name":"Insert","idBoard":"5456dd656a8668e557b82685","idCard":"54601ea8c3b55e32bafa35ab","pos":16384,"checkItems":[{"state":"complete","id":"546052df1a5a88d0cf22ca11","name":"Boards","nameData":null,"pos":17263},{"state":"complete","id":"546052eab9d0522b59ec29d8","name":"Cards","nameData":null,"pos":34570},{"state":"complete","id":"546052f77d4689dccf50eb71","name":"CheckListItems","nameData":null,"pos":51670},{"state":"incomplete","id":"546168e5c11633260ab38cac","name":"Match User","nameData":null,"pos":68191}]},{"id":"546477bf744f9b2b0aff8a0f","name":"schedule","idBoard":"5456dd656a8668e557b82685","idCard":"545c709150ce1f750c04b60a","pos":16384,"checkItems":[{"state":"complete","id":"546477d63198d40b2134c8d4","name":"Run every 15 minutes","nameData":null,"pos":16556}]}]');
        }
        else if(req.getEndpoint().contains('https://api.trello.com/1/boards/5456dd656a8668e557b82685/members'))
        {
            res.setBody('[{"id":"5456e599eb84e75b41283de8","fullName":"Evan Zhong","username":"evanzhong"},{"id":"50ad61a65a55ffe60e00830e","fullName":"Jair Zheng","username":"jairzheng"},{"id":"5456e0a4463c0074fcfa6e17","fullName":"Vicky Zhang","username":"vickyzhang3"}]');
        }
        else 
        {
            res.setBody('');
        }
        
        res.setStatusCode(200);
        return res;
    }

}