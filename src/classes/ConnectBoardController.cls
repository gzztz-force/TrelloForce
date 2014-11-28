public with sharing class ConnectBoardController {

    public TrelloFactory trelloData;
    private MProject__c prj;
    private String link;
    private PageReference returnPage;
    private String key;



    public ConnectBoardController(ApexPages.StandardController ctrl)
    {
        prj = (MProject__c)ctrl.getRecord();
        trelloData = new TrelloFactory();
        returnPage = ApexPages.currentPage();
        Key = 'cca16a310f7a1fff02de787a901640da';
        link = 'https://trello.com/1/authorize?response_type=token&key=cca16a310f7a1fff02de787a901640da&return_url='+Url.getSalesforceBaseUrl().toExternalForm()+returnPage.getUrl().remove('core.apexpages.devmode.url=1&' )+'&sfdc&name=TrelloWithPM&callback_method=fragment&scope=read%2Cwrite&expiration=never';
        if(IsAuthed)
        {
            Token = TrelloDetail__c.getInstance(UserInfo.getUserId()).Trello_Token__c;
        }
        System.debug('username='+UserInfo.getUserId());
    }

    public void connectBoard()
    {
        String projectId = prj.Id;
        MProject__c project = [select Id,TrelloBoardId__c from MProject__c where Id = :projectId limit 1];
        project.TrelloBoardId__c = BoardId;
        update project;
        System.debug('connect success');
    }

    //public void assignToBoards()
    //{
    //    if(Token != null)
    //        {
    //            Boards = trelloData.getTrelloBoardInfo(key,Token);
    //        }

    //}

    public void saveToken()
    {
        TrelloDetail__c trelloInfo = new TrelloDetail__c();
        trelloInfo.Trello_Token__c = Token;
        System.debug('Token='+Token);
        trelloInfo.Trello_Key__c = 'cca16a310f7a1fff02de787a901640da';
        trelloInfo.Name = UserInfo.getUserId();
        upsert trelloInfo Name;
        System.debug('upsert done');
    }

       public String getUserName()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://trello.com/1/members/me?key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        TrelloMember member = (TrelloMember)JSON.deserialize(response.getBody(), TrelloMember.class);
        return member.FullName;
    }

    public Boolean IsAuthed
    {
        get
        {
           if (TrelloDetail__c.getInstance(UserInfo.getUserId()).Trello_Token__c != null)
           {
                System.debug('true');
                return true;
           }
           else
            {
                System.debug('false');
                return false;
            }
        }
    }

    public String authLink{ get{ return link; } set;}
    public String Token{ get; set; }
    public String BoardId{ set; get; }
    public List<TrelloModel.TrelloBoard> Boards
    {
        get
        {
            if(Token != null)
            {
                return trelloData.getTrelloBoardInfo(key,Token);
            }
            else return false;
        }
        set;
    }

     public class TrelloMember
    {
        public String Id { get; set; }
        public String FullName { get; set; }
    }


}