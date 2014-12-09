/*
 * The class to update Trello data of pm.
 */
public with sharing class TrelloConnectUtil
{
    private String key;
    private String token;
    private TrelloAPI trelloApi;
    private List<MProject__c> projects;
    private List<String> param;

    public TrelloConnectUtil()
    {}

    public TrelloConnectUtil(List<MProject__c> projects)
    {
        token = TrelloUser__c.getInstance(UserInfo.getUserId()).Token__c;
        key = TrelloConfig__c.getInstance().Key__c;
        trelloApi = new TrelloAPI(key, token);
        this.projects = projects;
    }

    public void upsertChange()
    {
        List<Change__c> changesToUpsert = new List<Change__c>();
        Map<String, List<TrelloModel.Member>> proIdToTrelloMembers = new Map<String, List<TrelloModel.Member>>();
        Map<String, List<TrelloModel.Card>> proIdToTrelloCards = new Map<String, List<TrelloModel.Card>>();
        Map<String, String> cardIdToProId = new Map<String, String>();
        for(MProject__c pro : projects)
        {
            param = new List<String>();
            param.add(pro.TrelloBoardId__c);
            List<TrelloModel.Card> cards = trelloApi.getCardInfo(param);
            proIdToTrelloCards.put(pro.Id, cards);
            List<TrelloModel.Member> members =  trelloApi.getAllMembers(param);
            proIdToTrelloMembers.put(pro.Id, members);
        }
        for(String proId : proIdToTrelloCards.keySet())
        {
            List<TrelloModel.Card> cards = proIdToTrelloCards.get(proId);
            for(TrelloModel.Card card : cards)
            {
                Change__c c = new Change__c();
                c.Name = card.Name;
                c.TrelloCardId__c = card.Id;
                c.Description__c = card.Description;
                c.Project__c = proId;
                changesToUpsert.add(c);
                cardIdToProId.put(card.Id, proId);
            }
        }
        try
        {
            upsert changesToUpsert TrelloCardId__c;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
        deleteChange(cardIdToProId);
        upsertTeamMember(proIdToTrelloMembers);
        deleteTeamMember(proIdToTrelloMembers);
        Map<String, String> changeMemberIdToTeamMemberId = upsertChangeMember(proIdToTrelloCards);
        deleteChangeMember(changeMemberIdToTeamMemberId);
    }

//after insert, to delete the change which has been deleted in the trello.
    public void deleteChange(Map<String, String> cardIdToProId)
    {
        List<Change__c> changesToDelete = new List<Change__c>();
        for(Change__c change : [select Id, Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null])
        {
            if(!cardIdToProId.containsKey(change.TrelloCardId__c))
            {
                changesToDelete.add(change);
            }
        }
        try
        {
            delete changesToDelete;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

    public void upsertTeamMember(Map<String, List<TrelloModel.Member>> proIdToTrelloMembers)
    {
        List<TeamMember__c> teamMembersToUpsert = new List<TeamMember__c>();
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c];
        List<User> users = [select Id, FirstName, LastName from User];
        for(String proId : proIdToTrelloMembers.keySet())
        {
            List<TrelloModel.Member> trelloMembers = proIdToTrelloMembers.get(proId);
            for(TrelloModel.Member trelloMember : trelloMembers)
            {
                for(TeamMember__c teamMember : teamMembers)
                {
                    if(teamMember.name.equalsIgnoreCase(trelloMember.FullName)&&(teamMember.Project__c == proId))
                    {
                        teamMember.TrelloMemberId__c = trelloMember.Id;
                        teamMembersToUpsert.add(teamMember);
                        trelloMember.TeamMemberId = teamMember.Id;
                    }
                }
            }
            for(TrelloModel.Member trelloMember : trelloMembers)
            {
                if(trelloMember.TeamMemberId == null)
                {
                    for(User user : users)
                    {
                        String userName = user.FirstName + ' ' + user.LastName;
                        if(userName.equalsIgnoreCase(trelloMember.FullName))
                        {
                            TeamMember__c teamMember = new TeamMember__c();
                            teamMember.Name = trelloMember.FullName;
                            teamMember.TrelloMemberId__c = trelloMember.Id;
                            teamMember.User__c = user.Id;
                            teamMember.Project__c = proId;
                            teamMembersToUpsert.add(teamMember);
                        }
                    }
                }
            }
        }
        try
        {
            upsert teamMembersToUpsert Id;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

//delete the teamMember which has been deleted in the trello.
    public void deleteTeamMember(Map<String, List<TrelloModel.Member>> proIdToTrelloMembers)
    {
        List<TeamMember__c> teamMembersToDelete = new List<TeamMember__c>();
        Map<String, TrelloModel.Member> trelloMemberIdToTrelloMember = new Map<String, TrelloModel.Member>();
        for(String proId : proIdToTrelloMembers.keySet())
        {
            List<TrelloModel.Member> trelloMembers = proIdToTrelloMembers.get(proId);
            for(TrelloModel.Member trelloMember : trelloMembers)
            {
                trelloMemberIdToTrelloMember.put(trelloMember.Id + proId, trelloMember);
            }
        }
        for(TeamMember__c teamMember : [select TrelloMemberId__c, Project__c from TeamMember__c where TrelloMemberId__c != null])
        {
            if(!trelloMemberIdToTrelloMember.containsKey(teamMember.TrelloMemberId__c + teamMember.Project__c))
            {
                teamMembersToDelete.add(teamMember);
            }
        }
        try
        {
            delete teamMembersToDelete;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }

    }

    public Map<String, String> upsertChangeMember(Map<String, List<TrelloModel.Card>> proIdToTrelloCards)
    {
        List<ChangeMember__c> changeMembersToUpsert = new List<ChangeMember__c>();
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c from TeamMember__c where TrelloMemberId__c != null];
        Map<String,String> trelloCardIdToChangeId = new Map<String,String>();
        Map<String,String> changeMemberIdToTeamMemberId = new Map<String, String>();
        for(Change__c change : [select Id, Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null])
        {
            trelloCardIdToChangeId.put(change.TrelloCardId__c, change.Id);
        }
        for(List<TrelloModel.Card> cards : proIdToTrelloCards.values())
        {
            for(TrelloModel.Card card : cards)
            {
                    for(String trelloMemberId : card.IdMembers)
                    {
                        for(TeamMember__c teamMember : teamMembers)
                        {
                            if(teamMember.TrelloMemberId__c == trelloMemberId)
                            {
                                ChangeMember__c changeMember = new ChangeMember__c();
                                changeMember.Name = teamMember.Name;
                                changeMember.Change__c = trelloCardIdToChangeId.get(card.Id);
                                changeMember.TeamMember__c = teamMember.Id;
                                changeMember.ChangeId_MemberId__c = trelloCardIdToChangeId.get(card.Id)+teamMember.Id;
                                changeMemberIdToTeamMemberId.put(trelloCardIdToChangeId.get(card.Id)+teamMember.Id, trelloMemberId);
                                changeMembersToUpsert.add(changeMember);
                            }
                        }
                    }

            }
        }
        try
        {
            upsert changeMembersToUpsert ChangeId_MemberId__c;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
        return changeMemberIdToTeamMemberId;
    }

    public void deleteChangeMember(Map<String, String> changeMemberIdToTeamMemberId)
    {
        List<ChangeMember__c> changeMembersToDelete = new List<ChangeMember__c>();
        for(ChangeMember__c changeMember : [select ChangeId_MemberId__c from ChangeMember__c])
        {
            if(!changeMemberIdToTeamMemberId.containsKey(changeMember.ChangeId_MemberId__c))
            {
                changeMembersToDelete.add(changeMember);
            }
        }
        try
        {
            delete changeMembersToDelete;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

    public void upsertChangeTask()
    {
        Set<List<TrelloModel.CheckList>> checkListsSet = new Set<List<TrelloModel.CheckList>>();
        List<String> cardIds = new List<String>();
        List<ChangeTask__c> tasksToUpsert = new List<ChangeTask__c>();
        Map<String, String> cardIdToChangeId = new Map<String, String>();
        Map<String, TrelloModel.CheckItem> itemIdToItem = new Map<String, TrelloModel.CheckItem>();
        for(MProject__c pro : projects)
        {
            param = new List<String>();
            param.add(pro.TrelloBoardId__c);
            List<TrelloModel.CheckList> checklists = trelloApi.getCheckListInfo(param);
            checkListsSet.add(checklists);
            for(TrelloModel.CheckList checklist : checklists)
            {
                cardIds.add(checklist.IdCard);
            }
        }
        for(Change__c changes : [select Id, TrelloCardId__c from Change__c where TrelloCardId__c in :cardIds])
        {
            cardIdToChangeId.put(changes.TrelloCardId__c, changes.Id);
        }
        for(List<TrelloModel.CheckList> checkLists : checkListsSet)
        {
            for(TrelloModel.CheckList checklist : checkLists)
            {
                String changeId = cardIdToChangeId.get(checklist.IdCard);
                if(changeId != null){
                    List<TrelloModel.CheckItem> ChecklistItems = checklist.CheckItems;
                    for(TrelloModel.CheckItem item : ChecklistItems)
                    {
                        ChangeTask__c task = new ChangeTask__c();
                        task.Name = item.Name;
                        task.TrelloItemId__c = item.Id;
                        task.Change__c = changeId;
                        if(item.State == 'incomplete')
                        {
                            task.Status__c = 'In Progress';
                        }
                        else
                            task.Status__c = 'Done';
                        tasksToUpsert.add(task);
                        itemIdToItem.put(task.TrelloItemId__c, item);
                    }
                }

            }
        }
        try
        {
            upsert tasksToUpsert TrelloItemId__c;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
        deleteChangeTask(itemIdToItem);
    }

    public void deleteChangeTask(Map<String, TrelloModel.CheckItem> itemIdToItem)
    {
        List<ChangeTask__c> tasksToDelete = new List<ChangeTask__c>();
        for(ChangeTask__c changeTask : [select Id, TrelloItemId__c from ChangeTask__c where TrelloItemId__c != null])
        {
            if(!itemIdToItem.containsKey(changeTask.TrelloItemId__c))
            {
                tasksToDelete.add(changeTask);
            }
        }
        try
        {
            delete tasksToDelete;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

    public void deleteWithoutBoardId (MProject__c prj)
    {
        List<Change__c> changes = [select Id, Name from Change__c where Project__c = :prj.Id and TrelloCardId__c != null];
        List<TeamMember__c> teamMembers = [select Id, Name from TeamMember__c where Project__c = :prj.Id and TrelloMemberId__c != null]; 
        if(prj.TrelloBoardId__c == null || prj.TrelloBoardId__c == '')
        {
            try
            {
                delete changes;
                delete teamMembers;
            }
            catch(Exception ex)
            {
                System.debug(ex);
            }
        }
        
    }


}