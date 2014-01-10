/*
 * A trigger that automatically create self-learning prject team member when a new user created.
 */
trigger AutoCreateSelfLearningTeamMember on User (after insert)
{
    List<Id> userIds = new List<Id>();
    for(User newUser : trigger.new)
    {
        if(newUser.IsEmployee__c == 1)
        {
            userIds.add(newUser.Id);
        }
    }
    try
    {
        UserHandler.createTeamMembers(userIds);
    }
    catch(Exception e)
    {
        trigger.new[0].addError(e);
    }
}