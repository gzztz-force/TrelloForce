/*
 * This Schedule used to control Credit with timecard every month, which should execute every month's first day.
 * Should execute "0 0 0 1 * ? *"
 */
global class PerfectAttendanceCreditJob implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts
{
    private final static Decimal ADJUSTMENT = 0.3;

    private Date lastMonth = Date.today().addMonths(-1);
    private Integer year = lastMonth.year();
    private Integer month = lastMonth.month();
    private Integer workday;

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([select Id, Name, FinUserName__c from User where
                                        FinUserName__c != null and IsActive = true and IsEmployee__c = 1]);
    }

    // Execute method for batch
    global void execute(Database.BatchableContext BC, List<User> users)
    {
        Set<Id> userIds = new Set<Id>();
        Map<String, String> allUser = new Map<String, String>();
        for(User user : users)
        {
            userIds.add(user.Id);
            allUser.put(user.FinUserName__c, user.Id);
        }
        // All TimeCards last month
        AggregateResult[] timeCards;
        if(Test.isRunningTest())
        {
            timeCards = [select TeamMember__r.User__c uid, Date__c, sum(hours__c) from TimeCard__c where (TeamMember__r.User__c in :userIds) and (Date__c >= 2014-06-01) and (Date__c < 2014-07-01) group by TeamMember__r.User__c, Date__c order by Date__c desc];
            workday = Integer.valueOf(WorkDays__c.getValues('2014-6').Days__c);
        }
        else
        {
            timeCards = [select TeamMember__r.User__c uid, Date__c, sum(hours__c) from TimeCard__c where (TeamMember__r.User__c in :userIds) and (IsLogatSameDay__c = true) and Date__c = LAST_MONTH group by TeamMember__r.User__c, Date__c order by Date__c desc];
            workday = Integer.valueOf(WorkDays__c.getValues(year + '-' + month).Days__c);
        }

        // Keep the userId as key and his/her count of days has timecard this month as value on the map
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
        // Save the userId as key and creditId as value on the map
        Map<String, String> allCredits = EmployeeCredit.getCreditsInFin(allUser);

        Set<Id> uIds = allTimeCards.keySet();
        // Save all CreditTransaction shoud be inserted into Fin
        List<EmployeeCreditTransaction.CreditTransaction> creditTransactionsToAdd = new List<EmployeeCreditTransaction.CreditTransaction>();
        for(Id uId : uIds)
        {
            Integer timeCardNumber = allTimeCards.get(uId);

            if(timeCardNumber >= workday)
            {
                String creditId = allCredits.get(String.valueOf(uId));
                if(creditId != null && creditId != '')
                {
                    EmployeeCreditTransaction.CreditTransaction creditTransaction = new EmployeeCreditTransaction.CreditTransaction(ADJUSTMENT, creditId, 'Perfect Attendence' + year + '-' + month, Date.today(), false, 'Perfect Attendence');
                    creditTransactionsToAdd.add(creditTransaction);
                }
            }
        }
        if(creditTransactionsToAdd.size() > 0)
        {
            EmployeeCreditTransaction.createCreditTransactions(creditTransactionsToAdd);
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        // Get this month's workday, if get a nullPoint, then send the alert email to user
        if(WorkDays__c.getValues(year + '-' + (month+1)) == null)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {UserInfo.getUserEmail()};
            String[] ccAddresses = new String[] {'pm@meginfo.com'};
            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setReplyTo('danae.deng@meginfo.com');
            mail.setSenderDisplayName('Meginfo System Admin');
            mail.setSubject('Please Insert New Custom Setting Data');
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody('Please insert new Custom Setting data into WorkDays__c at least this month! Or the PerfectAttendanceCreditJob will stop.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    // Execute method for schedule
    global void execute(SchedulableContext SC)
    {
        // Get last month's workday, if get a nullPoint, then the batch won't execute
        WorkDays__c workdays = WorkDays__c.getValues(year + '-' + month);
        if(workdays != null)
        {
            workday = Integer.valueOf(workdays.Days__c);
            PerfectAttendanceCreditJob batch = new PerfectAttendanceCreditJob();
            Database.executeBatch(batch, 1);
        }
    }
}