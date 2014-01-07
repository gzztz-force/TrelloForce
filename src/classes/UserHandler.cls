/*
 * A help class for trigger AutoCreateSelfLearningTeamMember.
 */
public class UserHandler
{
    static String SELF_LEARN_PRO = 'Project for self-learning and non-work related hours';
    @future
    public static void createTeamMembers(List<Id> userIds)
    {
        List<TeamMember__c> newMembers = new List<TeamMember__c>();
        List<MProject__c> selfLearnProjects = [select Id, Name from MProject__c where Name = :SELF_LEARN_PRO limit 1];
        List<User> users = [select Id, Name, UserRoleId from User where Id in :userIds];
        if(selfLearnProjects.size() > 0 && users.size() > 0)
        {
            for(User newUser : users)
            {
                newMembers.add(new TeamMember__c(Name = newUser.Name, Project__c = selfLearnProjects[0].Id, User__c = newUser.Id, Role__c = newUser.UserRoleId));
            }
        }
        Database.insert(newMembers, false);
    }
}