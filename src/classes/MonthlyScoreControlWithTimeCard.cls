/*
 * this Schedule used to control score with timecard every month
 */
global class MonthlyScoreControlWithTimeCard implements Database.Batchable<SObject>, Schedulable
{
    private final Map<Integer, Integer> workDaysOf2014 = new Map<Integer, Integer>{ 1 => 20, 2 => 17, 3 => 21, 4 => 21, 5 => 21, 6 => 20, 7 => 23, 8 => 21, 9 => 22, 10 => 19, 11 => 20, 12 => 23 };

    global   Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([select Id, Name from User]);
    }

    //execute method for batch
    global void execute(Database.BatchableContext BC, List<User> users)
    {
        Date dateNow = Date.today();
        Integer yearNow = dateNow.year();
        Integer lastMonth = dateNow.month()-1;
        Integer daysLastMonth = workDaysOf2014.get(lastMonth);

        Set<Id> userIds = new Set<Id>();

        for(User u : users)
        {
            userIds.add(u.Id);
        }

        //date for sql to select TimeCard where between startDay and endDay
        Date startDay = Date.newInstance(yearNow, lastMonth, 1);
        Date endDay = Date.newInstance(yearNow, lastMonth, daysLastMonth);
        //String startDay = yearNow + '-' + lastMonth + '-01';
        //String endDay = yearNow + '-' + lastMonth + '-' + daysLastMonth;

        //all TimeCards this month
        AggregateResult[] timeCards = [select TeamMember__r.User__r.Id, sum(hours__c) from TimeCard__c where (IsLogatSameDay__c = true) and (Date__c >= :startDay and Date__c <= :endDay) group by TeamMember__r.User__r.Id, Date__c order by Date__c desc];
        List<Score__c> scores = [select User__r.Id, Worth__c, Id from Score__c];

        Map<Id, Integer> allTimeCards = new Map<Id, Integer>();
        Map<Id, Id> allScores = new Map<Id, Id>();

        //keep the userId as key and his/her count of days has timecard this month as value on the map
        for(AggregateResult ar: timeCards)
        {
            if(Integer.valueOf(ar.get('expr0')) >= 6)
            {
                String userIdStr = String.valueOf(ar.get('TeamMember__r.User__r.Id'));
                Id userId = Id.valueOf(userIdStr);
                Integer TimeCardNumber;
                if(allTimeCards.get(userId) == null)
                {
                   TimeCardNumber = 1;
                }
                else
                {
                    TimeCardNumber = allTimeCards.get(userId);
                    TimeCardNumber += 1;
                }
                allTimeCards.put(userId,TimeCardNumber);
            }
        }

        //It is wordy here....
        //keep the userId as key and his/her scoreId  as value on the map
        for(Score__c s : scores)
        {
            allScores.put(s.User__r.Id, s.Id);
        }

        //if timecard meet the condition ,then add his/her score
        Set<Id> uIds = allTimeCards.keySet();
        for(Id i : uIds)
        {
            Integer tmNumber = allTimeCards.get(i);
            if(tmNumber >= daysLastMonth)
            {
                Id scoreId = allScores.get(i);
                if(scoreId  == null)
                {
                    //how to deal with it, um......
                }
                else
                {
                    SubScore__c addScore = new SubScore__c();
                    addScore.Score__c = scoreId;
                    addScore.worth__c = 0.3;
                    addScore.Description__c = 'TimeCard encourage for ' + yearNow + '.' + (lastMonth) ;
                    insert addScore;
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC)
    {
    }

    //execute method for schedule
    global void execute(SchedulableContext SC)
    {
        MonthlyScoreControlWithTimeCard batch = new MonthlyScoreControlWithTimeCard();
        Database.executeBatch(batch, 1);
    }
}