global class TrelloChangeTaskBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	
	String query = 'select Id, Name, TrelloBoardId__c from MProject__c where TrelloBoardId__c != null';
    TrelloFactory trello;
	
	global TrelloChangeTaskBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		trello = new TrelloFactory(scope);
        trello.upsertChangeTask();
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}