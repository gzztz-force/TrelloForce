/*
 * The class to get info from Trello and insert to pm.
 */
public with sharing class TrelloFactory
{
    public TrelloFactory(){}

    //public List<ChangeMember__c> changeMembersToDelete { get; set; }

    public String Token
    {
        get
        {
           String vToken = TrelloDetail__c.getInstance('Vicky Zhang').Trello_Token__c;
           return vToken;
        }
        set;
    }
    public String Key
    {
        get
        {
            String vKey = TrelloDetail__c.getInstance('Vicky Zhang').Trello_Key__c;
            return vKey;
        }
        set;
    }

    public List<TrelloBoard> getTrelloBoardInfo(String key, String token)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/members/my/boards/all?fields=id,name,desc,closed&key='+ key +'&token='+ token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        List<TrelloBoard> boards = (List<TrelloBoard>)JSON.deserialize(response.getBody(), List<TrelloBoard>.class);
        if(boards.size() == null)
        {
            TrelloBoard board = new TrelloBoard();
            boards.add(board);
        }
        return boards;
    }

    public List<TrelloCard> getTrelloCardInfo(String boardId)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ boardId +'/cards?fields=name,closed,desc,idBoard,idList,due,idMembers&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return (List<TrelloCard>)JSON.deserialize(response.getBody(), List<TrelloCard>.class);

    }

    public List<TrelloCheckList> getTrelloCheckListInfo(String boardId)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ boardId +'/checklists?fields=id,name,idCard&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return (List<TrelloCheckList>)JSON.deserialize(response.getBody(), List<TrelloCheckList>.class);

    }

    public List<TrelloMember> getTrelloAllMembers(String boardId)
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/boards/'+ boardId +'/members?fields=id,fullName&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return (List<TrelloMember>)JSON.deserialize(response.getBody(), List<TrelloMember>.class);
    }


