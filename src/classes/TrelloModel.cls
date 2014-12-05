public with sharing class TrelloModel {
	public TrelloModel() {
    }

	public class Board
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String ShortLink { get; set; }
        public String Description { get; set; }
        public Boolean Closed { get; set; }
        public String DateLastActivity { get; set; }
        public String DateLastView { get; set; }
        public String IdOrganization { get; set; }
        public Boolean Invited { get; set; }
        public Boolean Pinned { get; set; }
        public Boolean Starred { get; set; }
        public String[] Invitations { get; set; }
        public MemberShips[] Memberships { get; set; }
        public Boolean Subscribed { get; set; }
        public String ShortUrl { get; set; }
    }

     public class Card
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public Boolean Closed { get; set; }
        public String Description { get; set; }
        public String IdBoard { get; set; }
        public String IdList { get; set; }
        public String Due { get; set; }
        public List<String> IdMembers { get; set; }
        public String ShortUrl { get; set; }
        public String Url { get; set; }
        public String ShortLink { get; set; }
        public Boolean Subscribed { get; set; }
        public Decimal Pos { get; set; }
        public String DateLastActivity { get; set; }
        public String DescData { get; set; }
        public String Email { get; set; }
        public List<String> IdCheckLists { get; set; }
        public List<String> IdLabels { get; set; }
        public Integer IdShort { get; set; }
        public String IdAttachmentCover { get; set; }
        public Boolean ManualCoverAttachment { get; set; }
        //checkItemStates
        //badges
        //idMembersVoted
        //labels

    }

    public class CheckList
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public String IdCard { get; set; }
        public String IdBoard { get; set; }
        public Decimal Pos { get; set; }
        public List<CheckItem> CheckItems { get; set; }
    }

    public class CheckItem
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public Decimal Pos { get; set; }
        public String Type { get; set; }
        public String State { get; set; }
    }

    public class Member
    {
        public String Id { get; set; }
        public String FullName { get; set; }
        public String AvatarHash { get; set; }
        public String Initials { get; set; }
        public String Status { get; set; }
        public String Url { get; set; }
        public String Username { get; set; }
        public List<String> IdOrganizations { get; set; }
        public List<String> IdBoards { get; set; }
        public String TeamMemberId { get; set; }
    }

    public class MemberShips
    {
        public String Id { get; set; }
        public String IdMember { get; set; }
        public String MemberType { get; set; }
        public Boolean Unconfirmed { get; set; }
        public Boolean Deactivated { get; set; }
    }
}