/*
 * This Trigger can deal with all the dml operation on user object.
 * 
 */
trigger UserTrigger on User (after update, after insert, before insert, before update)
{    
    if(Trigger.isAfter && Trigger.isUpdate)
    {
        // To update the WeChat__c record when the user was updated to inactive or active.
        syncUserStatusToWeChatUserConfig();
    }
    else if(Trigger.isAfter && Trigger.isInsert)
    {
        // Create a selfLearning project when a new user was inserted.
        AutoCreateSelfLearningTeamMember();
    }

    private void syncUserStatusToWeChatUserConfig()
    {
        Map<Id, Boolean> weChatIds2UserActive = new Map<Id, Boolean>();
        for(User user : Trigger.new)
        {
            if(user.isActive != Trigger.oldMap.get(user.Id).isActive)
            {
                weChatIds2UserActive.put(user.Id, user.isActive);
            }
        }
        UserTriggerHandler.updateWeChatIsVerified(weChatIds2UserActive);    
    }

    private void AutoCreateSelfLearningTeamMember()
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
            UserTriggerHandler.createTeamMembers(userIds);
        }
        catch(Exception e)
        {
            trigger.new[0].addError(e);
        }
    }
}