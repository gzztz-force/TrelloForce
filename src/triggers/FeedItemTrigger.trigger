/*
*Trigger for count FeedItem, and the number of CommentCount, LikeCount of the FedItem on the WikiPage.
*/
trigger FeedItemTrigger on FeedItem (after insert, after update, after delete, after undelete) 
{
	TriggerFactory.createHandler(FeedItem.SObjectType);
}