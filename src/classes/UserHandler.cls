/*
 * A help class for trigger AutoCreateSelfLearningTeamMember.
 */
public class UserHandler
{
    private final static String SELF_LEARN_PRO = 'Project for self-learning and non-work related hours';
    private final static String DEFAULT_ROLE = 'Developer';
    @future
    public static void createTeamMembers(List<Id> userIds)
    {
        List<TeamMember__c> newMembers = new List<TeamMember__c>();
        List<MProject__c> selfLearnProjects = [select Id, Name from MProject__c where Name = :SELF_LEARN_PRO limit 1];
        List<User> users = [select Id, Name from User where Id in :userIds];
        if(selfLearnProjects.size() > 0 && users.size() > 0)
        {
            for(User newUser : users)
            {
                newMembers.add(new TeamMember__c(Name = newUser.Name, Project__c = selfLearnProjects[0].Id, User__c = newUser.Id, Role__c = DEFAULT_ROLE));
            }
            Database.insert(newMembers, false);
        }
    }
}