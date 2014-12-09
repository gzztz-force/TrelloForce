public with sharing class TrelloBoardConnectionController
{
    private PageReference returnPage;
    private String key;
    private TrelloAPI trelloData;
    private List<MProject__c> syncProjects;
    private TrelloConnectUtil trelloConnectUtil;
    private String nullBoardName;
    private ApexPages.StandardController ctrl;      

    public TrelloBoardConnectionController(ApexPages.StandardController ctrl)
    {
        this.ctrl = ctrl;
        prj = (MProject__c)ctrl.getRecord();
        trelloConnectUtil = new TrelloConnectUtil();
        syncProjects = new List<MProject__c>();
        returnPage = ApexPages.currentPage();
        nullBoardName = 'Disconnect Board';
        if(String.isBlank(prj.TrelloBoardId__c))
        {
            IsSychronized = false; 
        }
        else
        {
            IsSychronized = true;
        }
        BoardId = prj.TrelloBoardId__c;
        Key = TrelloConfig__c.getInstance().Key__c;
        Authlink = 'https://trello.com/1/authorize?response_type=token&key=' + Key + '&return_url=' + Url.getSalesforceBaseUrl().toExternalForm() + returnPage.getUrl().remove('core.apexpages.devmode.url=1&' ) + '&sfdc&name=TrelloWithPM&callback_method=fragment&scope=read%2Cwrite&expiration=never';
        if(IsAuthed)
        {
            Token = TrelloUser__c.getInstance(UserInfo.getUserId()).Token__c;
        }
        trelloData = new TrelloAPI(Key, Token);
        Boards = new List<Board>();
    }

    public Boolean IsAuthed
    {
        get
        {
            if (TrelloUser__c.getInstance(UserInfo.getUserId()) != null)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }

    public MProject__c prj { get; set;}
    public String AuthLink { get; set;}
    public String Token { get; set; }
    public String BoardId { set; get; }
    public String SelectedName { get; set; }
    public Boolean IsSychronized { get; set; }

    public List<Board> Boards
    {
        get
        {   
            if(Boards.size() == 0 && Token != null)
            {
                if(String.isBlank(prj.TrelloBoardId__c))
                {
                    Boards.add(new Board('', nullBoardName, true));
                    for(TrelloModel.Board b : trelloData.getBoardInfo())
                    {
                        Boards.add(new Board(b.Id, b.name, false));
                    }
                }
                else
                {
                    Boards.add(new Board('', nullBoardName, false));
                    for(TrelloModel.Board b : trelloData.getBoardInfo())
                    {   
                        if(b.Id != prj.TrelloBoardId__c)
                        {
                            Boards.add(new Board(b.Id, b.Name, false));
                        }
                        else
                        {
                            Boards.add(new Board(b.Id, b.Name, true));
                        }
                    }
                }
            }
            return Boards; 
        }
        set;      
    }

    public void connectBoard()
    {   
        try
        {   
            if(prj.TrelloBoardId__c != BoardId)
            {
                prj.TrelloBoardId__c = BoardId;
                update prj;
                if(String.isBlank(BoardId))
                {
                    addMsgNotConnected();
                    trelloConnectUtil.deleteWithoutBoardId(prj); 
                }
                else
                {
                    addMsgConnected();
                }
            }
            else if(String.isBlank(BoardId))
            {
                addMsgNotConnected();
            }
            else 
            {
                addMsgConnected();
            }
        }
        catch(DmlException ex)
        {
            ApexPages.addMessages(ex);
        } 
        reSelect();
    }

    public void addMsgConnected()
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Connect Successfully. You can synchronize your data now.'));
        IsSychronized = true; 
    }

    public void addMsgNotConnected()
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have not connneted any Board now'));
        IsSychronized = false;
    }

    public void addMsgStartSync()
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Synchronization has been started, you can refresh the project page to check trello data a few minutes'));
    }

    public void editToken()
    {
        Token = TrelloUser__c.getInstance(UserInfo.getUserId()).Token__c;
    }

    public void saveToken()
    {
        TrelloUser__c trlloToken = new TrelloUser__c();
        trlloToken.Token__c = Token;
        trlloToken.Name = UserInfo.getUserId();
        try
        {
            upsert trlloToken Name;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessages(ex);
        }
        Token = null;
    }

    public void syncChanges()
    {   
        prj.TrelloBoardId__c = BoardId;
        syncProjects.add(prj);
        trelloConnectUtil = new TrelloConnectUtil(syncProjects);
        try
        {
            trelloConnectUtil.upsertChange();
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
    }

    public void syncChangeTasks()
    {
        try
        {
            prj.TrelloBoardId__c = BoardId;
            syncProjects = new List<MProject__c>();
            syncProjects.add(prj);
            trelloConnectUtil = new TrelloConnectUtil(syncProjects);
            trelloConnectUtil.upsertChangeTask();
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        reSelect();
    }

    public void reSelect()
    {
        for(Board b : Boards)
        {
            if(b.Id == BoardId)
            {
                b.IsSelected = true;
                if(String.isBlank(BoardId))
                {
                    IsSychronized = false;
                }
            }
            else b.IsSelected = false;
        }    
    }

    public class Board
    {
        public Board(String boardId, String boardName, Boolean isSelected)
        {
            this.Id = boardId;
            this.Name = boardName;
            this.IsSelected = isSelected;      
        }
        public String Id { get; set;}
        public String Name { get; set; }
        public Boolean IsSelected { get; set; }
    }
}