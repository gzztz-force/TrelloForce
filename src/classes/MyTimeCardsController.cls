public with sharing class MyTimeCardsController
{    
    public MyTimeCardsController()
    {
    }
    
    public List<InLineTimeCard> TimeCards
    { 
        get
        {
            List<InLineTimeCard> timeCards = new List<InLineTimeCard>();            
            for(TimeCard__c card : [select Id, Name, Billable__c, Change__c, Date__c, Description__c, Hours__c, IsSync__c, Project__r.Name, TeamMember__r.Name from TimeCard__c where TeamMember__r.User__c = :UserInfo.getUserId() LIMIT 10])
            {
                InLineTimeCard timeCard = new InLineTimeCard();
                timeCard.TimeCardId = card.Id;
                timeCard.TimeCardName = card.Name;
                timeCard.Project = card.Project__r.Name;
                timeCard.Hours = card.Hours__c;
                timeCard.DateValue = String.valueOf(card.Date__c);
                String description = card.Description__c;
                if(description != null && description != '' && description.length() > 30)
                {
                    timeCard.Description = description.abbreviate(33);
                }
                else
                {
                    timeCard.Description = description;
                }
                timeCards.add(timeCard);
            }
            return timeCards;
        }
    } 
    
    public class InLineTimeCard
    {
        public Id TimeCardId { get; set; }
        public String TimeCardName { get; set; }
        public String Project {get; set; }
        public Decimal Hours { get; set; }
        public String DateValue {get; set; }
        public String Description{ get; set; }
        
        public InLineTimeCard()
        {}
    }
}