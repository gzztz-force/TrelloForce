/*
 * A trigger for set the user's birthday this year works on workflow birthday blessing which fired when create or update user, or user's birthday passed.
 */
trigger SetUserBirthdayThisYear on User (before insert, before update)
{
    for(User user : trigger.new)
    {
        if(user.BirthdayThisYear__c == null && user.Birthday__c != null)
        {
            user.BirthdayType__c = String.isBlank(user.BirthdayType__c)?'Solar':user.BirthdayType__c;

            Date birthdayThisYear = LunarToSolarConversion.getBirthdayThisYear(user.Birthday__c.month(), user.Birthday__c.day(), user.BirthdayType__c);

            /*
             *  When birthday this year hasn't passed, set birthday this year.
             */
            if(birthdayThisYear > Date.today())
            {
                user.BirthdayThisYear__c = birthdayThisYear;
            }
            /*
             * When birthday this year passed, set birthday next year.
             */
            else
            {
                user.BirthdayThisYear__c = LunarToSolarConversion.getBirthdayNextYear(user.Birthday__c.month(), user.Birthday__c.day(), user.BirthdayType__c);
            }
        }
    }
}