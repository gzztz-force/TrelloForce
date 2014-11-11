/*
 * The controller of TrelloToConnect
 */
public with sharing class TrelloToConnectController
{

    public TrelloToConnectController()
    {
        Key = 'cca16a310f7a1fff02de787a901640da';
    }

    public String Key { get; set; }
    public String Token { get; set; }

    public String getUserName()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://trello.com/1/members/me?key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response =(new Http()).send(request);
        TrelloMember member = (TrelloMember)JSON.deserialize(response.getBody(), TrelloMember.class);
        return member.FullName;
    }

    public void saveToken()
    {
        String fullName = getUserName();
        System.debug(fullName);
        List<TrelloDetail__c> trelloList = [select Name, Trello_Token__c from TrelloDetail__c where Name = :fullName];
        if(trelloList.size() == 0){
            TrelloDetail__c trello = new TrelloDetail__c();
            trello.Name = fullName;
            trello.Trello_Token__c = Token;
            trello.Trello_Key__c = Key;
            insert trello;
        }
    }

    public class TrelloMember
    {
        public String Id { get; set; }
        public String FullName { get; set; }
    }
}