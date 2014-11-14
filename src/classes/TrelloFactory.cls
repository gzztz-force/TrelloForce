/*
 * The class to get info from Trello and insert to pm.
 */
public with sharing class TrelloFactory
{
    public static MProject__c project;
    public static Change__c change;
    public static ChangeTask__c changeTask;
    public static List<Change__c> changes;
    public static List<ChangeTask__c> changeTasks;
    public static List<TrelloCard> cards;
    public static List<TrelloCheckList> checkLists;

    public TrelloFactory(){}

    public static String Token
    {
        get
        {
           String vToken = TrelloDetail__c.getInstance('Vicky Zhang').Trello_Token__c;
           return vToken;
        }
        set;
    }
    public static String Key
    {
        get
        {
            String vKey = TrelloDetail__c.getInstance('Vicky Zhang').Trello_Key__c;
            return vKey;
        }
        set;
    }
    public static String BoardId
    {
        get
        {
            String id = 'IxV8b29C';
            return id;
        }
        set;
    }
    public static TrelloBoard Board { get; set; }
    public static String CardId { get; set; }

    public static void getTrelloBoardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'?fields=name,desc&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        Board = (TrelloBoard)JSON.deserialize(response.getBody(), TrelloBoard.class);
    }

    public static void getTrelloCardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'/cards?fields=name,closed,desc,idBoard,idList,due,idMembers&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        cards = (List<TrelloCard>)JSON.deserialize(response.getBody(), List<TrelloCard>.class);

    }

    public static void getTrelloCheckListInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'/checklists?fields=id,name,idCard&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        CheckLists = (List<TrelloCheckList>)JSON.deserialize(response.getBody(), List<TrelloCheckList>.class);

    }

//***** Methods Start *****//
    public static void insertBoard()
    {
        //Board = getTrelloBoardInfo();
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

    public static void insertCards()
    {
        List<Change__c> upsertChanges = new List<Change__c>();
        //cards = getTrelloCardInfo();
        //System.debug(BoardId+'Key'+Key+Token);
        project = [select Id from MProject__c where TrelloBoardId__c = :BoardId];
        System.debug(cards.size());

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

    }

    public static void insertItems()
    {
        List<ChangeTask__c> upsertTasks = new List<ChangeTask__c>();
        Set<String> cardIdSet = new Set<String>();
        Map<String, String> cardIdToChangeIdMap = new Map<String, String>();
        for(TrelloCheckList checklist : CheckLists)
        {
            cardIdSet.add(checklist.IdCard);
        }
        for(Change__c changeWithCard : [select Id, TrelloCardId__c from Change__c where TrelloCardId__c in :cardIdSet])
        {
            cardIdToChangeIdMap.put(changeWithCard.TrelloCardId__c, changeWithCard.Id);
        }
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
        upsert upsertTasks TrelloItemId__c;
    }

    @future(callout = 'true')
    public static void upsertTrello()
    {
        getTrelloCardInfo();
        getTrelloCheckListInfo();
        insertCards();
        insertItems();

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