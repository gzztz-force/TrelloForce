global class TrelloBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {

    String query = 'select Id, Name from MProject__c';

    global TrelloBatch() {

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        TrelloFactory trello = new TrelloFactory();
        trello.insertBoards();
    }

    global void finish(Database.BatchableContext BC) {
        Database.executeBatch(new TrelloCardBatch());
    }

}