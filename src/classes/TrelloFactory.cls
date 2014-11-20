/*
 * The class to get info from Trello and insert to pm.
 */
public with sharing class TrelloFactory
{
    public TrelloFactory(){}

    public List<ChangeMember__c> changeMembersToDelete { get; set; }

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

    public List<TrelloBoard> getTrelloBoardInfo()
    {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.trello.com/1/members/my/boards/all?fields=id,name,desc,closed&key='+ Key +'&token='+ Token);
        request.setMethod('GET');
        HttpResponse response = (new Http()).send(request);
        return (List<TrelloBoard>)JSON.deserialize(response.getBody(), List<TrelloBoard>.class);
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
    public void upsertBoard()
    {
        List<TrelloBoard> boards = getTrelloBoardInfo();
        List<MProject__c> projectsToUpsert = new List<MProject__c>();
        for(TrelloBoard board : boards)
        {
            MProject__c project = new MProject__c();
            project.Name = board.Name;
            project.TrelloBoardId__c = board.Id;
            System.debug(board.Closed);
            if(board.Closed == true)
            {
                project.Status__c = 'Closed';
            }
            else
            {
                project.Status__c = 'In Progress';
            }
            System.debug(project.Status__c);
            projectsToUpsert.add(project);
        }
        try
        {
            upsert projectsToUpsert TrelloBoardId__c;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
    }

    public void upsertCard(List<MProject__c> projects)
    {
        List<Change__c> changesToUpsert = new List<Change__c>();
        Map<String, List<TrelloMember>> proId_TrelloMembers = new Map<String, List<TrelloMember>>();
        Map<String, List<TrelloCard>> proId_trelloCards = new Map<String, List<TrelloCard>>();
        for(MProject__c pro : projects)
        {
            List<TrelloCard> cards = getTrelloCardInfo(pro.TrelloBoardId__c);
            proId_trelloCards.put(pro.Id, cards);
            List<TrelloMember> proMembers =  getTrelloAllMembers(pro.TrelloBoardId__c);
            proId_TrelloMembers.put(pro.Id, proMembers);
            System.debug(cards);
        }
        System.debug(proId_trelloCards.keySet());
        System.debug(proId_trelloCards.values());
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
        deleteChange(proId_trelloCards);
        upsertTeamMember(projects, proId_TrelloMembers);
        upsertChangeMember(proId_trelloCards);
    }

    public void deleteChange(Map<String, List<TrelloCard>> proId_trelloCards)
    {
        List<Change__c> changesToDelete = new List<Change__c>();
        List<Change__c> allchanges = [select id,Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null];
        for(String id : proId_trelloCards.keySet())
        {
            List<TrelloCard> cards = proId_trelloCards.get(id);
            List<Change__c> proChanges = new List<Change__c>();
            Map<String, TrelloCard> cardId_trelloCard = new Map<String, TrelloCard>();
            for(Change__c change : allchanges)
            {
                if(change.Project__c == id)
                {
                    proChanges.add(change);
                }
            }
            for(TrelloCard card : cards)
            {
                cardId_trelloCard.put(card.Id, card);
            }
            for(Change__c proChange : proChanges)
            {
                if(!cardId_trelloCard.containsKey(proChange.TrelloCardId__c))
                {
                    changesToDelete.add(proChange);
                }
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

    public void upsertTeamMember(List<MProject__c> projects, Map<String, List<TrelloMember>> proId_TrelloMembers)
    {
        List<TeamMember__c> teamMembersToUpsert = new List<TeamMember__c>();
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c];
        List<User> users = [select Id, Name from User];
        for(MProject__c pro : projects)
        {
            List<TrelloMember> proMembers = proId_TrelloMembers.get(pro.Id);
            for(TrelloMember member : proMembers)
            {
                for(TeamMember__c teamMember : teamMembers)
                {
                    if(teamMember.name.equalsIgnoreCase(member.FullName)&&(teamMember.Project__c == pro.Id))
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
                            teMember.Project__c = pro.Id;
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

    public void upsertChangeMember(Map<String, List<TrelloCard>> proId_trelloCards)
    {
        List<ChangeMember__c> changeMembersToUpsert = new List<ChangeMember__c>();
        List<Change__c> changes = [select Id,Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null];
        Map<String,String> trelloCardId_changeId = new Map<String,String>();
        List<TeamMember__c> teamMemberList = [select Id, Name, TrelloMemberId__c from TeamMember__c where TrelloMemberId__c != null];
        Map<String,TeamMember__c> trelloMemberId_TeamMember = new Map<String, TeamMember__c>();
        List<ChangeMember__c> changeMembers = [select Change__c, TeamMember__c from ChangeMember__c];
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
    }

    public void upsertItem()
    {
        Set<List<TrelloCheckList>> checkListsSet = new Set<List<TrelloCheckList>>();
        List<MProject__c> projects = [select Id, TrelloBoardId__c from MProject__c where TrelloBoardId__c != null];
        Set<String> cardIdSet = new Set<String>();
        List<ChangeTask__c> tasksToUpsert = new List<ChangeTask__c>();
        Map<String, String> cardIdToChangeIdMap = new Map<String, String>();
        for(MProject__c pro : projects)
        {
            List<TrelloCheckList> checklists = getTrelloCheckListInfo(pro.TrelloBoardId__c);
            checkListsSet.add(checklists);
            for(TrelloCheckList checklist : checklists)
            {
                cardIdSet.add(checklist.IdCard);
            }
        }
        for(Change__c changeWithCard : [select Id, TrelloCardId__c from Change__c where TrelloCardId__c in :cardIdSet])
        {
            cardIdToChangeIdMap.put(changeWithCard.TrelloCardId__c, changeWithCard.Id);
        }
        for(List<TrelloCheckList> checkLists : checkListsSet)
        {
            for(TrelloCheckList checklist : checkLists)
            {
                String changeId = cardIdToChangeIdMap.get(checklist.IdCard);
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