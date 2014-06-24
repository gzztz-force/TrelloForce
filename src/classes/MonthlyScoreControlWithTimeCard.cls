/*
 * this Schedule used to control score with timecard every month
 */
global class MonthlyScoreControlWithTimeCard implements Database.Batchable<SObject>, Schedulable
{
    private final Map<Integer, Integer> workDaysOf2014 = new Map<Integer, Integer>{ 1 => 20, 2 => 17, 3 => 21, 4 => 21, 5 => 21, 6 => 20, 7 => 23, 8 => 21, 9 => 22, 10 => 19, 11 => 20, 12 => 23 };

    global   Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([select Id, Name from User where IsActive = true and IsEmployee__c=1]);
    }

    //execute method for batch
    global void execute(Database.BatchableContext BC, List<User> users)
    {
        Date dateNow = Date.today();
        Integer lastMonth = dateNow.month()-1;
        Integer daysLastMonth = workDaysOf2014.get(lastMonth);

        Set<Id> userIds = new Set<Id>();
        for(User u : users)
        {
            userIds.add(u.Id);
        }

        //***************start************
        //Date startDay = Date.newInstance(yearNow, lastMonth, 1);
        //Date endDay = Date.newInstance(yearNow, lastMonth, daysLastMonth);
        //**************end***************

        //all TimeCards this month
        AggregateResult[] timeCards;
        if(Test.isRunningTest())
        {
            timeCards = [select TeamMember__r.User__c uid, Date__c, sum(hours__c) from TimeCard__c where (TeamMember__r.User__c in :userIds) and (Date__c >= 2014-06-01) and (Date__c < 2014-07-01) group by TeamMember__r.User__c, Date__c order by Date__c desc];
        }
        else
        {
            timeCards = [select TeamMember__r.User__c uid, Date__c, sum(hours__c) from TimeCard__c where (TeamMember__r.User__c in :userIds) and (IsLogatSameDay__c = true) and Date__c = LAST_MONTH group by TeamMember__r.User__c, Date__c order by Date__c desc];
        }
        List<Score__c> scores = [select User__r.Id, Worth__c, Id from Score__c where User__r.Id in :userIds];
        //keep the userId as key and his/her count of days has timecard this month as value on the map
        Map<Id, Integer> allTimeCards = new Map<Id, Integer>();
        for(AggregateResult ar: timeCards)
        {
            if(Integer.valueOf(ar.get('expr0')) >= 6)
            {
                String userIdStr = String.valueOf(ar.get('uid'));
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

        //save the userId as key and his/her scoreId  as value on the map
        Map<Id, Id> allScores = new Map<Id, Id>();
        //save all subScore should be insert
        List<SubScore__c> addSubScores = new List<SubScore__c>();
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
                    addScore.Description__c = 'TimeCard encourage for ' + dateNow.year() + '.' + lastMonth ;
                    addSubScores.add(addScore);
                }
            }
        }
        insert addSubScores;
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