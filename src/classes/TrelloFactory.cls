/*
 * The class to get info from Trello and insert to pm.
 */
public with sharing class TrelloFactory
{
    private String key;
    private String token;
    private TrelloAPI trelloApi;
    private List<MProject__c> projects;
    private List<String> param;

    public TrelloFactory(List<MProject__c> projects)
    {
        token = TrelloDetail__c.getInstance(UserInfo.getUserId()).Trello_Token__c;
        key = TrelloDetail__c.getInstance(UserInfo.getUserId()).Trello_Key__c;
        trelloApi = new TrelloAPI(key, token);
        this.projects = projects;
    }

    public void upsertChange()
    {
        List<Change__c> changesToUpsert = new List<Change__c>();
        Map<String, List<TrelloModel.Member>> proId_TrelloMembers = new Map<String, List<TrelloModel.Member>>();
        Map<String, List<TrelloModel.Card>> proId_trelloCards = new Map<String, List<TrelloModel.Card>>();
        Map<String, String> cardId_proId = new Map<String, String>();
        for(MProject__c pro : projects)
        {
            param = new List<String>();
            param.add(pro.TrelloBoardId__c);
            List<TrelloModel.Card> cards = trelloApi.getCardInfo(param);
            proId_trelloCards.put(pro.Id, cards);
            List<TrelloModel.Member> proMembers =  trelloApi.getAllMembers(param);
            proId_TrelloMembers.put(pro.Id, proMembers);
        }
        for(String id : proId_trelloCards.keySet())
        {
            List<TrelloModel.Card> cardList = proId_trelloCards.get(id);
            for(TrelloModel.Card card : cardList)
            {
                Change__c c = new Change__c();
                c.Name = card.Name;
                c.TrelloCardId__c = card.Id;
                c.Description__c = card.Description;
                c.Project__c = id;
                changesToUpsert.add(c);
                cardId_proId.put(card.Id, id);
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
        List<Change__c> changesToDelete = deleteChange(cardId_proId);
        upsertTeamMember(proId_TrelloMembers);
        deleteTeamMember(proId_TrelloMembers);
        Map<String, String> changeId_MemberId = upsertChangeMember(proId_trelloCards);
        deleteChangeMember(changeId_MemberId);
    }

    public List<Change__c> deleteChange(Map<String, String> cardId_proId)
    {
        List<Change__c> changesToDelete = new List<Change__c>();
        List<Change__c> changes = [select id,Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null];
        for(Change__c change : changes)
        {
            if(!cardId_proId.containsKey(change.TrelloCardId__c))
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
        return changesToDelete;
    }

    public void upsertTeamMember(Map<String, List<TrelloModel.Member>> proId_TrelloMembers)
    {
        List<TeamMember__c> teamMembersToUpsert = new List<TeamMember__c>();
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c];
        List<User> users = [select Id, Name from User];
        for(String proId : proId_TrelloMembers.keySet())
        {
            List<TrelloModel.Member> proMembers = proId_TrelloMembers.get(proId);
            for(TrelloModel.Member member : proMembers)
            {
                for(TeamMember__c teamMember : teamMembers)
                {
                    if(teamMember.name.equalsIgnoreCase(member.FullName)&&(teamMember.Project__c == proId))
                    {
                        teamMember.TrelloMemberId__c = member.Id;
                        teamMembersToUpsert.add(teamMember);
                        member.TeamMemberId = teamMember.Id;
                    }
                }
            }
            for(TrelloModel.Member member : proMembers)
            {
                if(member.TeamMemberId == null)
                {
                    for(User user : users)
                    {
                        if(user.Name.equalsIgnoreCase(member.FullName))
                        {
                            TeamMember__c teMember = new TeamMember__c();
                            teMember.Name = member.FullName;
                            teMember.TrelloMemberId__c = member.Id;
                            teMember.User__c = user.Id;
                            teMember.Project__c = proId;
                            teamMembersToUpsert.add(teMember);
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

    public void deleteTeamMember(Map<String, List<TrelloModel.Member>> proId_TrelloMembers)
    {
        List<TeamMember__c> teamMembersToDelete = new List<TeamMember__c>();
        Map<String, TrelloModel.Member> trelloMemberId_trelloMember = new Map<String, TrelloModel.Member>();
        List<TeamMember__c> teamMembers = [select TrelloMemberId__c, Project__c from TeamMember__c where TrelloMemberId__c != null];
        for(String proId : proId_TrelloMembers.keySet())
        {
            List<TrelloModel.Member> trelloMembers = proId_TrelloMembers.get(proId);
            for(TrelloModel.Member trelloMember : trelloMembers)
            {
                trelloMemberId_trelloMember.put(trelloMember.Id + proId,trelloMember);
            }
        }
        for(TeamMember__c teamMember : teamMembers)
        {
            if(!trelloMemberId_trelloMember.containsKey(teamMember.TrelloMemberId__c + teamMember.Project__c))
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

    public Map<String, String> upsertChangeMember(Map<String, List<TrelloModel.Card>> proId_trelloCards)
    {
        List<ChangeMember__c> changeMembersToUpsert = new List<ChangeMember__c>();
        List<Change__c> changes = [select Id,Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null];
        Map<String,String> trelloCardId_changeId = new Map<String,String>();
        List<TeamMember__c> teamMemberList = [select Id, Name, TrelloMemberId__c from TeamMember__c where TrelloMemberId__c != null];
        Map<String,TeamMember__c> trelloMemberId_TeamMember = new Map<String, TeamMember__c>();
        List<ChangeMember__c> changeMembers = [select Change__c, TeamMember__c from ChangeMember__c];
        Map<String,String> changeId_MemberId = new Map<String, String>();
        for(Change__c change : changes)
        {
            trelloCardId_changeId.put(change.TrelloCardId__c, change.Id);
        }
        for(TeamMember__c teamMember : teamMemberList)
        {
            trelloMemberId_TeamMember.put(teamMember.TrelloMemberId__c, teamMember);
        }
        for(List<TrelloModel.Card> cards : proId_trelloCards.values())
        {
            for(TrelloModel.Card card : cards)
            {
                    for(String id : card.IdMembers)
                    {
                        if(trelloMemberId_TeamMember.get(id) != null)
                        {
                            ChangeMember__c changeMember = new ChangeMember__c();
                            changeMember.Name = trelloMemberId_TeamMember.get(id).Name;
                            changeMember.Change__c = trelloCardId_changeId.get(card.Id);
                            changeMember.TeamMember__c = trelloMemberId_TeamMember.get(id).Id;
                            changeMember.ChangeId_MemberId__c = trelloCardId_changeId.get(card.Id)+trelloMemberId_TeamMember.get(id).Id;
                            changeId_MemberId.put(trelloCardId_changeId.get(card.Id)+trelloMemberId_TeamMember.get(id).Id, id);
                            changeMembersToUpsert.add(changeMember);
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
        return changeId_MemberId;
    }

    public void deleteChangeMember(Map<String, String> changeId_MemberId)
    {
        List<ChangeMember__c> changeMembersToDelete = new List<ChangeMember__c>();
        List<ChangeMember__c> changeMembers = [select ChangeId_MemberId__c from ChangeMember__c];
        for(ChangeMember__c changeMember : changeMembers)
        {
            if(!changeId_MemberId.containsKey(changeMember.ChangeId_MemberId__c))
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
        Map<String, String> cardId_ChangeId = new Map<String, String>();
        Map<String, TrelloModel.CheckItem> itemId_Item = new Map<String, TrelloModel.CheckItem>();
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
        for(Change__c changeWithCard : [select Id, TrelloCardId__c from Change__c where TrelloCardId__c in :cardIds])
        {
            cardId_ChangeId.put(changeWithCard.TrelloCardId__c, changeWithCard.Id);
        }
        for(List<TrelloModel.CheckList> checkLists : checkListsSet)
        {
            for(TrelloModel.CheckList checklist : checkLists)
            {
                String changeId = cardId_ChangeId.get(checklist.IdCard);
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
                        itemId_Item.put(task.TrelloItemId__c, item);
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
        deleteChangeTask(itemId_Item);
    }

    public void deleteChangeTask(Map<String, TrelloModel.CheckItem> itemId_Item)
    {
        List<ChangeTask__c> tasksToDelete = new List<ChangeTask__c>();
        List<ChangeTask__c> changeTasks = [select Id, TrelloItemId__c from ChangeTask__c where TrelloItemId__c != null];
        for(ChangeTask__c changeTask : changeTasks)
        {
            if(!itemId_Item.containsKey(changeTask.TrelloItemId__c))
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


}