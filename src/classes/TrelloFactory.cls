public with sharing class TrelloFactory
{
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
    public TrelloCards Card { get; set; }
    public List<TrelloCheckLists> CheckLists { get; set; }

    public TrelloBoard getTrelloBoardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'?fields=name,desc&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        Board = (TrelloBoard)JSON.deserialize(response.getBody(), TrelloBoard.class);
        return Board;
    }

    public class TrelloBoard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String Description { get; set; }

    }

    public TrelloCards getTrelloCardsInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ BoardId +'/cards?fields=name,closed,desc,idBoard,idList,due,idMembers&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        Card = (TrelloCards)JSON.deserialize(response.getBody(), TrelloCards.class);
        return Card;
    }

    public class TrelloCards
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

     public List<TrelloCheckLists> getTrelloCheckListInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/cards/'+ CardId +'/checklists?fields=name&checkItem_fields=name,state&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        CheckLists = (List<TrelloCheckLists>)JSON.deserialize(response.getBody(), List<TrelloCheckLists>.class);
        return CheckLists;
    }

    public class TrelloCheckLists

    {
        public String Id { get; set; }
        public String Name { get; set; }
        public List<CheckItems> CheckItems { get; set; }
    }

    public class CheckItems
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String Status { get; set; }

    }










}