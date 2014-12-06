public with sharing class ConnectBoardController
{

    
    private PageReference returnPage;
    private String key;
    private TrelloAPI trelloData;
    private List<MProject__c> syncProjects;
    private TrelloFactory factory;

    public ConnectBoardController(ApexPages.StandardController ctrl)
    {
        
        prj = (MProject__c)ctrl.getRecord();
        syncProjects = new List<MProject__c>();
        returnPage = ApexPages.currentPage();
        if(String.isBlank(prj.TrelloBoardId__c))
        {
            IsSychronized = false; 
        }
        else
        {
            IsSychronized = true;
        }
        BoardId = prj.TrelloBoardId__c;
        Key = 'cca16a310f7a1fff02de787a901640da';
        Authlink = 'https://trello.com/1/authorize?response_type=token&key='+Key+'&return_url='+Url.getSalesforceBaseUrl().toExternalForm()+returnPage.getUrl().remove('core.apexpages.devmode.url=1&' )+'&sfdc&name=TrelloWithPM&callback_method=fragment&scope=read%2Cwrite&expiration=never';
        if(IsAuthed)
        {
            Token = TrelloDetail__c.getInstance(UserInfo.getUserId()).Trello_Token__c;
        }
        System.debug('username='+UserInfo.getUserId());
        trelloData = new TrelloAPI(Key, Token);
        showBoards = new List<showBoard>();
       
    }

    public Boolean IsAuthed
    {
        get
        {
            if (TrelloDetail__c.getInstance(UserInfo.getUserId()) != null)
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

    public MProject__c prj { get; set;}
    public String AuthLink { get{ return Authlink; } set;}
    public String Token { get; set; }
    public String BoardId { set; get; }
    public String SelectedName { get; set; }
    public Boolean IsSychronized { get; set; }

    public List<showBoard> showBoards
    {
        get
        {   
            System.debug('get showBoards'+showBoards);
            //List<TrelloModel.Board> boardInfoList = trelloData.getBoardInfo();
            if(showBoards.size() == 0 && Token != null)
            {
                System.debug('showBoards start:'+showBoards.size());
                if(prj.TrelloBoardId__c != null)
                {
                    System.debug('connected and ');
                    //ShowBoard addBoard = new ShowBoard(false);
                    //addBoard.name = 'aa';
                    //System.debug('addboardId:'+addBoard.Id);
                    showBoards.add(new ShowBoard(false));
                    for(TrelloModel.Board b : trelloData.getBoardInfo())
                    {   
                        System.debug('start for loop');
                        if(b.Id != prj.TrelloBoardId__c)
                        {
                            showBoards.add(new ShowBoard(b.Id,b.Name));
                            System.debug('    bid:'+b.Id);
                        }
                        else
                        {
                            showBoards.add(new ShowBoard(b.Id,b.Name,true));
                            System.debug('Select this option'+'bid:'+b.Id);


                        }
                    }
                    
                }
                else
                {
                    System.debug('no connect');
                    showBoards.add(new showBoard(true));
                    for(TrelloModel.Board b : trelloData.getBoardInfo())
                    {
                        showBoards.add(new showBoard(b.Id,b.name));
                    }

                }
                
            }
            System.debug('showBoardsSize:'+showBoards.size());
            return showBoards; 
        }
        set;
               
    }


    //public List<TrelloModel.Board> Boards
    //{
    //    get
    //    {
    //        System.debug('test');
    //        if(Boards == null && Token != null)
    //        {
    //            Boards = trelloData.getBoardInfo();
    //        }
    //        return Boards;
    //    }
    //    set;
    //}



    public void connectBoard()
    {   
        try
        {   
            if(prj.TrelloBoardId__c != BoardId)
            {
                prj.TrelloBoardId__c = BoardId;
                update prj;
                System.debug('connect success');
                if(String.isBlank(BoardId))
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'You have not connneted any Board now'));
                    IsSychronized = false;
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Connect Successfully. You can synchronize your data now.'));
                    IsSychronized = true; 
                }
            }
            else if(String.isBlank(BoardId))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'You have not connneted any Board now'));
                IsSychronized = false;
            }
            else 
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Connect Successfully. You can synchronize your data now.'));
                IsSychronized = true; 
            }
        }
        catch(DmlException ex)
        {
            ApexPages.addMessages(ex);
        } 

        System.debug('aaaBoardId:'+BoardId);
        
        factory = new TrelloFactory();
        factory.deleteWithoutBoardId(prj); 

    }

    public void editToken()
    {
        System.debug('setToken');
        Token = TrelloDetail__c.getInstance(UserInfo.getUserId()).Trello_Token__c;
        System.debug('Token:'+Token);
    }

    public PageReference showInfo()
    {
        return null;
    }

    public void saveToken()
    {
        TrelloDetail__c trelloInfo = new TrelloDetail__c();
        trelloInfo.Trello_Token__c = Token;
        System.debug('Token='+Token);
        trelloInfo.Trello_Key__c = Key;
        trelloInfo.Name = UserInfo.getUserId();
        try
        {
            upsert trelloInfo Name;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessages(ex);
        }
        Token = null;
        System.debug('upsert done');
    }

    //public String getUserName()
    //{
    //    HttpRequest request = new HttpRequest();
    //    request.setEndpoint('https://trello.com/1/members/me?key='+ Key +'&token='+ Token);
    //    request.setMethod('GET');
    //    HttpResponse response =(new Http()).send(request);
    //    TrelloMember member = (TrelloMember)JSON.deserialize(response.getBody(), TrelloMember.class);
    //    return member.FullName;
    //}

    //public class TrelloMember
    //{
    //    public String Id { get; set; }
    //    public String FullName { get; set; }
    //}

    public void syncChanges()
    {
        syncProjects.add(prj);
        factory = new TrelloFactory(syncProjects);
        factory.upsertChange();
    }
    public void syncChangeTasks()
    {
        System.debug('synctask');
        factory.upsertChangeTask();
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Synchronize succeeded'));

    }

    public class showBoard
    {
        public showBoard(String bid,String bname)
        {
            this.Id = bid;
            this.Name = bname;
            this.Checked = false;
        }
       
        public showBoard(Boolean isChecked)
        {
            this.Id = null;
            this.Name = 'None Selected';
            this.Checked = isChecked;
        }
        public showBoard(String bid,String bname,Boolean isChecked)
        {
            this.Id = bid;
            this.Name = bname;
            this.Checked = isChecked; 
        }
        public String Id { get; set;}
        public String Name { get; set; }
        public Boolean Checked { get; set; }
    }


}