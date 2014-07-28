/*
*Trigger for count FeedItem, and the number of CommentCount, LikeCount of the FedItem on the WikiPage.
*/
trigger FeedItemTrigger on FeedItem (after insert, after delete, before insert, before delete, after update, before update) 
{
	TriggerFactory.createHandler(FeedItem.SObjectType);
}