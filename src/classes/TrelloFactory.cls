/*
 * The class to get info from Trello and insert to pm.
 */
public with sharing class TrelloFactory
{
    public TrelloFactory(){}

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
    public void upsertBoards()
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
        upsert projectsToUpsert TrelloBoardId__c;
    }

    public void upsertCard(List<MProject__c> projects)
    {
        Map<String,List<TrelloCard>> proCardMap = new Map<String,List<TrelloCard>>();
        List<TeamMember__c> teamMembers = [select Id, Name, TrelloMemberId__c, Project__c from TeamMember__c];
        List<User> users = [select Id, Name from User];
        List<TeamMember__c> teamMembersToUpsert = new List<TeamMember__c>();
        List<ChangeMember__c> changeMembersToUpsert = new List<ChangeMember__c>();
        List<Change__c> changesToDelete = new List<Change__c>();
        List<Change__c> allchanges = [select id,Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null];

        //for(Change__c change : changes)
        //{
        //    proChangesMap.put(change.Project__c, change);
        //}
        for(MProject__c pro : projects)
        {
            List<TrelloCard> cards = getTrelloCardInfo(pro.TrelloBoardId__c);
            proCardMap.put(pro.Id, cards);
        }
        List<Change__c> changesToUpsert = new List<Change__c>();
        for(String id : proCardMap.keySet())
        {
            List<TrelloCard> cardList = proCardMap.get(id);
            List<Change__c> proChanges = new List<Change__c>();
            Map<String, TrelloCard> cardMap = new Map<String, TrelloCard>();
            for(Change__c c : allchanges)
            {
                if(c.Project__c == id)
                {
                    proChanges.add(c);
                }
            }
            for(TrelloCard card : cardList)
            {
                cardMap.put(card.Id, card);
            }
            for(Change__c change : proChanges)
            {
                if(!cardMap.containsKey(change.TrelloCardId__c))
                {
                    System.debug(change);
                    changesToDelete.add(change);
                }
            }
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
        for(MProject__c pro : projects)
        {
            List<TrelloMember> proMembers =  getTrelloAllMembers(pro.TrelloBoardId__c);
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
            delete changesToDelete;
            upsert changesToUpsert TrelloCardId__c;
            upsert teamMembersToUpsert Id;
        }
        catch(Exception ex)
        {
            System.debug(ex);
        }
        List<Change__c> changes = [select id,Project__c, TrelloCardId__c from Change__c where TrelloCardId__c != null];
        Map<String,String> changeCardIdMap = new Map<String,String>();
        for(Change__c change : changes)
        {
            changeCardIdMap.put(change.TrelloCardId__c, change.Id);
        }
        List<TeamMember__c> teamMemberList = [select Id, Name, TrelloMemberId__c from TeamMember__c where TrelloMemberId__c != null];
        Map<String,TeamMember__c> teamMemberMap = new Map<String, TeamMember__c>();
        for(TeamMember__c member : teamMemberList)
        {
            teamMemberMap.put(member.TrelloMemberId__c, member);
        }
        for(List<TrelloCard> cards : proCardMap.values())
        {
            for(TrelloCard card : cards)
            {
                    for(String id : card.IdMembers)
                    {
                        if(teamMemberMap.get(id) != null)
                        {
                            ChangeMember__c changeMember = new ChangeMember__c();
                            changeMember.Name = teamMemberMap.get(id).Name;
                            changeMember.Change__c = changeCardIdMap.get(card.Id);
                            changeMember.TeamMember__c = teamMemberMap.get(id).Id;
                            changeMember.ChangeId_MemberId__c = changeCardIdMap.get(card.Id)+teamMemberMap.get(id).Id;
                            changeMembersToUpsert.add(changeMember);
                        }
                    }

            }
        }
        upsert changeMembersToUpsert ChangeId_MemberId__c;
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
        upsert tasksToUpsert TrelloItemId__c;
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