public with sharing class TrelloFactory
{
    public MProject__c project;
    public Change__c change;
    public ChangeTask__c changeTask;
    public List<Change__c> changes;
    public List<ChangeTask__c> changeTasks;
    public List<TrelloCard> cards;
    public List<TrelloCheckList> checkLists;



    public TrelloFactory()
    {
        String vToken = TrelloDetail__c.getInstance('vicky').Trello_Token__c;
        String vKey = TrelloDetail__c.getInstance('vicky').Trello_Key__c;
        if(vToken != null && vKey != null)
        {
            Token = vToken;
            Key = vKey;
        }
        BoardId = 'IxV8b29C';
    }

    public String Key { get; set; }
    public String Token { get; set; }
    public String BoardId { get; set; }
    public TrelloBoard Board { get; set; }
    public String CardId { get; set; }


    //public List<TrelloCheckItem> Items { get; set; }


    public TrelloBoard getTrelloBoardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'?fields=name,desc&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        return (TrelloBoard)JSON.deserialize(response.getBody(), TrelloBoard.class);
    }

    public List<TrelloCard> getTrelloCardInfo(String TrelloBoardId)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ TrelloBoardId +'/cards?fields=name,closed,desc,idBoard,idList,due,idMembers&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        return (TrelloCard)JSON.deserialize(response.getBody(), List<TrelloCard>.class);
    }

     public List<TrelloCheckList> getTrelloCheckListInfo(String TrelloCardId)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/cards/'+ TrelloCardId +'/checklists?fields=name&checkItem_fields=name,state&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        return (List<TrelloCheckList>)JSON.deserialize(response.getBody(), List<TrelloCheckList>.class);
    }

//***** Methods Start *****//
    public void insertBoard()
    {
        Board = getTrelloBoardInfo();
        project = new MProject__c();
        project.name = Board.name;
        project.IsClosed__c = Board.closed;
        project.TrelloBoardId = Board.Id;
        insert project;
    }

    public void insertCards()
    {
        changes.clear();
        cards = getTrelloCardInfo(BoardId);
        project = [select Id from Project where TrelloBoardId = :BoardId];
        for(TrelloCard card : cards)
        {
            change = new Change__c();
            change.name = card.name;
            change.TrelloCardId__c = card.Id;
            if(card.Closed == 1)
            {
                change.IsClosed__c = true;
            }
            else change.IsClosed__c = false;
            change.DueDate__c = card.Due;
            change.Description__c = card.Description;
            change.TrelloCardId__c = card.Id;
            change.Project__c = project.Id;
            change.AssignedTo__c = //matchUser()
            changes.add(change);
        }
        insert changes;
    }

    public void insertAllItems(String TrelloUserName)
    {
        changeTasks.clear();
        for(TrelloCard card : cards)
        {
            String changId = ][select Id from Change where TrelloCardId = :card.Id];
            CheckLists = getTrelloCheckListInfo(card.Id);//use batch maybe
            for(TrelloCheckList checklist : CheckLists)
            {
                List<TrelloCheckItem> ChecklistItems = new List<TrelloCheckItem>(checklist.TrelloCheckItem);
                for(TrelloCheckItem item : ChecklistItems)
                {
                    changeTask = new ChangeTask__c();
                    changeTask.name = item.Name;
                    changeTask.Status__c = item.Status;
                    changeTask.TrelloItemId = item.Id;
                    changeTask.AssignedTo__c //matchUser();
                    changeTask.Change__c = changId;
                    changeTasks.add(changeTask);
                }
            }
        }
        insert changeTasks;
    }

    public matchUser(String[] ){
        for()
    }
//***** Methods End *****//


//***** Inner Class Start *****//
    public class TrelloBoard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String Description { get; set; }
    }

     public class TrelloCard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public Boolean Closed { get; set; }
        public String Description { get; set; }
        public String IdBoard { get; set; }
        public String IdList { get; set; }
        public String Due { get; set; }
        public String[] IdMembers { get; set; }
    }

    public class TrelloCheckList
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public List<TrelloCheckItem> TrelloCheckItems { get; set; }
    }

    public class TrelloCheckItem
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String Status { get; set; }
    }
    //***** Inner Class End *****//


}