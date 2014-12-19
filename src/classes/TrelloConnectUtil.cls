/*
 * The class to update Trello data of pm.
 */
public without sharing class TrelloConnectUtil
{
    private String key;
    private String token;
    private TrelloAPI trelloApi;
    private List<MProject__c> projects;
    private List<String> param;

    public TrelloConnectUtil(){}

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
        Set<String> cardIds = new Set<String>();
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
                cardIds.add(card.Id);
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

        deleteChange(cardIds);
        upsertTeamMember(proIdToTrelloMembers);
        upsertChangeMember(proIdToTrelloCards);
    }

    // after insert, to delete the change which has been deleted in the trello.
    public void deleteChange(Set<String> cardIds)
    {
        List<Change__c> changesToDelete = new List<Change__c>();
        for(Change__c change : [select Id, Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null])
        {
            if(!cardIds.contains(change.TrelloCardId__c))
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
        Map<String, String> teamMemberMap = new Map<String, String>();
        for(TeamMember__c teamMember : [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c])
        {
            teamMemberMap.put(teamMember.Name + teamMember.TrelloMemberId__c + teamMember.Project__c, teamMember.Id);
        }

        List<TeamMember__c> teamMembersToUpsert = new List<TeamMember__c>();

        for(String proId : proIdToTrelloMembers.keySet())
        {
            for(TrelloModel.Member trelloMember : proIdToTrelloMembers.get(proId))  
            {
                if(teamMemberMap.containsKey(trelloMember.FullName+trelloMember.Id+proId))
                {
                    trelloMember.TeamMemberId = teamMemberMap.get(trelloMember.FullName + trelloMember.Id + proId);
                }
                else
                {
                    trelloMember.TeamMemberId = null;
                }
            }
            for(TrelloModel.Member trelloMember : proIdToTrelloMembers.get(proId))
            {
                if(trelloMember.TeamMemberId == null)
                {
                    for(User user : [select Id, FirstName, LastName from User])
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
            insert teamMembersToUpsert;
            deleteTeamMember(proIdToTrelloMembers);
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

    // delete the teamMember which has been deleted in the trello.
    public void deleteTeamMember(Map<String, List<TrelloModel.Member>> proIdToTrelloMembers)
    {
        List<TeamMember__c> teamMembersToDelete = new List<TeamMember__c>();
        Set<String> trelloMemberIds = new Set<String>();

        for(String proId : proIdToTrelloMembers.keySet())
        {
            List<TrelloModel.Member> trelloMembers = proIdToTrelloMembers.get(proId);
            for(TrelloModel.Member trelloMember : trelloMembers)
            {
                trelloMemberIds.add(trelloMember.Id + proId);
            }
        }

        for(String proId : proIdToTrelloMembers.keySet())
        {
            for(TeamMember__c teamMember : [select TrelloMemberId__c, Project__c from TeamMember__c where TrelloMemberId__c != null and Project__c = :proId])
            {
                if(!trelloMemberIds.contains(teamMember.TrelloMemberId__c + teamMember.Project__c))
                {
                    teamMembersToDelete.add(teamMember);
                }
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

    public void upsertChangeMember(Map<String, List<TrelloModel.Card>> proIdToTrelloCards)
    {
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c];
        List<ChangeMember__c> changeMembersToUpsert = new List<ChangeMember__c>();
        Map<String,String> trelloCardIdToChangeId = new Map<String,String>();
        Set<String> changeMemberIds = new Set<String>();

        for(Change__c change : [select Id, Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null])
        {
            trelloCardIdToChangeId.put(change.TrelloCardId__c, change.Id);
        }

        for(String proId : proIdToTrelloCards.keySet())
        {
            for(TrelloModel.Card card : proIdToTrelloCards.get(proId))
            {
                Set<String> idMemberSet = new Set<String>(card.IdMembers);
                for(TeamMember__c teamMember : teamMembers)
                {
                    if(idMemberSet.contains(teamMember.TrelloMemberId__c) && teamMember.Project__c == proId)
                    {
                        ChangeMember__c changeMember = new ChangeMember__c();
                        changeMember.Name = teamMember.Name;
                        changeMember.Change__c = trelloCardIdToChangeId.get(card.Id);
                        changeMember.TeamMember__c = teamMember.Id;
                        changeMember.ChangeId_MemberId__c = trelloCardIdToChangeId.get(card.Id) + teamMember.Id;
                        changeMemberIds.add(trelloCardIdToChangeId.get(card.Id) + teamMember.Id);
                        changeMembersToUpsert.add(changeMember);
                    }
                }
            }
        }
        try
        {
            upsert changeMembersToUpsert ChangeId_MemberId__c;
            deleteChangeMember(changeMemberIds);
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
        
    }

    public void deleteChangeMember(Set<String> changeMemberIds)
    {
        List<ChangeMember__c> changeMembersToDelete = new List<ChangeMember__c>();

        for(ChangeMember__c changeMember : [select ChangeId_MemberId__c from ChangeMember__c])
        {
            if(!changeMemberIds.contains(changeMember.ChangeId_MemberId__c))
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
        Set<String> itemIds = new Set<String>();

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
                if(changeId != null)
                {
                    for(TrelloModel.CheckItem item : checklist.CheckItems)
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
                        {
                            task.Status__c = 'Done';
                        }
                        tasksToUpsert.add(task);
                        itemIds.add(task.TrelloItemId__c);
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
        deleteChangeTask(itemIds);
    }

    public void deleteChangeTask(Set<String> itemIds)
    {
        List<ChangeTask__c> tasksToDelete = new List<ChangeTask__c>();
        for(ChangeTask__c changeTask : [select Id, TrelloItemId__c from ChangeTask__c where TrelloItemId__c != null])
        {
            if(!itemIds.contains(changeTask.TrelloItemId__c))
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
        if(String.isBlank(prj.TrelloBoardId__c))
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