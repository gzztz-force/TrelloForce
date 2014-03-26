/*
 * A controller for MyTimeCards page
 */
public with sharing class MyTimeCardsController
{
    public List<InLineTimeCard> TimeCards
    {
        get
        {
            List<InLineTimeCard> timeCards = new List<InLineTimeCard>();
            for(TimeCard__c card : [select Id, Name, Billable__c, Change__c, Date__c, Description__c,
                                    Hours__c, Project__r.Name, TeamMember__r.Name
                                    from TimeCard__c where TeamMember__r.User__c = :UserInfo.getUserId()
                                    order by Date__c desc, CreatedDate desc LIMIT 10])
            {
                timeCards.add(new InLineTimeCard(card));
            }
            return timeCards;
        }
    }

    public class InLineTimeCard
    {
        public InLineTimeCard(TimeCard__c card)
        {
            this.TimeCardId = card.Id;
            this.TimeCardName = card.Name;
            this.Project = card.Project__r.Name;
            this.Hours = card.Hours__c;
            this.DateValue = card.Date__c;
            this.Description = String.isNotBlank(card.Description__c) ? card.Description__c.abbreviate(33) : '';
        }

        public Id TimeCardId { get; set; }
        public String TimeCardName { get; set; }
        public String Project { get; set; }
        public Decimal Hours { get; set; }
        public Date DateValue { get; set; }
        public String Description{ get; set; }
    }
}