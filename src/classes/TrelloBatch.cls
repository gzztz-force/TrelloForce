global class TrelloBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {

    String query = 'select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c != null';
    TrelloConnectUtil trello;

    global TrelloBatch() {
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        trello = new TrelloConnectUtil(scope);
        trello.upsertChange();
    }

    global void finish(Database.BatchableContext BC) {
        Database.executeBatch(new TrelloChangeTaskBatch());
    }

}