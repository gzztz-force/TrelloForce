/*
 * A trigger for reset the user's birthday of next year after spend birthday this year.
*/
trigger SetUserBirthdayThisYear on User (before insert, before update)
{
    for(User user : trigger.new)
    {
        if(user.BirthdayThisYear__c == null)
        {
            user.BirthdayType__c = String.isBlank(user.BirthdayType__c)?'Solar':user.BirthdayType__c;

            if(user.Birthday__c != null)
            {
                Date birthdayThisYear = ConvertLunarToSolar.getBirthdayThisYear(user.Birthday__c.month(), user.Birthday__c.day(), user.BirthdayType__c);
                Date birthdayNextYear = ConvertLunarToSolar.getBirthdayNextYear(user.Birthday__c.month(), user.Birthday__c.day(), user.BirthdayType__c);
                if(birthdayThisYear > Date.today())
                {
                    user.BirthdayThisYear__c = birthdayThisYear;
                }
                else
                {
                    user.BirthdayThisYear__c = birthdayNextYear;
                }
            }
        }
    }
}