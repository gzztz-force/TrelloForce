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
        String vToken = TrelloDetail__c.getInstance('Vicky Zhang').Trello_Token__c;
        String vKey = TrelloDetail__c.getInstance('Vicky Zhang').Trello_Key__c;
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

    public TrelloBoard getTrelloBoardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'?fields=name,desc&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return (TrelloBoard)JSON.deserialize(response.getBody(), TrelloBoard.class);
    }

    public void getTrelloCardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'/cards?fields=name,closed,desc,idBoard,idList,due,idMembers&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        cards = (List<TrelloCard>)JSON.deserialize(response.getBody(), List<TrelloCard>.class);
    }

    public void getTrelloCheckListInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'/checklists?fields=id,name,idCard&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        CheckLists = (List<TrelloCheckList>)JSON.deserialize(response.getBody(), List<TrelloCheckList>.class);

    }

//***** Methods Start *****//
    public void insertBoard()
    {
        Board = getTrelloBoardInfo();
        project = new MProject__c();
        project.name = Board.name;
        if(Board.Closed = true)
        {
            project.Status__c = 'Closed';
        }
        else
            project.Status__c = 'In Progress';
        project.TrelloBoardId__c = Board.Id;
        upsert project TrelloBoardId__c;
    }

    public void insertCards()
    {
        List<Change__c> upsertChanges = new List<Change__c>();
        //cards = getTrelloCardInfo();
        project = [select Id from MProject__c where TrelloBoardId__c = :BoardId];
        for(TrelloCard card : cards)
        {
            Change__c c = new Change__c();
            c.Name = card.Name;
            c.TrelloCardId__c = card.Id;
            c.DueDate__c = card.Due;
            c.Description__c = card.Description;
            c.Project__c = project.Id;
            upsertChanges.add(c);
        }
        upsert upsertChanges TrelloCardId__c;
        System.debug(upsertChanges.size());

    }

    public void insertItems()
    {
        List<ChangeTask__c> upsertTasks = new List<ChangeTask__c>();
        //CheckLists = getTrelloCheckListInfo();
        Set<String> cardIdSet = new Set<String>();
        Map<String, String> cardIdToChangeIdMap = new Map<String, String>();
        for(TrelloCheckList checklist : CheckLists)
        {
            cardIdSet.add(checklist.IdCard);
        }
        for(Change__c change : [select Id, TrelloCardId__c from Change__c where TrelloCardId__c in :cardIdSet])
        {
            cardIdToChangeIdMap.put(change.TrelloCardId__c, change.Id);
        }
        System.debug(cardIdToChangeIdMap.size());

        for(TrelloCheckList checklist : CheckLists)
        {
            String changeId = cardIdToChangeIdMap.get(checklist.IdCard);
            if(changeId != null){
                List<TrelloCheckItem> ChecklistItems = checklist.CheckItems;
                System.debug(changeId+'--'+checklist.IdCard);
                for(TrelloCheckItem item : ChecklistItems)
                {
                    ChangeTask__c task = new ChangeTask__c();
                    task.Name = item.Name;
                    task.TrelloItemId__c = item.Id;
                    System.debug(task.TrelloItemId__c);
                    task.Change__c = changeId;
                    if(item.State == 'incomplete')
                    {
                        task.Status__c = 'In Progress';
                    }
                    else
                        task.Status__c = 'Done';
                    upsertTasks.add(task);
                }
            }

        }
        System.debug(upsertTasks.size());
        upsert upsertTasks TrelloItemId__c;
    }

//***** Methods End *****//


//***** Inner Class Start *****//
    public class TrelloBoard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String Description { get; set; }
        public Boolean Closed { get; set; }
    }

     public class TrelloCard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public Boolean Closed { get; set; }
        public String Description { get; set; }
        public String IdBoard { get; set; }
        public String IdList { get; set; }
        public Date Due { get; set; }
        public String[] IdMembers { get; set; }
        public Integer Flag{ get; set; }

    }

    public class TrelloCheckList
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String IdCard { get; set; }
        public List<TrelloCheckItem> CheckItems { get; set; }
    }

    public class TrelloCheckItem
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String State { get; set; }
    }
    //***** Inner Class End *****//


}