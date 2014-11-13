global class TrelloFactoryScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        TrelloFactory factory = new TrelloFactory();
        factory.getTrelloCardInfo();
        factory.getTrelloCheckListInfo();
        factory.insertBoard();
        factory.insertCards();
        factory.insertItems();
    }
}