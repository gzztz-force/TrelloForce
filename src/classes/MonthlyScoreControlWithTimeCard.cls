/*
 * this Schedule used to control Credit with timecard every month, which should execute every month's first day in 2014.
 */
global class MonthlyScoreControlWithTimeCard implements Database.Batchable<SObject>, Schedulable
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([select Id, Name, Email from User where IsActive = true and IsEmployee__c = 1]);
    }

    //execute method for batch
    global void execute(Database.BatchableContext BC, List<User> users)
    {
        Date lastMonth = Date.today().addMonths(-1);
        Integer year = lastMonth.year();
        Integer month = lastMonth.month();
        Integer workday = Integer.valueOf(WorkDays__c.getValues(year + '-' + month));
        
        Set<String> userEmails = new Set<String>();
        Set<Id> userIds = new Set<Id>();
        Map<String, String> allUser = new Map<String, String>();
        for(User user : users)
        {
            userEmails.add(user.Email);
            userIds.add(user.Id);
            allUser.put(user.Email, user.Id);
        }
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

        //keep the userId as key and his/her count of days has timecard this month as value on the map
        Map<Id, Integer> allTimeCards = new Map<Id, Integer>();
        for(AggregateResult aggregateResult: timeCards)
        {
            if(Integer.valueOf(aggregateResult.get('expr0')) >= 6)
            {
                String userIdStr = String.valueOf(aggregateResult.get('uid'));
                Id userId = Id.valueOf(userIdStr);
                Integer timeCardNumber = (allTimeCards.get(userId) == null) ? 1 : allTimeCards.get(userId) + 1;
                allTimeCards.put(userId, timeCardNumber);

            }
        }
        //save the userId as key and creditId as value on the map
        Map<String, String> allCredits = EmployeeCredit.getCreditsInFin(allUser);
        Set<Id> uIds = allTimeCards.keySet();
        //save all CreditTransaction shoud be inserted into Fin
        List<EmployeeCreditTransaction.CreditTransaction> addCreditTransactions = new List<EmployeeCreditTransaction.CreditTransaction>();
        for(Id id : uIds)
        {
            Integer timeCardNumber = allTimeCards.get(id);
            if(timeCardNumber >= workday)
            {
                String creditId = allCredits.get(String.valueOf(id));
                if(creditId != null && creditId != '')
                {
                    EmployeeCreditTransaction.CreditTransaction creditTransaction = new EmployeeCreditTransaction.CreditTransaction( 0.3, creditId, 'Perfect Attendence' + year + '-' + month, Date.today(), true, 'Perfect Attendence');
                    addCreditTransactions.add(creditTransaction);
                }
            }
        }
        EmployeeCreditTransaction.createCreditTransactions(addCreditTransactions);
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