//***** Methods Start *****//
    //public Map<String, String> getBoardNames()
    //{
    //    List<TrelloBoard> boards = getTrelloBoardInfo();
    //    Map<String, String> boardId_boardName = new Map<String,String>();
    //    for(TrelloBoard board : boards)
    //    {
    //        boardId_boardName.put(board.Id, board.Name);
    //    }
    //    return boardId_boardName;
    //}
    //public void upsertBoard()
    //{
    //    List<TrelloBoard> boards = getTrelloBoardInfo();
    //    List<MProject__c> projectsToUpsert = new List<MProject__c>();
    //    for(TrelloBoard board : boards)
    //    {
    //        MProject__c project = new MProject__c();
    //        project.Name = board.Name;
    //        project.TrelloBoardId__c = board.Id;
    //        System.debug(board.Closed);
    //        if(board.Closed == true)
    //        {
    //            project.Status__c = 'Closed';
    //        }
    //        else
    //        {
    //            project.Status__c = 'In Progress';
    //        }
    //        System.debug(project.Status__c);
    //        projectsToUpsert.add(project);
    //    }
    //    try
    //    {
    //        upsert projectsToUpsert TrelloBoardId__c;
    //    }
    //    catch(Exception ex)
    //    {
    //        System.debug(ex);
    //    }
    //}

    public void upsertCard(List<MProject__c> projects)
    {
        List<Change__c> changesToUpsert = new List<Change__c>();
        Map<String, List<TrelloMember>> proId_TrelloMembers = new Map<String, List<TrelloMember>>();
        Map<String, List<TrelloCard>> proId_trelloCards = new Map<String, List<TrelloCard>>();
        Map<String, String> cardId_proId = new Map<String, String>();
        for(MProject__c pro : projects)
        {
            List<TrelloCard> cards = getTrelloCardInfo(pro.TrelloBoardId__c);
            proId_trelloCards.put(pro.Id, cards);
            List<TrelloMember> proMembers =  getTrelloAllMembers(pro.TrelloBoardId__c);
            proId_TrelloMembers.put(pro.Id, proMembers);
        }
        for(String id : proId_trelloCards.keySet())
        {
            List<TrelloCard> cardList = proId_trelloCards.get(id);
            for(TrelloCard card : cardList)
            {
                Change__c c = new Change__c();
                c.Name = card.Name;
                c.TrelloCardId__c = card.Id;
                c.DueDate__c = card.Due;
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

    public void upsertTeamMember(Map<String, List<TrelloMember>> proId_TrelloMembers)
    {
        List<TeamMember__c> teamMembersToUpsert = new List<TeamMember__c>();
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c];
        List<User> users = [select Id, Name from User];
        for(String proId : proId_TrelloMembers.keySet())
        {
            List<TrelloMember> proMembers = proId_TrelloMembers.get(proId);
            for(TrelloMember member : proMembers)
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
            for(TrelloMember member : proMembers)
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

    public void deleteTeamMember(Map<String, List<TrelloMember>> proId_TrelloMembers)
    {
        List<TeamMember__c> teamMembersToDelete = new List<TeamMember__c>();
        Map<String, TrelloMember> trelloMemberId_trelloMember = new Map<String, TrelloMember>();
        List<TeamMember__c> teamMembers = [select TrelloMemberId__c, Project__c from TeamMember__c where TrelloMemberId__c != null];
        for(String proId : proId_TrelloMembers.keySet())
        {
            List<TrelloMember> trelloMembers = proId_TrelloMembers.get(proId);
            for(TrelloMember trelloMember : trelloMembers)
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

    public Map<String, String> upsertChangeMember(Map<String, List<TrelloCard>> proId_trelloCards)
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
        for(List<TrelloCard> cards : proId_trelloCards.values())
        {
            for(TrelloCard card : cards)
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

    public void upsertItem(List<MProject__c> projects)
    {
        Set<List<TrelloCheckList>> checkListsSet = new Set<List<TrelloCheckList>>();
        List<String> cardIds = new List<String>();
        List<ChangeTask__c> tasksToUpsert = new List<ChangeTask__c>();
        Map<String, String> cardId_ChangeId = new Map<String, String>();
        Map<String, TrelloCheckItem> itemId_Item = new Map<String, TrelloCheckItem>();
        for(MProject__c pro : projects)
        {
            List<TrelloCheckList> checklists = getTrelloCheckListInfo(pro.TrelloBoardId__c);
            checkListsSet.add(checklists);
            for(TrelloCheckList checklist : checklists)
            {
                cardIds.add(checklist.IdCard);
            }
        }
        for(Change__c changeWithCard : [select Id, TrelloCardId__c from Change__c where TrelloCardId__c in :cardIds])
        {
            cardId_ChangeId.put(changeWithCard.TrelloCardId__c, changeWithCard.Id);
        }
        for(List<TrelloCheckList> checkLists : checkListsSet)
        {
            for(TrelloCheckList checklist : checkLists)
            {
                String changeId = cardId_ChangeId.get(checklist.IdCard);
                if(changeId != null){
                    List<TrelloCheckItem> ChecklistItems = checklist.CheckItems;
                    for(TrelloCheckItem item : ChecklistItems)
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
        deleteItem(itemId_Item);
    }
    public void deleteItem(Map<String, TrelloCheckItem> itemId_Item)
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

//***** Methods End *****//

//***** Inner Class Start *****//
    public class TrelloBoard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String ShortLink { get; set; }
        public String Description { get; set; }
        public Boolean Closed { get; set; }
    }

     public class TrelloCard
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public Boolean Closed { get; set; }
        public String Description { get; set; }
        public String IdBoard { get; set; }
        public String IdList { get; set; }
        public Date Due { get; set; }
        public List<String> IdMembers { get; set; }

    }

    public class TrelloCheckList
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String IdCard { get; set; }
        public List<TrelloCheckItem> CheckItems { get; set; }
    }

    public class TrelloCheckItem
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String State { get; set; }
    }

    public class TrelloMember
    {
        public String Id { get; set; }
        public String FullName { get; set; }
        public String TeamMemberId { get; set; }
    }
    //***** Inner Class End *****//


}