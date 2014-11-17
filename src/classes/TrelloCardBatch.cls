global class TrelloCardBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {

    String query = 'select Id, TrelloBoardId__c from MProject__c where TrelloBoardId__c != null';

    global TrelloCardBatch() {

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<MProject__c> scope) {
        TrelloFactory trello = new TrelloFactory();
        trello.upsertCard(scope);

    }

    global void finish(Database.BatchableContext BC) {
        TrelloFactory trello = new TrelloFactory();
        trello.upsertItem();
    }

}